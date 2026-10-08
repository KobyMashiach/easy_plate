const test = require("node:test");
const assert = require("node:assert/strict");
const { tierOf, seatsFor, entitlementActive, householdTierFor, inheritedEntitlement, mayInherit } = require("./households").internals;

const ts = (ms) => ({ toMillis: () => ms });
const now = 1_000_000;

test("the tier is read from the product id", () => {
  assert.equal(tierOf("easyplate_duo_monthly"), "duo");
  assert.equal(tierOf("EasyPlate.Family.Yearly"), "family");
  assert.equal(tierOf("easyplate_pro_monthly"), "pro");
  assert.equal(tierOf(""), "pro");
  assert.equal(seatsFor("duo"), 2);
  assert.equal(seatsFor("family"), 6);
  assert.equal(seatsFor("pro"), 1);
});

test("an entitlement is active between premiumFrom and premiumUntil", () => {
  assert.equal(entitlementActive(null, now), false);
  assert.equal(entitlementActive({ premium: false }, now), false);
  assert.equal(entitlementActive({ premium: true }, now), true);
  assert.equal(entitlementActive({ premium: true, premiumUntil: ts(now - 1) }, now), false);
  assert.equal(entitlementActive({ premium: true, premiumUntil: ts(now + 1) }, now), true);
  assert.equal(entitlementActive({ premium: true, premiumFrom: ts(now + 1) }, now), false);
});

test("only a live duo or family purchase of one's own opens a household", () => {
  assert.equal(householdTierFor({ premium: true, productId: "duo_m" }, now), "duo");
  assert.equal(householdTierFor({ premium: true, productId: "family_y" }, now), "family");
  assert.equal(householdTierFor({ premium: true, productId: "pro_m" }, now), null);
  assert.equal(householdTierFor({ premium: true, productId: "duo_m", premiumUntil: ts(now - 1) }, now), null);
  assert.equal(householdTierFor({ premium: true, productId: "family_y", source: "household" }, now), null);
  assert.equal(householdTierFor(null, now), null);
});

test("members inherit the owner's verdict, including a lapse", () => {
  const live = inheritedEntitlement({ premium: true, productId: "duo_m", premiumUntil: ts(now + 5) }, "h1", now);
  assert.equal(live.premium, true);
  assert.equal(live.source, "household");
  assert.equal(live.householdId, "h1");
  assert.equal(live.productId, "duo_m");
  assert.equal(live.premiumUntil.toMillis(), now + 5);
  const lapsed = inheritedEntitlement({ premium: true, productId: "duo_m", premiumUntil: ts(now - 5) }, "h1", now);
  assert.equal(lapsed.premium, false);
  assert.equal(lapsed.premiumUntil, null);
});

test("a member's own live subscription is never overwritten", () => {
  assert.equal(mayInherit(undefined, now), true);
  assert.equal(mayInherit({ premium: true, source: "household" }, now), true);
  assert.equal(mayInherit({ premium: true, source: "revenuecat", premiumUntil: ts(now - 1) }, now), true);
  assert.equal(mayInherit({ premium: true, source: "revenuecat", premiumUntil: ts(now + 1) }, now), false);
  assert.equal(mayInherit({ premium: true, source: "admin", adminLock: true }, now), false);
});
