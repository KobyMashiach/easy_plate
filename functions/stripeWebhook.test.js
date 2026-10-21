const test = require("node:test");
const assert = require("node:assert/strict");

process.env.GCLOUD_PROJECT = process.env.GCLOUD_PROJECT || "easy-plate";
process.env.FIREBASE_CONFIG = process.env.FIREBASE_CONFIG || JSON.stringify({ projectId: "easy-plate" });

const { uidIn, customerIdIn, periodEndMs, decide, eventRecord } = require("./stripeWebhook").internals;

const UID = "AbCdEfGhIjKlMnOpQrStUvWxYz12";
const NOW_S = 1_800_000_000;
const END_S = NOW_S + 30 * 24 * 3600;

const subscription = (over = {}) => ({
  id: "sub_1",
  object: "subscription",
  customer: "cus_1",
  status: "active",
  cancel_at_period_end: false,
  metadata: { uid: UID },
  items: { data: [{ current_period_end: END_S, price: { id: "price_1", lookup_key: "easy_plate_ai_pro_duo_monthly", currency: "ils" } }] },
  ...over,
});

const event = (type, object, over = {}) => ({ id: `evt_${type}`, type, created: NOW_S, livemode: false, data: { object }, ...over });

test("the uid is read from wherever our metadata comes back", () => {
  assert.equal(uidIn(event("customer.subscription.updated", subscription())), UID);
  assert.equal(uidIn(event("checkout.session.completed", { client_reference_id: UID })), UID);
  assert.equal(uidIn(event("checkout.session.completed", { metadata: { uid: UID } })), UID);
  assert.equal(uidIn(event("invoice.paid", { parent: { subscription_details: { metadata: { uid: UID } } } })), UID);
  assert.equal(uidIn(event("invoice.paid", { subscription_details: { metadata: { uid: UID } } })), UID);
  assert.equal(uidIn(event("invoice.paid", { customer: "cus_1" })), null);
  assert.equal(uidIn(event("customer.subscription.updated", subscription({ metadata: { uid: "short" } }))), null);
  assert.equal(customerIdIn(event("invoice.paid", { customer: "cus_9" })), "cus_9");
  assert.equal(customerIdIn(event("invoice.paid", { customer: { id: "cus_8" } })), "cus_8");
});

test("the period end is read from the subscription or its items, whichever the API version carries", () => {
  assert.equal(periodEndMs(subscription()), END_S * 1000);
  assert.equal(periodEndMs(subscription({ items: { data: [] }, current_period_end: END_S + 5 })), (END_S + 5) * 1000);
  assert.equal(periodEndMs(subscription({ items: { data: [] } })), null);
});

test("an active subscription grants premium until the period end, as a stripe-sourced entitlement", () => {
  const { entitlement, customer } = decide(event("customer.subscription.created", subscription()), UID);
  assert.equal(entitlement.uid, UID);
  assert.equal(entitlement.data.premium, true);
  assert.equal(entitlement.data.premiumUntil.getTime(), END_S * 1000);
  assert.equal(entitlement.data.source, "stripe");
  assert.equal(entitlement.data.store, "stripe");
  assert.equal(entitlement.data.productId, "easy_plate_ai_pro_duo_monthly");
  assert.equal(entitlement.data.lastEventAt, NOW_S * 1000);
  assert.equal(entitlement.data.environment, "SANDBOX");
  assert.equal(entitlement.data.stripeSubscriptionId, "sub_1");
  assert.equal(customer.data.subscriptionStatus, "active");
  assert.equal(customer.data.everSubscribed, true);
});

test("cancelling keeps premium to the period end; deletion and unpaid revoke; incomplete says nothing", () => {
  const cancelled = decide(event("customer.subscription.updated", subscription({ cancel_at_period_end: true })), UID);
  assert.equal(cancelled.entitlement.data.premium, true);
  assert.equal(cancelled.entitlement.data.cancelAtPeriodEnd, true);
  assert.equal(decide(event("customer.subscription.updated", subscription({ status: "past_due" })), UID).entitlement.data.premium, true);
  assert.equal(decide(event("customer.subscription.updated", subscription({ status: "trialing" })), UID).entitlement.data.premium, true);

  const deleted = decide(event("customer.subscription.deleted", subscription({ status: "canceled" })), UID);
  assert.equal(deleted.entitlement.data.premium, false);
  assert.equal(deleted.entitlement.data.premiumUntil, null);
  assert.equal(deleted.customer.data.subscriptionStatus, "canceled");

  assert.equal(decide(event("customer.subscription.updated", subscription({ status: "unpaid" })), UID).entitlement.data.premium, false);
  assert.equal(decide(event("customer.subscription.updated", subscription({ status: "canceled" })), UID).entitlement.data.premium, false);

  const pending = decide(event("customer.subscription.created", subscription({ status: "incomplete" })), UID);
  assert.equal(pending.entitlement, null);
  assert.equal(pending.customer.data.subscriptionStatus, "incomplete");
});

test("checkout completion only records the customer; invoices and unknown uids write nothing", () => {
  const done = decide(event("checkout.session.completed", { mode: "subscription", customer: "cus_1", subscription: "sub_1", client_reference_id: UID }), UID);
  assert.equal(done.entitlement, null);
  assert.equal(done.customer.data.stripeCustomerId, "cus_1");
  assert.equal(done.customer.data.subscriptionId, "sub_1");
  assert.equal(done.customer.data.everSubscribed, true);
  assert.deepEqual(decide(event("checkout.session.completed", { mode: "payment" }), UID), { entitlement: null, customer: null });
  assert.deepEqual(decide(event("invoice.paid", { amount_paid: 2000 }), UID), { entitlement: null, customer: null });
  assert.deepEqual(decide(event("customer.subscription.updated", subscription()), null), { entitlement: null, customer: null });
});

test("every event leaves an audit row the subscriptions screen can read", () => {
  const sub = eventRecord(event("customer.subscription.created", subscription(), { livemode: true }), UID);
  assert.equal(sub.id, "evt_customer.subscription.created");
  assert.equal(sub.data.uid, UID);
  assert.equal(sub.data.store, "stripe");
  assert.equal(sub.data.grantsPremium, true);
  assert.deepEqual(sub.data.entitlementIds, ["easy_plate_ai_pro"]);
  assert.equal(sub.data.environment, "PRODUCTION");
  assert.equal(sub.data.expiresAt.getTime(), END_S * 1000);
  assert.equal(sub.data.currency, "ILS");

  const paid = eventRecord(event("invoice.paid", { customer: "cus_1", amount_paid: 2000, currency: "ils" }), UID);
  assert.equal(paid.data.price, 20);
  assert.equal(paid.data.grantsPremium, false);
  assert.equal(paid.data.stripeCustomerId, "cus_1");

  const orphan = eventRecord(event("invoice.payment_failed", { customer: "cus_x", amount_due: 2000 }), null);
  assert.equal(orphan.data.uid, null);
  assert.equal(eventRecord({ type: "x" }, UID), null);
});

// A Firestore stand-in for `process`: documents by path, a transaction over
// the same map, and the one query uidByCustomer runs.
function fakeDb(seed = {}) {
  const store = new Map(Object.entries(seed));
  const snapOf = (path) => ({ exists: store.has(path), id: path.split("/").pop(), data: () => store.get(path), get: (f) => (store.get(path) || {})[f] });
  const docRef = (path) => ({
    path,
    get: async () => snapOf(path),
    set: async (data, opts) => store.set(path, opts && opts.merge ? { ...(store.get(path) || {}), ...data } : data),
  });
  const collection = (name) => ({
    doc: (id) => docRef(`${name}/${id}`),
    where: (field, op, value) => ({ limit: () => ({ get: async () => {
      const docs = [...store.entries()].filter(([p, d]) => p.startsWith(`${name}/`) && d[field] === value).map(([p]) => snapOf(p));
      return { empty: docs.length === 0, docs };
    } }) }),
  });
  const tx = {
    get: (ref) => ref.get(),
    set: (ref, data, opts) => store.set(ref.path, opts && opts.merge ? { ...(store.get(ref.path) || {}), ...data } : data),
  };
  return { store, collection, runTransaction: (fn) => fn(tx) };
}

const { process: handle, CUSTOMERS, EVENTS_COLLECTION } = require("./stripeWebhook").internals;

test("a late, older subscription event cannot overwrite a newer status; a newer one can", async () => {
  const db = fakeDb();
  const exists = async () => true;
  await handle(db, event("customer.subscription.deleted", subscription({ status: "canceled" }), { id: "evt_del", created: NOW_S + 10 }), { userExists: exists });
  assert.equal(db.store.get(`${CUSTOMERS}/${UID}`).subscriptionStatus, "canceled");
  // The `updated` from ten seconds earlier arrives last: ignored.
  await handle(db, event("customer.subscription.updated", subscription({ status: "active" }), { id: "evt_upd", created: NOW_S }), { userExists: exists });
  assert.equal(db.store.get(`${CUSTOMERS}/${UID}`).subscriptionStatus, "canceled");
  assert.ok(db.store.has(`${EVENTS_COLLECTION}/evt_upd`), "the audit row is still written");
  // A genuinely newer one lands.
  await handle(db, event("customer.subscription.updated", subscription({ status: "active" }), { id: "evt_new", created: NOW_S + 20 }), { userExists: exists });
  assert.equal(db.store.get(`${CUSTOMERS}/${UID}`).subscriptionStatus, "active");
  // A checkout record (no status, no lastEventAt) merges in whenever it comes.
  await handle(db, event("checkout.session.completed", { mode: "subscription", customer: "cus_1", subscription: "sub_1", client_reference_id: UID }, { id: "evt_co", created: NOW_S - 5 }), { userExists: exists });
  assert.equal(db.store.get(`${CUSTOMERS}/${UID}`).everSubscribed, true);
  assert.equal(db.store.get(`${CUSTOMERS}/${UID}`).subscriptionStatus, "active");
});

test("events for an account that no longer exists leave only the audit row", async () => {
  const db = fakeDb();
  const out = await handle(db, event("customer.subscription.deleted", subscription({ status: "canceled" })), { userExists: async () => false });
  assert.equal(out.orphan, true);
  assert.equal(out.uid, UID);
  assert.equal(db.store.has(`${CUSTOMERS}/${UID}`), false);
  assert.equal(db.store.has(`entitlements/${UID}`), false);
  assert.ok(db.store.has(`${EVENTS_COLLECTION}/evt_customer.subscription.deleted`));
  // An invoice (no write beyond the audit row) never asks Auth at all.
  let asked = 0;
  await handle(db, event("invoice.paid", { customer: "cus_1", amount_paid: 2000 }), { userExists: async () => { asked++; return false; } });
  assert.equal(asked, 0);
});

test("two web subscriptions: cancelling or losing the old one never removes Premium the live one grants", async () => {
  const exists = async () => true;
  const db = fakeDb();
  const ent = () => db.store.get(`entitlements/${UID}`);
  const cust = () => db.store.get(`${CUSTOMERS}/${UID}`);
  const subA = (over = {}) => subscription({ id: "sub_A", ...over });
  const subB = (over = {}) => subscription({ id: "sub_B", items: { data: [{ current_period_end: END_S + 86400, price: { id: "price_1", lookup_key: "easy_plate_ai_pro_monthly", currency: "ils" } }] }, ...over });

  await handle(db, event("customer.subscription.created", subA(), { id: "e1", created: NOW_S }), { userExists: exists });
  await handle(db, event("customer.subscription.created", subB(), { id: "e2", created: NOW_S + 5 }), { userExists: exists });
  assert.equal(ent().premium, true);
  assert.equal(cust().subscriptionId, "sub_B", "the live one with the later period end decides");

  // The buyer cancels the old one in the portal; then it is deleted.
  const outU = await handle(db, event("customer.subscription.updated", subA({ cancel_at_period_end: true }), { id: "e3", created: NOW_S + 10 }), { userExists: exists });
  assert.equal(outU.superseded, true);
  const outD = await handle(db, event("customer.subscription.deleted", subA({ status: "canceled" }), { id: "e4", created: NOW_S + 20 }), { userExists: exists });
  assert.equal(outD.superseded, true);
  assert.equal(ent().premium, true);
  assert.equal(ent().stripeSubscriptionId, "sub_B");
  assert.equal(ent().premiumUntil.toMillis(), (END_S + 86400) * 1000);
  assert.equal(cust().subscriptionId, "sub_B");
  assert.equal(cust().subscriptionStatus, "active");
  assert.equal(cust().subscriptions.sub_A.status, "canceled");

  // Now the live one ends too: Premium goes.
  await handle(db, event("customer.subscription.deleted", subB({ status: "canceled" }), { id: "e5", created: NOW_S + 30 }), { userExists: exists });
  assert.equal(ent().premium, false);
  assert.equal(cust().subscriptionStatus, "canceled");
});

test("cross-subscription order: an older 'created' for a new subscription still lands after the old one's newer deletion", async () => {
  const exists = async () => true;
  const db = fakeDb();
  await handle(db, event("customer.subscription.created", subscription({ id: "sub_A" }), { id: "e1", created: NOW_S }), { userExists: exists });
  await handle(db, event("customer.subscription.deleted", subscription({ id: "sub_A", status: "canceled" }), { id: "e2", created: NOW_S + 20 }), { userExists: exists });
  assert.equal(db.store.get(`entitlements/${UID}`).premium, false);
  await handle(db, event("customer.subscription.created", subscription({ id: "sub_B" }), { id: "e3", created: NOW_S + 10 }), { userExists: exists });
  assert.equal(db.store.get(`entitlements/${UID}`).premium, true);
  assert.equal(db.store.get(`${CUSTOMERS}/${UID}`).subscriptionId, "sub_B");
  // A checkout record arriving afterwards does not repoint the subscription id.
  await handle(db, event("checkout.session.completed", { mode: "subscription", customer: "cus_1", subscription: "sub_A", client_reference_id: UID }, { id: "e4", created: NOW_S - 5 }), { userExists: exists });
  assert.equal(db.store.get(`${CUSTOMERS}/${UID}`).subscriptionId, "sub_B");
});

test("a record written before the subscriptions map keeps its ordering", () => {
  const { mergeSubscription } = require("./stripeWebhook").internals;
  const stored = { subscriptionId: "sub_1", subscriptionStatus: "canceled", lastEventAt: (NOW_S + 10) * 1000 };
  const late = decide(event("customer.subscription.updated", subscription({ status: "active" }), { created: NOW_S }), UID);
  assert.equal(mergeSubscription(stored, late.customer, late.entitlement), null);
});

test("same-second events of one subscription: the later state wins whichever arrives last", async () => {
  const { statusRank } = require("./stripeWebhook").internals;
  assert.ok(statusRank("canceled") > statusRank("active"));
  assert.ok(statusRank("active") > statusRank("incomplete"));
  const exists = async () => true;
  // active then the same-second incomplete (created) arriving late: stays active.
  const db = fakeDb();
  await handle(db, event("customer.subscription.updated", subscription({ status: "active" }), { id: "e_a", created: NOW_S }), { userExists: exists });
  await handle(db, event("customer.subscription.created", subscription({ status: "incomplete" }), { id: "e_i", created: NOW_S }), { userExists: exists });
  assert.equal(db.store.get(`${CUSTOMERS}/${UID}`).subscriptionStatus, "active");
  assert.equal(db.store.get(`entitlements/${UID}`).premium, true);
  // canceled then a same-second active: stays canceled, Premium off.
  await handle(db, event("customer.subscription.deleted", subscription({ status: "canceled" }), { id: "e_c", created: NOW_S + 5 }), { userExists: exists });
  await handle(db, event("customer.subscription.updated", subscription({ status: "active" }), { id: "e_a2", created: NOW_S + 5 }), { userExists: exists });
  assert.equal(db.store.get(`${CUSTOMERS}/${UID}`).subscriptionStatus, "canceled");
  assert.equal(db.store.get(`entitlements/${UID}`).premium, false);
});

test("the entitlement is written inside the customer merge's transaction, under the admin lock", async () => {
  const exists = async () => true;
  const db = fakeDb({ [`entitlements/${UID}`]: { premium: true, adminLock: true, premiumUntil: null, source: "admin", lastEventAt: 0 } });
  let inTx = 0;
  const run = db.runTransaction;
  db.runTransaction = (fn) => { inTx++; return run(fn); };
  await handle(db, event("customer.subscription.deleted", subscription({ status: "canceled" }), { id: "e_x", created: NOW_S }), { userExists: exists });
  assert.equal(inTx, 1, "one transaction for the merge and the entitlement");
  assert.equal(db.store.get(`entitlements/${UID}`).adminLock, true);
  assert.equal(db.store.get(`entitlements/${UID}`).premium, true);
});
