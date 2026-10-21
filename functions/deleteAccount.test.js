const test = require("node:test");
const assert = require("node:assert/strict");

process.env.GCLOUD_PROJECT = process.env.GCLOUD_PROJECT || "easy-plate";
process.env.FIREBASE_CONFIG = process.env.FIREBASE_CONFIG || JSON.stringify({ projectId: "easy-plate" });
const { parseRequest, deleteQuery, stripeCleanupFor, stripeConfigured, deleteStripeCustomer, STRIPE_CUSTOMERS } = require("./deleteAccount").internals;
const { StripeError } = require("./stripeClient");

test("the request has to confirm in as many words", () => {
  assert.equal(parseRequest({ confirm: true }).confirm, true);
  assert.equal(parseRequest({ confirm: "true" }).error, "confirm is required");
  assert.equal(parseRequest({}).error, "confirm is required");
  assert.equal(parseRequest(null).error, "confirm is required");
});

test("a query's documents are deleted in batches, or subtree by subtree", async () => {
  const deleted = [];
  const docs = Array.from({ length: 5 }, (_, i) => ({ ref: `d${i}` }));
  const db = {
    batch: () => ({ delete: (ref) => deleted.push(`batch:${ref}`), commit: async () => {} }),
    recursiveDelete: async (ref) => deleted.push(`tree:${ref}`),
  };
  const query = { get: async () => ({ docs, size: docs.length }) };
  assert.equal(await deleteQuery(db, query), 5);
  assert.equal(await deleteQuery(db, query, { subtrees: true }), 5);
  assert.deepEqual(deleted.slice(0, 5), ["batch:d0", "batch:d1", "batch:d2", "batch:d3", "batch:d4"]);
  assert.deepEqual(deleted.slice(5), ["tree:d0", "tree:d1", "tree:d2", "tree:d3", "tree:d4"]);
});

test("the Stripe customer always goes; the subscription only while it may still be running", () => {
  assert.deepEqual(stripeCleanupFor(null), { customerId: null, subscriptionId: null });
  assert.deepEqual(stripeCleanupFor({ everSubscribed: true }), { customerId: null, subscriptionId: null });
  assert.deepEqual(stripeCleanupFor({ stripeCustomerId: "cus_1" }), { customerId: "cus_1", subscriptionId: null });
  assert.deepEqual(stripeCleanupFor({ stripeCustomerId: "cus_1", subscriptionId: "sub_1", subscriptionStatus: "active" }), { customerId: "cus_1", subscriptionId: "sub_1" });
  assert.deepEqual(stripeCleanupFor({ stripeCustomerId: "cus_1", subscriptionId: "sub_1", subscriptionStatus: "past_due" }), { customerId: "cus_1", subscriptionId: "sub_1" });
  // Only a checkout so far, no status yet: cancel it, Stripe says 404 if it never started.
  assert.deepEqual(stripeCleanupFor({ stripeCustomerId: "cus_1", subscriptionId: "sub_1" }), { customerId: "cus_1", subscriptionId: "sub_1" });
  assert.deepEqual(stripeCleanupFor({ stripeCustomerId: "cus_1", subscriptionId: "sub_1", subscriptionStatus: "canceled" }), { customerId: "cus_1", subscriptionId: null });
  assert.deepEqual(stripeCleanupFor({ stripeCustomerId: "cus_1", subscriptionId: "sub_1", subscriptionStatus: "incomplete_expired" }), { customerId: "cus_1", subscriptionId: null });
  assert.equal(stripeConfigured("sk_test_x"), true);
  assert.equal(stripeConfigured(""), false);
  assert.equal(stripeConfigured("-"), false);
  assert.equal(stripeConfigured(undefined), false);
});

function customersDb(data) {
  const store = new Map(data ? [[`${STRIPE_CUSTOMERS}/u1`, data]] : []);
  return {
    store,
    collection: (name) => ({
      doc: (id) => ({
        get: async () => ({ exists: store.has(`${name}/${id}`), data: () => store.get(`${name}/${id}`) }),
        delete: async () => store.delete(`${name}/${id}`),
      }),
    }),
  };
}

test("deleting an account cancels its web subscription, deletes the Stripe customer, then the record", async () => {
  const calls = [];
  const request = async (secret, method, path) => { calls.push(`${method} ${path}`); return {}; };
  const db = customersDb({ stripeCustomerId: "cus_1", subscriptionId: "sub_1", subscriptionStatus: "active" });
  const out = await deleteStripeCustomer(db, "u1", "sk_test", request);
  assert.deepEqual(calls, ["DELETE /subscriptions/sub_1", "DELETE /customers/cus_1"]);
  assert.deepEqual(out, { customer: true, subscriptionCancelled: true, skipped: false });
  assert.equal(db.store.size, 0);
});

test("a subscription or customer Stripe no longer has is fine; any other refusal stops the deletion with the record intact", async () => {
  const gone = async (secret, method, path) => { throw new StripeError(404, { error: { code: "resource_missing", message: "No such subscription" } }); };
  const db = customersDb({ stripeCustomerId: "cus_1", subscriptionId: "sub_1", subscriptionStatus: "trialing" });
  assert.equal((await deleteStripeCustomer(db, "u1", "sk_test", gone)).customer, true);
  assert.equal(db.store.size, 0);

  const down = async () => { throw new StripeError(500, { error: { message: "Stripe is down" } }); };
  const kept = customersDb({ stripeCustomerId: "cus_2", subscriptionId: "sub_2", subscriptionStatus: "active" });
  await assert.rejects(deleteStripeCustomer(kept, "u1", "sk_test", down), (err) => err instanceof StripeError && err.status === 500);
  assert.equal(kept.store.size, 1, "the record stays so the deletion can be retried");
});

test("without the key the Stripe step is skipped with a warning, and the deletion goes on; without a record nothing is called", async () => {
  const calls = [];
  const request = async (secret, method, path) => { calls.push(path); return {}; };
  const db = customersDb({ stripeCustomerId: "cus_1", subscriptionId: "sub_1", subscriptionStatus: "active" });
  const out = await deleteStripeCustomer(db, "u1", "", request);
  assert.deepEqual(calls, []);
  assert.deepEqual(out, { customer: true, subscriptionCancelled: false, skipped: true });
  assert.equal(db.store.size, 0);
  const none = await deleteStripeCustomer(customersDb(null), "u1", "sk_test", request);
  assert.deepEqual(none, { customer: false, subscriptionCancelled: false, skipped: false });
  assert.deepEqual(calls, []);
});

test("a Stripe failure stops the deletion before the account leaves its household", async () => {
  const { deleteAccount } = require("./deleteAccount").internals;
  const householdsInternals = require("./households").internals;
  const stripeClient = require("./stripeClient");
  const originalLeave = householdsInternals.leave;
  const originalRequest = stripeClient.request;
  const steps = [];
  householdsInternals.leave = async () => { steps.push("leave"); return { ok: true }; };
  stripeClient.request = async () => { steps.push("stripe"); throw new StripeError(500, { error: { message: "Stripe is down" } }); };
  const db = customersDb({ stripeCustomerId: "cus_1", subscriptionId: "sub_1", subscriptionStatus: "active" });
  const base = db.collection;
  db.collection = (name) => (name === "households"
    ? { where: () => ({ limit: () => ({ get: async () => ({ empty: true, docs: [] }) }) }) }
    : base(name));
  try {
    await assert.rejects(deleteAccount(db, "u1", { stripeSecret: "sk_test" }), (err) => err instanceof StripeError);
    assert.deepEqual(steps, ["stripe"], "the household is left only after Stripe is settled");
    assert.equal(db.store.size, 1);
  } finally {
    householdsInternals.leave = originalLeave;
    stripeClient.request = originalRequest;
  }
});

test("the profile photo is deleted by its exact name, never by a uid prefix", async () => {
  const { deleteStorage } = require("./deleteAccount").internals;
  const listed = [];
  const deleted = [];
  const bucket = {
    getFiles: async ({ prefix }) => { listed.push(prefix); return [[{ delete: async () => deleted.push(`${prefix}a.jpg`) }]]; },
    file: (path) => ({ delete: async () => deleted.push(path) }),
  };
  await deleteStorage("abc", bucket);
  assert.deepEqual(listed, ["recipe_images/abc/"]);
  assert.ok(deleted.includes("profile_photos/abc.jpg"));
  assert.ok(!listed.some((p) => p.startsWith("profile_photos")));
});
