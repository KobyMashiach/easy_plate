const test = require("node:test");
const assert = require("node:assert/strict");
const { staleReason } = require("./cleanupStaleInvites");

test("an accepted invite stands only while its target is on the owner's roster", () => {
  const invite = { ownerUid: "o", targetUid: "m" };
  assert.equal(staleReason(invite, { ownerUid: "o", memberUids: ["m"] }), null);
  assert.equal(staleReason(invite, { ownerUid: "o", memberUids: [] }), "not_a_member");
  assert.equal(staleReason(invite, null), "collab_gone");
  assert.equal(staleReason(invite, { ownerUid: "x", memberUids: ["m"] }), "owner_changed");
});
