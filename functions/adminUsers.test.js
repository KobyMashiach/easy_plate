const test = require("node:test");
const assert = require("node:assert/strict");

process.env.GCLOUD_PROJECT = process.env.GCLOUD_PROJECT || "easy-plate";
process.env.FIREBASE_CONFIG =
  process.env.FIREBASE_CONFIG || JSON.stringify({ projectId: "easy-plate" });

const { parseRequest } = require("./adminUsers").internals;
const { permissionOf, isAdmin, PERMISSIONS } = require("./permissions");

test("only permission \"admin\" on the users document makes an administrator", async () => {
  assert.equal(permissionOf({ permission: "admin" }), PERMISSIONS.ADMIN);
  assert.equal(permissionOf({ permission: "user" }), PERMISSIONS.USER);
  assert.equal(permissionOf({ permission: "Admin" }), PERMISSIONS.USER);
  assert.equal(permissionOf({ email: "koby9779@gmail.com" }), PERMISSIONS.USER);
  assert.equal(permissionOf(null), PERMISSIONS.USER);
  assert.equal(await isAdmin(null), false);
  assert.equal(await isAdmin({ email: "koby9779@gmail.com" }), false);
});

test("disable carries the block message", () => {
  const r = parseRequest({ action: "disable", uid: "u1", message: "  spam  " });
  assert.deepEqual(r, { action: "disable", uid: "u1", message: "spam" });
});

test("account actions need a uid", () => {
  assert.equal(parseRequest({ action: "delete" }).error, "uid is required");
  assert.equal(parseRequest({ action: "enable", uid: "" }).error, "uid is required");
});

test("a push needs a body, and the title is optional", () => {
  assert.equal(parseRequest({ action: "notify", uid: "u1" }).error, "body is required");
  const r = parseRequest({ action: "notify", uid: "u1", body: "hi" });
  assert.deepEqual(r, { action: "notify", uid: "u1", title: "", message: "hi" });
});

test("a broadcast takes no uid", () => {
  const r = parseRequest({ action: "notifyAll", title: "News", body: "Version 2 is out" });
  assert.deepEqual(r, { action: "notifyAll", title: "News", message: "Version 2 is out" });
});

test("long texts are cut, unknown actions refused", () => {
  const r = parseRequest({ action: "notifyAll", body: "x".repeat(5000) });
  assert.equal(r.message.length, 1000);
  assert.equal(parseRequest({ action: "shutdown" }).error, "unknown action");
  assert.equal(parseRequest(null).error, "unknown action");
});

test("a price sync takes nothing", () => {
  assert.deepEqual(parseRequest({ action: "syncPricing" }), { action: "syncPricing" });
});

test("a broadcast reaches exactly its audience", () => {
  const { inAudience } = require("./adminUsers").internals;
  const picked = new Set(["a", "b"]);
  assert.equal(inAudience({ audience: "all", uid: "x" }), true);
  assert.equal(inAudience({ audience: "premium", uid: "x", premium: true }), true);
  assert.equal(inAudience({ audience: "premium", uid: "x", premium: false }), false);
  assert.equal(inAudience({ audience: "free", uid: "x", premium: false }), true);
  assert.equal(inAudience({ audience: "free", uid: "x", premium: true }), false);
  assert.equal(inAudience({ audience: "users", uid: "a", uidSet: picked }), true);
  assert.equal(inAudience({ audience: "users", uid: "c", uidSet: picked }), false);
});

test("setPermission takes user, superuser or admin", () => {
  assert.deepEqual(parseRequest({ action: "setPermission", uid: "u1", permission: "superuser" }), { action: "setPermission", uid: "u1", permission: "superuser" });
  assert.deepEqual(parseRequest({ action: "setPermission", uid: "u1", permission: "admin" }), { action: "setPermission", uid: "u1", permission: "admin" });
  assert.equal(parseRequest({ action: "setPermission", uid: "u1", permission: "boss" }).error, "permission must be user, superuser or admin");
  assert.equal(parseRequest({ action: "setPermission", permission: "user" }).error, "uid is required");
});

test("a superuser is read as such and is exempt like the administrator", () => {
  const { permissionOf, hasAllFeatures } = require("./permissions");
  assert.equal(permissionOf({ permission: "superuser" }), "superuser");
  assert.equal(permissionOf({ permission: "boss" }), "user");
  assert.ok(hasAllFeatures("superuser"));
  assert.ok(hasAllFeatures("admin"));
  assert.ok(!hasAllFeatures("user"));
});

// A users collection walked in id order, an inbox that records writes, and
// a messaging stub: enough of Firestore for a paged broadcast.
function broadcastDb(count) {
  const ids = Array.from({ length: count }, (_, i) => `u${String(i).padStart(4, "0")}`);
  const written = [];
  const usersQuery = (after = null, limit = Infinity) => ({
    orderBy: () => usersQuery(after, limit),
    select: () => usersQuery(after, limit),
    limit: (n) => usersQuery(after, n),
    startAfter: (c) => usersQuery(c, limit),
    get: async () => {
      const docs = ids.filter((id) => after === null || id > after).slice(0, limit)
        .map((id) => ({ id, get: (f) => (f === "pushToken" ? `tok_${id}` : undefined) }));
      return { docs, empty: docs.length === 0, size: docs.length };
    },
  });
  let auto = 0;
  return {
    written,
    collection: (name) => (name === "users" ? usersQuery() : {
      doc: (uid) => ({
        collection: () => ({ doc: (id) => ({ path: `${name}/${uid}/items/${id || `auto${auto++}`}` }) }),
      }),
    }),
    doc: () => ({ get: async () => ({ exists: false }) }),
    batch: () => {
      const pending = [];
      return { set: (ref) => pending.push(ref.path), commit: async () => { written.push(...pending); } };
    },
  };
}

test("a broadcast walks the accounts in pages, stops at its deadline and resumes from the cursor", async () => {
  const { notifyAll, BROADCAST_PAGE } = require("./adminUsers").internals;
  const db = broadcastDb(BROADCAST_PAGE * 2 + 100);
  const pushed = [];
  const messaging = { sendEachForMulticast: async ({ tokens }) => { pushed.push(...tokens); return { successCount: tokens.length, failureCount: 0 }; } };
  const progress = [];
  const base = { fromUid: "admin", title: "T", message: "M", db, messaging, pushFlag: 2, runKey: "tpl_a_1", onProgress: async (p) => progress.push(p) };

  const first = await notifyAll({ ...base, deadline: 0 });
  assert.equal(first.done, false);
  assert.equal(first.items, BROADCAST_PAGE);
  assert.equal(first.cursor, `u${String(BROADCAST_PAGE - 1).padStart(4, "0")}`);

  const rest = await notifyAll({ ...base, resume: first });
  assert.equal(rest.done, true);
  assert.equal(rest.items, BROADCAST_PAGE * 2 + 100);
  assert.equal(rest.sent, BROADCAST_PAGE * 2 + 100);
  assert.equal(new Set(pushed).size, pushed.length, "nobody is pushed twice");
  assert.equal(progress.length, 3);
  // A fixed id per run: a page written again lands on the same item.
  assert.ok(db.written.every((p) => p.endsWith("/items/broadcast_tpl_a_1")));
});

test("broadcast item ids never carry a slash", () => {
  const { broadcastItemId } = require("./adminUsers").internals;
  assert.equal(broadcastItemId("tpl_a/b_1"), "broadcast_tpl_a_b_1");
});

test("admin ids must be one document segment", () => {
  assert.equal(parseRequest({ action: "delete", uid: "a/b" }).error, "uid is not a valid id");
  assert.equal(parseRequest({ action: "delete", uid: ".." }).error, "uid is not a valid id");
  assert.equal(parseRequest({ action: "delete", uid: "__x__" }).error, "uid is not a valid id");
  assert.equal(parseRequest({ action: "delete", uid: "abc" }).uid, "abc");
});

test("the administrator's delete settles Stripe first; a Stripe failure removes nothing", async () => {
  const { remove } = require("./adminUsers").internals;
  const stripeClient = require("./stripeClient");
  const originalRequest = stripeClient.request;
  const touched = [];
  const db = {
    collection: (name) => ({
      doc: (id) => ({
        get: async () => ({ exists: name === "stripe_customers", data: () => ({ stripeCustomerId: "cus_1", subscriptionId: "sub_1", subscriptionStatus: "active" }) }),
        delete: async () => touched.push(`delete ${name}/${id}`),
      }),
      where: () => ({
        get: async () => { touched.push(`query ${name}`); return { docs: [] }; },
        limit: () => ({ get: async () => ({ empty: true, docs: [] }) }),
      }),
    }),
    batch: () => ({ delete: () => {}, commit: async () => touched.push("batch") }),
    doc: (p) => p,
    recursiveDelete: async (p) => touched.push(`tree ${p}`),
  };
  stripeClient.request = async () => { throw new stripeClient.StripeError(500, { error: { message: "down" } }); };
  try {
    await assert.rejects(remove("u1", { stripeSecret: "sk_test", db }), (err) => err instanceof stripeClient.StripeError);
    assert.deepEqual(touched, [], "nothing of the account was removed");
  } finally {
    stripeClient.request = originalRequest;
  }
});

test("the administrator's delete refuses a household owner before anything, and takes a member out of the household", async () => {
  const { remove } = require("./adminUsers").internals;
  const touched = [];
  const ownerDb = {
    collection: (name) => ({
      where: (field) => ({ limit: () => ({ get: async () => ({ empty: !(name === "households" && field === "ownerUid"), docs: [{}] }) }) }),
      doc: () => ({ get: async () => { touched.push("read"); return { exists: false }; } }),
    }),
  };
  assert.deepEqual(await remove("owner", { stripeSecret: "-", db: ownerDb }), { error: "household_owner" });
  assert.deepEqual(touched, [], "Stripe and the account untouched");

  // A member: Stripe settled, then the household left in a transaction,
  // then the rest of the removal.
  const order = [];
  const memberDb = {
    collection: (name) => ({
      doc: (id) => ({ path: `${name}/${id}`, get: async () => ({ exists: false, data: () => undefined }), delete: async () => order.push(`delete ${name}/${id}`) }),
      where: (field) => ({
        get: async () => ({ docs: [] }),
        limit: () => ({
          get: async () => (name === "households" && field === "memberUids"
            ? { empty: false, docs: [{ ref: { path: "households/h1" }, data: () => ({ ownerUid: "o", seats: 2, memberUids: ["o", "m"] }) }] }
            : { empty: true, docs: [] }),
          select: () => ({ get: async () => { order.push(`page ${name}`); return { empty: true, size: 0, docs: [] }; } }),
        }),
      }),
      select: () => ({ get: async () => { order.push(`days ${name}`); return { docs: [] }; } }),
    }),
    runTransaction: async (fn) => fn({
      get: async (target) => target.get(),
      update: (ref) => order.push(`leave ${ref.path}`),
      set: () => {},
    }),
    batch: () => ({ delete: () => {}, commit: async () => order.push("batch") }),
    doc: (p) => p,
    recursiveDelete: async (p) => order.push(`tree ${p}`),
  };
  // The Auth step needs a Firebase app; everything before it is the point.
  await assert.rejects(remove("m", { stripeSecret: "-", db: memberDb }), (err) => err.code === "app/no-app");
  assert.deepEqual(order, ["leave households/h1", "batch", "page ai_interactions", "page ai_calls", "days ai_daily", "tree users/m", "tree notifications/m"]);
});

test("a direct broadcast is refused above the cap, pointing at a template's send now", async () => {
  const { directSendRefusal, DIRECT_SEND_MAX } = require("./adminUsers").internals;
  const dbWith = (count) => ({ collection: (name) => ({ count: () => ({ get: async () => { assert.equal(name, "users"); return { data: () => ({ count }) }; } }) }) });
  assert.equal(await directSendRefusal(dbWith(DIRECT_SEND_MAX)), null);
  const refusal = await directSendRefusal(dbWith(DIRECT_SEND_MAX + 1));
  assert.equal(refusal.error, "too_many_recipients");
  assert.match(refusal.message, /template/);
});

test("an administrator the console switched off is no administrator", async () => {
  const docs = {
    "users/a1": { permission: "admin" },
    "users/a2": { permission: "admin" },
    "account_status/a2": { disabled: true },
    "users/a3": { permission: "admin" },
    "account_status/a3": { disabled: false },
    "users/u1": { permission: "user" },
  };
  const db = { doc: (p) => ({ get: async () => ({ exists: p in docs, data: () => docs[p] }) }) };
  assert.equal(await isAdmin({ uid: "a1" }, db), true);
  assert.equal(await isAdmin({ uid: "a2" }, db), false);
  assert.equal(await isAdmin({ uid: "a3" }, db), true);
  assert.equal(await isAdmin({ uid: "u1" }, db), false);
});

test("an account's conversation-owner rows are deleted page by page until none is left", async () => {
  const { deleteInteractionOwners } = require("./adminUsers").internals;
  let left = 9;
  const asked = [];
  const db = {
    collection: (name) => ({
      where: (field, op, value) => {
        asked.push([name, field, op, value]);
        return { limit: (n) => ({ select: () => ({ get: async () => {
          const size = Math.min(n, left);
          return { empty: size === 0, size, docs: Array.from({ length: size }, () => ({ ref: {} })) };
        } }) }) };
      },
    }),
    batch: () => {
      let n = 0;
      return { delete: () => n++, commit: async () => { left -= n; } };
    },
  };
  assert.equal(await deleteInteractionOwners(db, "u1", 4), 9);
  assert.equal(left, 0);
  assert.deepEqual(asked[0], ["ai_interactions", "uid", "==", "u1"]);
  assert.equal(asked.length, 3, "4 + 4 + 1, and a short page ends it");
});

test("switching an account off puts `disabled` in its token claims, and back on takes it out, keeping other claims", async () => {
  const { claimsWithDisabled, setDisabledClaim } = require("./adminUsers").internals;
  assert.deepEqual(claimsWithDisabled(null, true), { disabled: true });
  assert.deepEqual(claimsWithDisabled({ x: 1, disabled: true }, false), { x: 1 });
  let written = null;
  const auth = { getUser: async () => ({ customClaims: { tier: "a" } }), setCustomUserClaims: async (uid, c) => { written = [uid, c]; } };
  await setDisabledClaim("u1", true, auth);
  assert.deepEqual(written, ["u1", { tier: "a", disabled: true }]);
  // A failure is logged, never thrown: the status document already stands.
  await setDisabledClaim("u1", true, { getUser: async () => { throw new Error("down"); } });
});
