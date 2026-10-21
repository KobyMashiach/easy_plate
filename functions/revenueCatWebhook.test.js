// Run with: npm test
const test = require("node:test");
const assert = require("node:assert/strict");

process.env.GCLOUD_PROJECT = process.env.GCLOUD_PROJECT || "easy-plate";
process.env.FIREBASE_CONFIG =
  process.env.FIREBASE_CONFIG || JSON.stringify({ projectId: "easy-plate" });

const { decide, eventRecord, authorized, uidFor } = require("./revenueCatWebhook").internals;

const UID = "AbCdEfGhIjKlMnOpQrStUvWxYz12";
const NOW = 1_800_000_000_000;

const event = (overrides) => ({
  id: "evt-1",
  type: "INITIAL_PURCHASE",
  app_user_id: UID,
  aliases: [UID],
  entitlement_ids: ["easy_plate_ai_pro"],
  product_id: "premium_monthly",
  store: "PLAY_STORE",
  environment: "PRODUCTION",
  event_timestamp_ms: NOW,
  expiration_at_ms: NOW + 30 * 24 * 3600 * 1000,
  ...overrides,
});

test("a purchase grants premium until the expiry", () => {
  const [w] = decide(event());
  assert.equal(w.uid, UID);
  assert.equal(w.data.premium, true);
  assert.equal(w.data.premiumUntil.getTime(), NOW + 30 * 24 * 3600 * 1000);
  assert.equal(w.data.productId, "premium_monthly");
  assert.equal(w.data.lastEventAt, NOW);
});

test("renewal and cancellation keep premium; only expiration revokes it", () => {
  assert.equal(decide(event({ type: "RENEWAL" }))[0].data.premium, true);
  // Cancelling turns auto-renew off; the period already paid for stays.
  assert.equal(decide(event({ type: "CANCELLATION" }))[0].data.premium, true);
  assert.equal(decide(event({ type: "BILLING_ISSUE" }))[0].data.premium, true);
  const [expired] = decide(event({ type: "EXPIRATION" }));
  assert.equal(expired.data.premium, false);
  assert.equal(expired.data.premiumUntil, null);
});

test("a lifetime purchase has no expiry", () => {
  const [w] = decide(event({ type: "NON_RENEWING_PURCHASE", expiration_at_ms: null }));
  assert.equal(w.data.premium, true);
  assert.equal(w.data.premiumUntil, null);
});

test("events about other entitlements are ignored", () => {
  assert.deepEqual(decide(event({ entitlement_ids: ["something_else"] })), []);
  assert.deepEqual(decide(event({ entitlement_ids: [] })), []);
});

test("anonymous receipts have no document; an alias to a uid does", () => {
  const anon = "$RCAnonymousID:abcdef";
  assert.deepEqual(decide(event({ app_user_id: anon, aliases: [anon] })), []);
  assert.equal(uidFor({ app_user_id: anon, aliases: [anon, UID] }), UID);
});

test("test events are acknowledged without a write", () => {
  assert.deepEqual(decide(event({ type: "TEST" })), []);
});

test("a transfer revokes the accounts it left", () => {
  const other = "ZyXwVuTsRqPoNmLkJiHgFeDcBa21";
  const writes = decide(
    event({
      type: "TRANSFER",
      entitlement_ids: undefined,
      transferred_from: [UID, "$RCAnonymousID:x"],
      transferred_to: [other],
    }),
  );
  assert.equal(writes.length, 1);
  assert.equal(writes[0].uid, UID);
  assert.equal(writes[0].data.premium, false);
});

test("the authorization header must match the secret exactly", () => {
  assert.equal(authorized("s3cret", "s3cret"), true);
  assert.equal(authorized("Bearer s3cret", "s3cret"), true);
  assert.equal(authorized("s3cret ", "s3cret"), false);
  assert.equal(authorized("", "s3cret"), false);
  assert.equal(authorized(undefined, "s3cret"), false);
  assert.equal(authorized("s3cret", ""), false);
});

test("every event is recorded, with whether it carried the entitlement", () => {
  const r = eventRecord(event({ entitlement_ids: [] , price_in_purchased_currency: 20, currency: "ILS" }));
  assert.equal(r.id, "evt-1");
  assert.equal(r.data.uid, UID);
  assert.equal(r.data.grantsPremium, false);
  assert.equal(r.data.price, 20);
  assert.equal(r.data.currency, "ILS");
  assert.equal(eventRecord(event({ type: "TEST" })), null);
  const anon = eventRecord(event({ app_user_id: "$RCAnonymousID:1", aliases: [] }));
  assert.equal(anon.data.uid, null);
});

test("an app user id that cannot be a document id is treated as anonymous", () => {
  const { decide, eventRecord, isAnonymous } = require("./revenueCatWebhook").internals;
  for (const bad of ["a/b", "..", ".", "__x__", "x".repeat(129)]) assert.equal(isAnonymous(bad), true, bad);
  assert.equal(isAnonymous("uid123"), false);
  const event = { type: "INITIAL_PURCHASE", app_user_id: "users/victim", aliases: ["../x"], entitlement_ids: ["easy_plate_ai_pro"], expiration_at_ms: Date.now() + 1e9, id: "ev/1" };
  assert.deepEqual(decide(event), []);
  assert.equal(eventRecord(event).id, "ev_1");
  assert.equal(eventRecord(event).data.uid, null);
});

test("one source's revocation does not end premium another source still holds", () => {
  const { revokesAnotherSource } = require("./revenueCatWebhook").internals;
  const now = 1_000_000;
  const ts = (ms) => ({ toMillis: () => ms });
  const off = (source) => ({ source, premium: false });
  assert.equal(revokesAnotherSource({ premium: true, source: "revenuecat", premiumUntil: ts(now + 1) }, off("stripe"), now), true);
  assert.equal(revokesAnotherSource({ premium: true, source: "stripe" }, off("revenuecat"), now), true);
  assert.equal(revokesAnotherSource({ premium: true, source: "household" }, off("revenuecat"), now), true);
  assert.equal(revokesAnotherSource({ premium: true, source: "revenuecat" }, off("revenuecat"), now), false, "a source ends its own");
  assert.equal(revokesAnotherSource({ premium: true, source: "revenuecat", premiumUntil: ts(now - 1) }, off("stripe"), now), false, "already over");
  assert.equal(revokesAnotherSource({ premium: false, source: "revenuecat" }, off("stripe"), now), false);
  assert.equal(revokesAnotherSource({ premium: true, source: "revenuecat" }, { source: "stripe", premium: true }, now), false, "a grant is not a revocation");
  assert.equal(revokesAnotherSource(undefined, off("stripe"), now), false);
});
