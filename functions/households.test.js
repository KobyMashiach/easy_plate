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

const { create } = require("./households").internals;

// Enough Firestore for create(): one array-contains query, documents by
// path, and a transaction whose reads see the store and whose writes land
// on it. Each runTransaction runs the body once.
function fakeDb(seed = {}) {
  const store = new Map(Object.entries(seed));
  let counter = 0;
  const snapOf = (path) => {
    const data = store.get(path);
    return { exists: store.has(path), id: path.split("/").pop(), data: () => data, get: (f) => (data || {})[f] };
  };
  const docRef = (path) => ({ path, id: path.split("/").pop(), get: async () => snapOf(path) });
  const collection = (name) => ({
    doc: (id) => docRef(`${name}/${id || `auto${++counter}`}`),
    where: (field, op, value) => ({
      limit: () => ({
        get: async () => {
          const docs = [...store.entries()]
            .filter(([path, data]) => path.startsWith(`${name}/`) && Array.isArray(data[field]) && data[field].includes(value))
            .map(([path]) => snapOf(path));
          return { empty: docs.length === 0, docs };
        },
      }),
    }),
  });
  const tx = {
    get: (target) => target.get(),
    set: (ref, data) => store.set(ref.path, data),
  };
  return { store, collection, runTransaction: async (fn) => fn(tx) };
}

test("create reads membership and entitlement inside the transaction and writes the household there", async () => {
  const db = fakeDb({ "entitlements/owner": { premium: true, productId: "easyplate_duo_monthly" } });
  const out = await create(db, "owner", "Home");
  assert.equal(out.error, undefined);
  assert.equal(out.household.tier, "duo");
  assert.equal(out.household.seats, 2);
  assert.deepEqual(out.household.memberUids, ["owner"]);
  const written = [...db.store.entries()].find(([path]) => path.startsWith("households/"));
  assert.ok(written, "the household document is written through the transaction");
  assert.equal(written[1].ownerUid, "owner");

  // A second create by the same owner sees the first one and is refused.
  const again = await create(db, "owner", "Second");
  assert.equal(again.error, "in_household");
  assert.equal([...db.store.keys()].filter((p) => p.startsWith("households/")).length, 1);

  const free = await create(fakeDb({ "entitlements/u": { premium: true, productId: "easyplate_pro_monthly" } }), "u", "x");
  assert.equal(free.error, "not_eligible");
  assert.equal((await create(fakeDb(), "nobody", "x")).error, "not_eligible");
});

test("a downgrade marks the household over its seats instead of removing anyone", () => {
  const { seatCheck } = require("./households").internals;
  const four = { memberUids: ["o", "a", "b", "c"] };
  assert.deepEqual(seatCheck(four, { premium: true, productId: "easyplate_duo_monthly" }), { seats: 2, overSeats: true, tier: "duo" });
  assert.deepEqual(seatCheck(four, { premium: true, productId: "easyplate_family_monthly" }), { seats: 6, overSeats: false, tier: "family" });
  assert.deepEqual(seatCheck(four, { premium: true, productId: "easyplate_pro_monthly" }), { seats: 1, overSeats: true });
  assert.equal(seatCheck(four, { premium: false, productId: "easyplate_duo_monthly" }), null, "a lapse is handled by inheritance");
  assert.equal(seatCheck(four, { premium: true, source: "household" }), null);
});

test("a household over its seats takes no one new", async () => {
  const { join } = require("./households").internals;
  const db = {
    collection: () => ({ doc: () => ({ get: async () => ({ exists: true, id: "h1", data: () => ({ ownerUid: "o", seats: 2, overSeats: true, memberUids: ["o"] }) }) }) }),
  };
  assert.deepEqual(await join(db, "h1", "newbie"), { error: "full" });
});

test("dissolving releases the members and deletes the document in one transaction", async () => {
  const { dissolve } = require("./households").internals;
  const ops = [];
  const householdRef = { path: "households/h1" };
  const entRef = (id) => ({ path: `entitlements/${id}` });
  const db = {
    collection: (name) => (name === "households"
      ? { where: () => ({ limit: () => ({ get: async () => ({ empty: false, docs: [{ ref: householdRef, get: (f) => ({ ownerUid: "o" })[f] }] }) }) }) }
      : { doc: entRef }),
    runTransaction: async (fn) => fn({
      get: async () => ({ exists: true, get: (f) => ({ ownerUid: "o", memberUids: ["o", "a", "b"] })[f] }),
      getAll: async (...refs) => refs.map((r) => ({ exists: true, data: () => ({ source: r.path.endsWith("/a") ? "household" : "revenuecat" }) })),
      set: (ref) => ops.push(`release ${ref.path}`),
      delete: (ref) => ops.push(`delete ${ref.path}`),
    }),
    recursiveDelete: async (ref) => ops.push(`tree ${ref.path}`),
  };
  assert.deepEqual(await dissolve(db, "o"), { ok: true });
  assert.deepEqual(ops, ["release entitlements/a", "delete households/h1", "tree households/h1"]);
});

// leave/remove: membership, seats and the entitlement read in the
// transaction that writes them.
function txDb(seed) {
  const ops = [];
  const reads = [];
  const snapOf = (path) => {
    const data = seed[path];
    return { exists: path in seed, id: path.split("/").pop(), ref: { path }, data: () => data, get: (f) => (data || {})[f] };
  };
  const db = {
    collection: (name) => ({
      doc: (id) => ({ path: `${name}/${id}`, get: async () => snapOf(`${name}/${id}`) }),
      where: (field, op, value) => ({
        limit: () => ({
          get: async () => {
            const docs = Object.entries(seed)
              .filter(([path, data]) => path.startsWith(`${name}/`) && Array.isArray(data[field]) && data[field].includes(value))
              .map(([path]) => snapOf(path));
            return { empty: docs.length === 0, docs };
          },
        }),
      }),
    }),
    runTransaction: async (fn) => fn({
      get: async (target) => { reads.push(target.path || "query"); return target.get(); },
      update: (ref, data) => ops.push({ op: "update", path: ref.path, data }),
      set: (ref, data) => ops.push({ op: "set", path: ref.path, data }),
    }),
  };
  return { db, ops, reads };
}

test("leaving reads the roster and the entitlement inside the transaction and clears overSeats there", async () => {
  const { leave } = require("./households").internals;
  const { db, ops, reads } = txDb({
    "households/h1": { ownerUid: "o", seats: 2, overSeats: true, memberUids: ["o", "a", "b"] },
    "entitlements/a": { source: "household", premium: true },
  });
  assert.deepEqual(await leave(db, "a"), { ok: true });
  assert.deepEqual(reads, ["query", "entitlements/a"]);
  assert.equal(ops.length, 2);
  assert.equal(ops[0].path, "households/h1");
  assert.equal(ops[0].data.overSeats, false, "two left on two seats");
  assert.equal(ops[1].path, "entitlements/a");
  assert.equal(ops[1].data.premium, false);

  const owner = txDb({ "households/h1": { ownerUid: "o", memberUids: ["o", "a"] } });
  assert.deepEqual(await leave(owner.db, "o"), { error: "owner_cannot_leave" });
  assert.equal(owner.ops.length, 0);
  assert.deepEqual(await leave(txDb({}).db, "x"), { error: "not_member" });
});

test("removing a member is the owner's, inside one transaction, and keeps overSeats while still over", async () => {
  const { remove } = require("./households").internals;
  const seed = {
    "households/h1": { ownerUid: "o", seats: 2, overSeats: true, memberUids: ["o", "a", "b", "c"] },
    "entitlements/b": { source: "revenuecat", premium: true },
  };
  const { db, ops } = txDb(seed);
  assert.deepEqual(await remove(db, "o", "b"), { ok: true });
  assert.equal(ops.length, 1, "an own subscription is not touched");
  assert.equal("overSeats" in ops[0].data, false, "three on two seats is still over");
  assert.deepEqual(await remove(txDb(seed).db, "a", "b"), { error: "not_owner" });
  assert.deepEqual(await remove(txDb(seed).db, "o", "o"), { error: "owner_cannot_leave" });
  assert.deepEqual(await remove(txDb(seed).db, "o", "zz"), { error: "not_member" });
});

test("the owner's renewal reaches only members still in the household when written", async () => {
  const { syncMembers, syncSeats } = require("./households").internals;
  // The trigger read a roster with "gone" in it; by the time it writes,
  // "gone" has left.
  const stale = { id: "h1", ref: { path: "households/h1", get: async () => ({ exists: true, data: () => ({ ownerUid: "o", tier: "duo", seats: 2, memberUids: ["o", "a"] }), get: (f) => ({ memberUids: ["o", "a"] })[f] }) }, data: () => ({ ownerUid: "o", memberUids: ["o", "a", "gone"] }) };
  const written = [];
  const db = {
    collection: () => ({ doc: (id) => ({ path: `entitlements/${id}`, get: async () => ({ data: () => ({ source: "household" }) }) }) }),
    runTransaction: async (fn) => fn({ get: (ref) => ref.get(), set: (ref) => written.push(ref.path), update: (ref, d) => written.push(`${ref.path} ${JSON.stringify(d.overSeats)}`) }),
  };
  const owner = { premium: true, productId: "easyplate_duo_monthly" };
  assert.equal(await syncMembers(db, stale, owner), 1);
  assert.deepEqual(written, ["entitlements/a"]);
  // Two on two seats, as the household now stands: nothing to correct.
  assert.equal(await syncSeats(db, stale.ref, owner), null);
});

test("a member whose own subscription lapsed gets the household's Premium back; a live own one is kept", () => {
  const { regainedEntitlement } = require("./households").internals;
  const owner = { premium: true, productId: "easyplate_family_monthly", premiumUntil: ts(now + 1000), source: "revenuecat" };
  const lapsed = { premium: true, productId: "easyplate_pro_monthly", premiumUntil: ts(now - 1), source: "revenuecat" };
  const back = regainedEntitlement(owner, lapsed, "h1", now);
  assert.equal(back.premium, true);
  assert.equal(back.source, "household");
  assert.equal(back.householdId, "h1");
  assert.equal(regainedEntitlement(owner, null, "h1", now).premium, true);
  // Their own still live, the owner's lapsed, or the owner's itself inherited: nothing.
  assert.equal(regainedEntitlement(owner, { premium: true, premiumUntil: ts(now + 5), source: "stripe" }, "h1", now), null);
  assert.equal(regainedEntitlement({ ...owner, premiumUntil: ts(now - 1) }, lapsed, "h1", now), null);
  assert.equal(regainedEntitlement({ ...owner, source: "household" }, lapsed, "h1", now), null);
});

test("a member's own plan that ran out with no write gets the household's Premium back in the daily sweep", async () => {
  const { restoreLapsed, LAPSE_WINDOW_MS } = require("./households").internals;
  const now = 1_800_000_000_000;
  const ts = (ms) => ({ toMillis: () => ms });
  const docs = [
    { id: "granted", data: () => ({ premium: true, adminLock: true, premiumUntil: ts(now - 1000) }) },
    { id: "inherited", data: () => ({ premium: true, source: "household", premiumUntil: ts(now - 1000) }) },
  ];
  const seenQuery = [];
  const query = {
    where: (f, op, v) => { seenQuery.push([f, op, v.toMillis()]); return query; },
    orderBy: () => query,
    limit: () => query,
    startAfter: () => query,
    get: async () => ({ size: docs.length, docs }),
  };
  const db = { collection: (name) => { assert.equal(name, "entitlements"); return query; } };
  const asked = [];
  const out = await restoreLapsed(db, { now, restore: async (_db, uid) => { asked.push(uid); return true; } });
  assert.deepEqual(asked, ["granted"]);
  assert.deepEqual(out, { seen: 2, restored: 1 });
  assert.deepEqual(seenQuery, [["premiumUntil", ">", now - LAPSE_WINDOW_MS], ["premiumUntil", "<=", now]]);
});
