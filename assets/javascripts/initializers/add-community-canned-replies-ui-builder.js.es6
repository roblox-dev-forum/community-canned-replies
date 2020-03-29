import { withPluginApi } from "discourse/lib/plugin-api";
import showModal from "discourse/lib/show-modal";

function initializeCommunityCannedRepliesUIBuilder(api) {
  api.modifyClass("controller:composer", {
    actions: {
      showCommunityCannedRepliesButton() {
        if (this.site.mobileView) {
          showModal("community-canned-replies").set("composerModel", this.model);
        } else {
          this.appEvents.trigger("composer:show-preview");
          this.appEvents.trigger("community-canned-replies:show");
        }
      }
    }
  });

  api.addToolbarPopupMenuOptionsCallback(() => {
    return {
      id: "community_canned_replies_button",
      icon: "far-clipboard",
      action: "showCommunityCannedRepliesButton",
      label: "community_canned_replies.composer_button_text"
    };
  });
}

export default {
  name: "add-community-canned-replies-ui-builder",

  initialize(container) {
    const siteSettings = container.lookup("site-settings:main");
    const currentUser = container.lookup("current-user:main");
    if (
      siteSettings.community_canned_replies_enabled &&
      currentUser &&
      currentUser.can_use_community_canned_replies
    ) {
      withPluginApi("0.5", initializeCommunityCannedRepliesUIBuilder);
    }
  }
};
