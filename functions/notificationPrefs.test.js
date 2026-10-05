const test = require("node:test");
const assert = require("node:assert/strict");
const prefs = require("./notificationPrefs");

test("a missing document means everything is on", () => {
  const p = prefs.fromDocument(null);
  assert.equal(p.pushEnabled, true);
  assert.equal(prefs.wantsPush(p, { type: "forumReply", onMyPost: true }), true);
  assert.equal(prefs.wantsPush(p, { type: "shareInvite" }), true);
});

test("the master switch silences every push but keeps the inbox item", () => {
  const p = prefs.fromDocument({ pushEnabled: false });
  assert.equal(prefs.wantsPush(p, { type: "shareInvite" }), false);
  assert.equal(prefs.wantsPush(p, { type: "adminMessage" }), false);
  assert.equal(prefs.wantsInboxItem(p, { type: "shareInvite" }), true);
  assert.equal(prefs.wantsInboxItem(p, { type: "forumReply", onMyPost: true }), true);
});

test("a forum reply is governed by whose thread it is", () => {
  const p = prefs.fromDocument({ notifyRepliesOnMyPosts: false, notifyRepliesOnThreads: true });
  assert.equal(prefs.wantsPush(p, { type: "forumReply", onMyPost: true }), false);
  assert.equal(prefs.wantsPush(p, { type: "forumReply", onMyPost: false }), true);
  assert.equal(prefs.wantsInboxItem(p, { type: "forumReply", onMyPost: true }), false);
  assert.equal(prefs.wantsInboxItem(p, { type: "forumReply", onMyPost: false }), true);
});

test("an invite always reaches the inbox, even with its alert off", () => {
  const p = prefs.fromDocument({ notifyShareInvites: false });
  assert.equal(prefs.wantsPush(p, { type: "shareInvite" }), false);
  assert.equal(prefs.wantsInboxItem(p, { type: "shareInvite" }), true);
});

test("a recipe update with its switch off is not written at all", () => {
  const p = prefs.fromDocument({ notifySharedRecipeUpdates: false });
  assert.equal(prefs.wantsInboxItem(p, { type: "sharedRecipeUpdated" }), false);
});

test("non-boolean values in the document are ignored", () => {
  const p = prefs.fromDocument({ pushEnabled: "no", notifyAnnouncements: 0 });
  assert.equal(p.pushEnabled, true);
  assert.equal(p.notifyAnnouncements, true);
});

test("an unknown type is pushed as before", () => {
  const p = prefs.fromDocument({});
  assert.equal(prefs.wantsPush(p, { type: "somethingNew" }), true);
});
