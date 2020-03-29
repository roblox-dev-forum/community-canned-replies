import showModal from "discourse/lib/show-modal";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { getOwner } from "discourse-common/lib/get-owner";

export default {
  setupComponent(args, component) {
    const currentUser = this.get("currentUser");
    const everyoneCanEdit =
      this.get("siteSettings.community_canned_replies_everyone_enabled") &&
      this.get("siteSettings.community_canned_replies_everyone_can_edit");
    const currentUserCanEdit =
      this.get("siteSettings.community_canned_replies_enabled") &&
      currentUser &&
      currentUser.can_edit_community_canned_replies;
    const canEdit = currentUserCanEdit ? currentUserCanEdit : everyoneCanEdit;
    this.set("canEdit", canEdit);

    component.setProperties({
      isVisible: false,
      loadingReplies: false,
      replies: [],
      filteredReplies: []
    });

    if (!component.appEvents.has("community-canned-replies:show")) {
      this.showCanned = () => component.send("show");
      component.appEvents.on("community-canned-replies:show", this, this.showCanned);
    }

    if (!component.appEvents.has("community-canned-replies:hide")) {
      this.hideCanned = () => component.send("hide");
      component.appEvents.on("community-canned-replies:hide", this, this.hideCanned);
    }

    component.addObserver("listFilter", function() {
      const filterTitle = component.listFilter.toLowerCase();
      const filtered = component.replies
        .map(reply => {
          /* Give a relevant score to each reply. */
          reply.score = 0;
          if (reply.title.toLowerCase().indexOf(filterTitle) !== -1) {
            reply.score += 2;
          } else if (reply.content.toLowerCase().indexOf(filterTitle) !== -1) {
            reply.score += 1;
          }
          return reply;
        })
        .filter(reply => reply.score !== 0) // Filter irrelevant replies.
        .sort((a, b) => {
          /* Sort replies by relevance and title. */
          if (a.score !== b.score) {
            return a.score > b.score ? -1 : 1; /* descending */
          } else if (a.title !== b.title) {
            return a.title < b.title ? -1 : 1; /* ascending */
          }
          return 0;
        });
      component.set("filteredReplies", filtered);
    });
  },

  teardownComponent(component) {
    if (component.appEvents.has("community-canned-replies:show") && this.showCanned) {
      component.appEvents.off("community-canned-replies:show", this, this.showCanned);
      component.appEvents.off("community-canned-replies:hide", this, this.hideCanned);
    }
  },

  actions: {
    show() {
      $("#reply-control .d-editor-preview-wrapper > .d-editor-preview").hide();
      this.setProperties({ isVisible: true, loadingReplies: true });

      ajax("/community_canned_replies")
        .then(results => {
          this.setProperties({
            replies: results.replies,
            filteredReplies: results.replies
          });
        })
        .catch(popupAjaxError)
        .finally(() => {
          this.set("loadingReplies", false);

          if (this.canEdit) {
            Ember.run.schedule("afterRender", () =>
              document.querySelector(".community-canned-replies-filter").focus()
            );
          }
        });
    },

    hide() {
      $(".d-editor-preview-wrapper > .d-editor-preview").show();
      this.set("isVisible", false);
    },

    newCommunityReply() {
      const composer = getOwner(this).lookup("controller:composer");
      composer.send("closeModal");

      showModal("community-new-reply").set("newContent", composer.model.reply);
    }
  }
};
