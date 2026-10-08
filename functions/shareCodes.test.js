const test = require("node:test");
const assert = require("node:assert/strict");
const { normalizeCode, rejectReason, recipeCollabIdsIn } = require("./shareCodes").internals;

test("codes are normalised from what people type", () => {
  assert.equal(normalizeCode("ep-7k3m 9qx2"), "7K3M9QX2");
  assert.equal(normalizeCode("7K3M9QX2"), "7K3M9QX2");
  assert.equal(normalizeCode("EP7K3M9QX2"), "7K3M9QX2");
  assert.equal(normalizeCode("abc"), null);
  assert.equal(normalizeCode("7K3M9QX0"), null); // 0 and 1 are not in the alphabet
  assert.equal(normalizeCode(42), null);
});

test("a code is refused when revoked, expired, used up, missing or the owner's own", () => {
  const ts = (ms) => ({ toMillis: () => ms });
  const now = 1_000_000;
  const base = { kind: "recipe", ownerUid: "owner", targetId: "c1", uses: 0 };
  assert.equal(rejectReason(null, "u", now), "not_found");
  assert.equal(rejectReason({ ...base, revoked: true }, "u", now), "revoked");
  assert.equal(rejectReason({ ...base, expiresAt: ts(now - 1) }, "u", now), "expired");
  assert.equal(rejectReason({ ...base, expiresAt: ts(now + 1) }, "u", now), null);
  assert.equal(rejectReason({ ...base, maxUses: 1, uses: 1 }, "u", now), "used_up");
  assert.equal(rejectReason({ ...base, maxUses: 2, uses: 1 }, "u", now), null);
  assert.equal(rejectReason(base, "owner", now), "self");
  assert.equal(rejectReason({ ...base, kind: "pizza" }, "u", now), "not_found");
});

test("recipe ids are read from both container shapes", () => {
  assert.deepEqual(recipeCollabIdsIn({ recipes: [{ collabId: "a" }, { collabId: "b" }, {}] }), ["a", "b"]);
  assert.deepEqual(recipeCollabIdsIn({ meals: [{ items: [{ recipeCollabId: "x" }, { freeText: "soup" }] }, { items: [{ recipeCollabId: "x" }] }] }), ["x"]);
  assert.deepEqual(recipeCollabIdsIn(null), []);
});
