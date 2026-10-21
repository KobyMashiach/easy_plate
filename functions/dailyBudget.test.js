const test = require("node:test");
const assert = require("node:assert/strict");

process.env.GCLOUD_PROJECT = process.env.GCLOUD_PROJECT || "easy-plate";
process.env.FIREBASE_CONFIG = process.env.FIREBASE_CONFIG || JSON.stringify({ projectId: "easy-plate" });

const budget = require("./dailyBudget");

const TODAY = "2026-10-18";

test("a fresh user spends against an empty count; yesterday's count does not carry", () => {
  assert.deepEqual(budget.decide(null, TODAY, 300), { allowed: true, used: 1, limit: 300 });
  assert.deepEqual(budget.decide({ day: "2026-10-17", count: 300 }, TODAY, 300), { allowed: true, used: 1, limit: 300 });
  assert.deepEqual(budget.decide({ day: TODAY, count: 299 }, TODAY, 300), { allowed: true, used: 300, limit: 300 });
  assert.deepEqual(budget.decide({ day: TODAY, count: 300 }, TODAY, 300), { allowed: false, used: 300, limit: 300 });
});

test("an amount is counted whole and must fit in what is left of the day", () => {
  // 2900 used of 3000: a 500-line call no longer fits …
  assert.deepEqual(budget.decide({ day: TODAY, count: 2900 }, TODAY, 3000, 500), { allowed: false, used: 2900, limit: 3000, requested: 500 });
  // … a 100-line one does, exactly.
  assert.deepEqual(budget.decide({ day: TODAY, count: 2900 }, TODAY, 3000, 100), { allowed: true, used: 3000, limit: 3000 });
  // The first call of the day may take the whole allowance, and no more.
  assert.equal(budget.decide(null, TODAY, 3000, 3000).allowed, true);
  assert.equal(budget.decide(null, TODAY, 3000, 3001).allowed, false);
  assert.equal(budget.decide({ day: "2026-10-17", count: 3000 }, TODAY, 3000, 3000).allowed, true);
  // A caller may bound the first call lower still.
  assert.equal(budget.decide(null, TODAY, 3000, 2000, { firstMax: 1000 }).allowed, true, "fits anyway");
  assert.equal(budget.decide({ day: TODAY, count: 1 }, TODAY, 3000, 3000, { firstMax: 3000 }).allowed, false);
  // A zero amount still counts one, so a claim is never free.
  assert.equal(budget.decide(null, TODAY, 10, 0).used, 1);
  // A zero limit switches the feature off.
  assert.equal(budget.decide(null, TODAY, 0).allowed, false);
  assert.equal(budget.decide({ day: TODAY, count: "garbage" }, TODAY, 5).used, 1);
});

function fakeDb(seed = {}) {
  const store = new Map(Object.entries(seed));
  const ref = (path) => ({
    path,
    get: async () => ({ exists: store.has(path), data: () => store.get(path), get: (f) => (store.get(path) || {})[f] }),
  });
  const tx = {
    get: (r) => r.get(),
    set: (r, data, opts) => store.set(r.path, opts && opts.merge ? { ...(store.get(r.path) || {}), ...data } : data),
    update: (r, data) => store.set(r.path, { ...(store.get(r.path) || {}), ...data }),
  };
  return { store, collection: (name) => ({ doc: (id) => ref(`${name}/${id}`) }), runTransaction: (fn) => fn(tx) };
}

test("claim writes one document per user per kind, keyed on the day; refund gives the amount back", async () => {
  const db = fakeDb();
  const first = await budget.claim(db, { uid: "u1", kind: "speak", limit: 2, day: TODAY });
  assert.equal(first.allowed, true);
  const doc = db.store.get(`${budget.COLLECTION}/u1_speak`);
  assert.equal(doc.day, TODAY);
  assert.equal(doc.count, 1);
  assert.equal(doc.uid, "u1");
  assert.equal(doc.kind, "speak");
  assert.equal((await budget.claim(db, { uid: "u1", kind: "speak", limit: 2, day: TODAY })).allowed, true);
  const third = await budget.claim(db, { uid: "u1", kind: "speak", limit: 2, day: TODAY });
  assert.equal(third.allowed, false);
  assert.equal(db.store.get(`${budget.COLLECTION}/u1_speak`).count, 2, "a refusal does not move the count");
  // Another kind for the same user is its own document.
  await budget.claim(db, { uid: "u1", kind: "translate", limit: 10, amount: 7, day: TODAY });
  assert.equal(db.store.get(`${budget.COLLECTION}/u1_translate`).count, 7);
  await budget.refund(db, { uid: "u1", kind: "translate", amount: 7, day: TODAY });
  assert.equal(db.store.get(`${budget.COLLECTION}/u1_translate`).count, 0);
  // A refund for another day, or for a missing document, is a no-op.
  await budget.refund(db, { uid: "u1", kind: "translate", amount: 7, day: "2026-10-17" });
  assert.equal(db.store.get(`${budget.COLLECTION}/u1_translate`).count, 0);
  await budget.refund(db, { uid: "nobody", kind: "speak", day: TODAY });
  assert.equal(db.store.has(`${budget.COLLECTION}/nobody_speak`), false);
});

test("the refusal carries the quota object the app keys on, under the shared code", () => {
  const body = budget.refusalBody({ allowed: false, used: 150, limit: 150 }, "imageSearch");
  assert.equal(body.error.code, "quota");
  assert.equal(body.error.status, "RESOURCE_EXHAUSTED");
  assert.deepEqual(body.error.quota, { used: 150, limit: 150, kind: "imageSearch" });
  assert.match(body.error.message, /150 image searches/);
  const err = budget.exhausted({ allowed: false, used: 3, limit: 3 }, "speak");
  assert.equal(err.status, 429);
  assert.equal(err.code, "quota");
  assert.deepEqual(err.body.error.quota, { used: 3, limit: 3, kind: "speak" });
});

test("every kind names a console parameter with a default", () => {
  assert.equal(budget.KINDS.translate.param, "quota_translate_lines_daily");
  assert.equal(budget.KINDS.translate.fallback, 3000);
  assert.equal(budget.KINDS.speak.param, "quota_speak_calls_daily");
  assert.equal(budget.KINDS.speak.fallback, 300);
  assert.equal(budget.KINDS.imageSearch.param, "quota_image_search_daily");
  assert.equal(budget.KINDS.imageSearch.fallback, 150);
  assert.equal(budget.docId("u", "speak"), "u_speak");
});

test("shared price records have a budget of their own, read from the console", () => {
  assert.equal(budget.KINDS.priceRecords.param, "quota_price_records_daily");
  assert.equal(budget.KINDS.priceRecords.fallback, 500);
  // The whole receipt counts at once, and has to fit in what is left.
  assert.equal(budget.decide({ day: "2026-10-18", count: 480 }, "2026-10-18", 500, 50).allowed, false);
  assert.deepEqual(budget.decide({ day: "2026-10-18", count: 450 }, "2026-10-18", 500, 50), { allowed: true, used: 500, limit: 500 });
});

test("translate cache lookups have a budget of their own, counted in lines, read from the console", () => {
  assert.equal(budget.KINDS.translateCache.param, "quota_translate_cache_reads_daily");
  assert.equal(budget.KINDS.translateCache.fallback, 50000);
  // A 3000-line request has to fit in what is left of the day; the refusal
  // says what was asked so the clients cut the request down.
  const refused = budget.decide({ day: "2026-10-18", count: 49000 }, "2026-10-18", 50000, 3000);
  assert.equal(refused.allowed, false);
  assert.equal(refused.requested, 3000);
  assert.deepEqual(budget.refusalBody(refused, "translateCache").error.quota, { used: 49000, limit: 50000, kind: "translateCache", requested: 3000 });
  assert.deepEqual(budget.decide({ day: "2026-10-18", count: 47000 }, "2026-10-18", 50000, 3000), { allowed: true, used: 50000, limit: 50000 });
});
