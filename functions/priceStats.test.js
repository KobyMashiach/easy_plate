const test = require("node:test");
const assert = require("node:assert/strict");

process.env.GCLOUD_PROJECT = process.env.GCLOUD_PROJECT || "easy-plate";
process.env.FIREBASE_CONFIG =
  process.env.FIREBASE_CONFIG || JSON.stringify({ projectId: "easy-plate" });

const { normalizeName, keyFor, fold, median, validRecord, share: shareFn, COLLECTION: STATS, WINDOW_COLLECTION } = require("./priceStats").internals;

test("names normalise to one key however they were typed", () => {
  assert.equal(normalizeName("  חָלָב 3%, תנובה "), "חלב 3% תנובה");
  assert.equal(normalizeName("Milk 3%"), "milk 3%");
  assert.equal(keyFor(normalizeName("חלב 3%")), keyFor(normalizeName("חלב  3% ")));
});

test("the fold keeps a mean, a median and a bounded window", () => {
  let doc = null;
  for (const p of [10, 10, 11, 1000]) doc = fold(doc, p, 1);
  assert.equal(doc.count, 4);
  assert.equal(doc.avg, 257.75, "the mean is dragged by the typo");
  assert.equal(doc.median, 10.5, "the median is not");
  for (let i = 0; i < 40; i++) doc = fold(doc, 12, 1);
  assert.equal(doc.recent.length, 25);
});

test("median of odd and even windows", () => {
  assert.equal(median([3, 1, 2]), 2);
  assert.equal(median([4, 1, 3, 2]), 2.5);
});

test("only sane records are accepted", () => {
  assert.equal(validRecord({ name: "חלב", price: "6.90" }).price, 6.9);
  assert.equal(validRecord({ name: "", price: 5 }), null);
  assert.equal(validRecord({ name: "x", price: -1 }), null);
  assert.equal(validRecord({ name: "x", price: 99999 }), null);
  assert.equal(validRecord("nope"), null);
});

const { share, COLLECTION } = require("./priceStats").internals;

// Enough Firestore for share(): documents by path and a transaction whose
// reads and writes land on the same map.
function fakeDb(seed = {}) {
  const store = new Map(Object.entries(seed));
  const snapOf = (path) => ({ exists: store.has(path), data: () => store.get(path), get: (field) => (store.get(path) || {})[field] });
  const docRef = (path) => ({ path, id: path.split("/").pop(), get: async () => snapOf(path) });
  const tx = {
    get: (ref) => ref.get(),
    set: (ref, data, opts) => store.set(ref.path, opts && opts.merge ? { ...(store.get(ref.path) || {}), ...data } : data),
  };
  return {
    store,
    collection: (name) => ({ doc: (id) => docRef(`${name}/${id}`) }),
    runTransaction: async (fn) => fn(tx),
  };
}

test("a receipt is counted against the day before it is folded in, and refused as a whole once the day is spent", async () => {
  const calls = [];
  const spend = async (args) => {
    calls.push(args);
    return { allowed: true, used: args.amount, limit: 500 };
  };
  const db = fakeDb();
  const out = await share(db, "u1", [{ name: "חלב", price: 6.9 }, { name: "לחם", price: 12 }, { name: "", price: 3 }], { spend, now: () => 1 });
  assert.equal(out.status, 200);
  assert.equal(out.body.written, 2);
  assert.equal(calls.length, 1);
  assert.equal(calls[0].kind, "priceRecords");
  assert.equal(calls[0].amount, 2, "only the valid records count");
  assert.equal(db.store.get(`${COLLECTION}/${keyFor(normalizeName("חלב"))}`).count, 1);

  const refused = await share(fakeDb(), "u1", [{ name: "חלב", price: 6.9 }], { spend: async () => ({ allowed: false, used: 500, limit: 500 }) });
  assert.equal(refused.status, 429);
  assert.equal(refused.body.error.code, "quota");
  assert.equal(refused.body.error.quota.kind, "priceRecords");

  const empty = await share(fakeDb(), "u1", [{ name: "x", price: -1 }], { spend: async () => { throw new Error("must not be asked"); } });
  assert.equal(empty.status, 400);
});

test("one account holds one slot of the median window, however many prices it sends", async () => {
  const spend = async (args) => ({ allowed: true, used: args.amount, limit: 500 });
  const db = fakeDb();
  const key = keyFor(normalizeName("חלב"));
  for (const uid of ["a", "b", "c"]) await shareFn(db, uid, [{ name: "חלב", price: 7 }], { spend, now: () => 1 });
  // One request with the same product many times counts it once, and
  // repeated requests replace the account's own price instead of piling up.
  await shareFn(db, "evil", Array.from({ length: 25 }, () => ({ name: "חלב", price: 9000 })), { spend, now: () => 1 });
  for (let i = 0; i < 30; i++) await shareFn(db, "evil", [{ name: "חלב", price: 9000 }], { spend, now: () => 1 });
  const stat = db.store.get(`${STATS}/${key}`);
  assert.deepEqual(stat.recent, [7, 7, 7, 9000]);
  assert.equal(stat.median, 7);
  assert.equal(stat.recentBy, undefined, "who gave which price is not on the public document");
  assert.equal(db.store.get(`${WINDOW_COLLECTION}/${key}`).recentBy.length, 4);
});

test("a window written before contributors were tracked is kept and extended", () => {
  const doc = fold({ count: 2, sum: 20, recent: [10, 10] }, 12, 1, "t1");
  assert.deepEqual(doc.recent, [10, 10, 12]);
  assert.deepEqual(doc.recentBy, [null, null, "t1"]);
});

test("a record without unit or currency keeps the legacy per-name key; with them it gets its own aggregate", async () => {
  const legacy = validRecord({ name: "עגבניות", price: 8 });
  assert.equal(legacy.key, keyFor(normalizeName("עגבניות")), "old clients' key is unchanged");
  assert.equal(validRecord({ name: "עגבניות", price: 8, currency: "ils" }).key, legacy.key, "ILS is the default, any case");
  const perKg = validRecord({ name: "עגבניות", price: 8, unit: "kg" });
  const perKgUsd = validRecord({ name: "עגבניות", price: 8, unit: "kg", currency: "USD" });
  const perUnit = validRecord({ name: "עגבניות", price: 8, unit: "unit" });
  assert.equal(perKg.key, keyFor("עגבניות", "kg", "ILS"));
  assert.equal(new Set([legacy.key, perKg.key, perKgUsd.key, perUnit.key]).size, 4);
  assert.equal(validRecord({ name: "x", price: 1, unit: "box" }), null, "an unknown unit is refused, not folded into the wrong aggregate");
  assert.equal(validRecord({ name: "x", price: 1, unit: 3 }), null);
  assert.equal(validRecord({ name: "x", price: 1, currency: "shekel" }), null);

  const spend = async (args) => ({ allowed: true, used: args.amount, limit: 500 });
  const db = fakeDb();
  const out = await shareFn(db, "u1", [
    { name: "עגבניות", price: 6 },
    { name: "עגבניות", price: 8, unit: "kg" },
    { name: "עגבניות", price: 3, unit: "unit" },
    { name: "עגבניות", price: 9, unit: "kg" },
  ], { spend, now: () => 1 });
  assert.equal(out.body.written, 3, "one per product AND unit per request");
  const old = db.store.get(`${STATS}/${legacy.key}`);
  assert.equal(old.median, 6);
  assert.equal(old.unit, undefined, "the legacy document keeps its shape");
  const kg = db.store.get(`${STATS}/${perKg.key}`);
  assert.equal(kg.median, 8);
  assert.equal(kg.unit, "kg");
  assert.equal(kg.currency, "ILS");
});
