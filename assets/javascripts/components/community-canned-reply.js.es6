import showModal from "discourse/lib/show-modal";
import applyCommunityReply from "discourse/plugins/community-canned-replies/lib/community-apply-reply";

export default Ember.Component.extend({
  isOpen: false,
  canEdit: false,

  init() {
    this._super(...arguments);
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
  },

  actions: {
    toggle() {
      this.toggleProperty("isOpen");
    },

    apply() {
      const composer = Discourse.__container__.lookup("controller:composer");

      applyCommunityReply(
        this.get("reply.id"),
        this.get("reply.title"),
        this.get("reply.content"),
        composer.model
      );

      this.appEvents.trigger("community-canned-replies:hide");
    },

    editCommunityReply() {
      const composer = Discourse.__container__.lookup("controller:composer");

      composer.send("closeModal");
      showModal("community-edit-reply").setProperties({
        composerModel: composer.composerModel,
        replyId: this.get("reply.id"),
        replyTitle: this.get("reply.title"),
        replyContent: this.get("reply.content")
      });
    }
  }
});
