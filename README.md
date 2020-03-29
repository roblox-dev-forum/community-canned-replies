# Plugin: `community-canned-replies`

Adds a means to insert templates from the composer for developer community programs, such as Post Approval and Community Sage.

---

## Features

Clones `discourse-canned-replies` so we can have 2 sets of canned replies: one visible and editable for staff (i.e. `discourse-canned-replies`); another visible and editable for DevRel community group users (i.e. this plugin; for Post Approval and Community Sage).

---

## Impact

### Community

The post approval team can more swiftly, efficiently and effectively give feedback on post approval requests, because it takes less time to formulate a proper response to a lacking request.

Other community programs can make use of the canned replies to more quickly provide feedback to users on any other aspects than post approval requests.

### Internal

It helps the developer community programs scale better and they can provide feedback more quickly through canned replies, which means that bug reports and feature requests are surfaced more quickly and are of higher quality after they have passed through post approval.

### Resources

There is no significant performance overhead since only a small fraction of users will use canned replies.

Some work is performed to compute whether the user should be shown the canned replies both on the back-end and front-end, but this is very negligible.

The storage for the canned replies themselves is also very negligible (just the storage space of a few dozen posts at most).

A very minor amount of extra bandwidth will be used to cache the additional front-end assets.

### Maintenance

Whenever `discourse-canned-replies` updates, the changes have to be merged over manually to this plugin when desired, which will be a tedious process. However, it is not required to merge over every update to the parent plugin, and it is deemed that few changes will be necessary to the plugin unless a future Discourse update breaks the plugin.

---

## Technical Scope

Adds some custom user fields that determine whether the user can see/edit canned replies.

The front-end shows the button and list of canned replies based on these capabilities of a user.

The canned replies are stored as a custom plugin store that is indexed by the name of the plugin, so it will not interfere with the regular canned replies plugin. All other parts of the plugin (i.e. classes, modules, files, localization entries, settings) have also been renamed to avoid clashes with the regular plugin.

---

## Configuration

The `community_canned_replies_enabled` can be used to turn the plugin on/off.

Upon deployment, `community_canned_replies_groups` should be set to the list of groups that should have view/edit access to the community canned replies button and repository.

The `community_canned_replies_everyone_enabled` and `community_canned_replies_everyone_can_edit` should probably not be used for the Developer Forum, as they let everyone use and edit the canned replies respectively.
