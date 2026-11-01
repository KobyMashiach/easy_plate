const test = require("node:test");
const assert = require("node:assert/strict");

process.env.GCLOUD_PROJECT = process.env.GCLOUD_PROJECT || "easy-plate";
process.env.FIREBASE_CONFIG = process.env.FIREBASE_CONFIG || JSON.stringify({ projectId: "easy-plate" });

const { copyRootOf, saversFor, writeInboxItems, changedFields, WRITE_BATCH, PREFS_BATCH } = require("./index").internals;

// A document reference with just the parent chain copyRootOf walks.
function refAt(path) {
  const parts = path.split("/");
  let node = null;
  for (const part of parts) node = { id: part, parent: node };
  return node;
}

test("a saved copy's root is read from its path, personal or household", () => {
  assert.deepEqual(copyRootOf(refAt("users/u1/recipes/r1")), { collection: "users", id: "u1" });
  assert.deepEqual(copyRootOf(refAt("households/h1/recipes/r2")), { collection: "households", id: "h1" });
  assert.equal(copyRootOf(refAt("whatever/x/recipes/r3")), null);
  assert.equal(copyRootOf(refAt("recipes/r4")), null);
  assert.equal(copyRootOf(null), null);
});

test("household copies are told to every member; the author never hears of their own edit", () => {
  const roots = [
    { collection: "users", id: "alice" },
    { collection: "households", id: "h1" },
    { collection: "users", id: "author" },
    null,
    { collection: "households", id: "gone" },
  ];
  const members = new Map([["h1", ["bob", "carol", "author"]]]);
  assert.deepEqual(saversFor(roots, members, "author").sort(), ["alice", "bob", "carol"]);
  assert.deepEqual(saversFor([{ collection: "households", id: "h1" }], members, "bob").sort(), ["author", "carol"]);
  assert.deepEqual(saversFor([], members, "x"), []);
});

test("inbox items go out in batches Firestore accepts, honouring each account's choices", async () => {
  const commits = [];
  const muted = new Set(["u7", "u300"]);
  const db = {
    doc: (path) => ({ get: async () => {
      const uid = path.split("/")[1];
      return { exists: muted.has(uid), data: () => ({ notifySharedRecipeUpdates: false }) };
    } }),
    collection: () => ({ doc: () => ({ collection: () => ({ doc: () => ({}) }) }) }),
    batch: () => {
      const ops = [];
      return { set: (ref, item) => ops.push(item), commit: async () => commits.push(ops.length) };
    },
  };
  const uids = Array.from({ length: 1000 }, (_, i) => `u${i}`);
  const written = await writeInboxItems(db, uids, (uid) => ({ type: "sharedRecipeUpdated", uid }));
  assert.equal(written, 998, "the two muted accounts get no item");
  assert.deepEqual(commits, [WRITE_BATCH, WRITE_BATCH, 998 - 2 * WRITE_BATCH]);
  assert.ok(commits.every((n) => n <= 500));
  assert.ok(PREFS_BATCH <= 100);
  assert.deepEqual(await writeInboxItems(db, [], () => ({})), 0);
});

test("only edits a saver would notice count as a change", () => {
  const before = { title: "Soup", steps: ["a"], likeCount: 3, updatedAt: 1 };
  assert.deepEqual(changedFields(before, { ...before, likeCount: 4, updatedAt: 2 }), []);
  assert.deepEqual(changedFields(before, { ...before, title: "Stew" }), ["title"]);
});

test("a push body clips what a client wrote into someone else's inbox", () => {
  const { bodyFor } = require("./index").internals;
  const huge = bodyFor({ type: "shareInvite", recipeTitle: "x".repeat(100000), role: "viewer" }, "y".repeat(5000));
  assert.ok(huge.length < 400, `body is ${huge.length} characters`);
  const odd = bodyFor({ type: "shareInvite", recipeTitle: { evil: true }, role: "editor" }, 42);
  assert.ok(!odd.includes("[object Object]"));
  assert.ok(odd.startsWith("מישהו"));
});

test("invite pushes stop at the sender's allowance and the pair's, and fail open", async () => {
  const { invitePushAllowed } = require("./index").internals;
  const seen = [];
  const spendWith = (refuse) => async ({ uid, kind }) => {
    seen.push(`${kind}:${uid}`);
    return { allowed: kind !== refuse };
  };
  assert.equal(await invitePushAllowed("s", "t", spendWith(null)), true);
  assert.deepEqual(seen, ["invitePush:s", "invitePushPair:s_t"]);
  assert.equal(await invitePushAllowed("s", "t", spendWith("invitePush")), false);
  assert.equal(await invitePushAllowed("s", "t", spendWith("invitePushPair")), false);
  assert.equal(await invitePushAllowed("s", "t", async () => { throw new Error("down"); }), true);
});

test("a replier's daily reply notifications stop at the allowance, and fail open", async () => {
  const { replyFanoutAllowed } = require("./index").internals;
  const { KINDS } = require("./dailyBudget");
  assert.equal(KINDS.forumReplyFanout.param, "quota_forum_reply_fanout_daily");
  const template = require("../remoteconfig.template.json");
  assert.equal(template.parameters.quota_forum_reply_fanout_daily.defaultValue.value, String(KINDS.forumReplyFanout.fallback));
  const seen = [];
  assert.equal(await replyFanoutAllowed("u1", async ({ uid, kind }) => { seen.push(`${kind}:${uid}`); return { allowed: true }; }), true);
  assert.deepEqual(seen, ["forumReplyFanout:u1"]);
  assert.equal(await replyFanoutAllowed("u1", async () => ({ allowed: false })), false);
  assert.equal(await replyFanoutAllowed("u1", async () => { throw new Error("down"); }), true);
  assert.equal(await replyFanoutAllowed("", async () => ({ allowed: true })), false);
});

test("recipe-update fan-out spends the author's own daily budget", async () => {
  const { recipeUpdateFanoutAllowed } = require("./index").internals;
  const seen = [];
  assert.equal(await recipeUpdateFanoutAllowed("a1", async ({ uid, kind }) => { seen.push(`${kind}:${uid}`); return { allowed: true }; }), true);
  assert.deepEqual(seen, ["recipeUpdateFanout:a1"]);
  assert.equal(await recipeUpdateFanoutAllowed("a1", async () => ({ allowed: false })), false);
  assert.equal(await recipeUpdateFanoutAllowed("", async () => ({ allowed: true })), false);
  assert.equal(await recipeUpdateFanoutAllowed("a1", async () => { throw new Error("down"); }), true);
});

test("a thread's reply counter is set back to the replies that exist, and left alone when it already matches", async () => {
  const { reconcileReplyCount } = require("./index").internals;
  const updates = [];
  const ref = (count) => ({
    id: "p1",
    collection: (name) => ({ count: () => ({ get: async () => { assert.equal(name, "replies"); return { data: () => ({ count }) }; } }) }),
    update: async (data) => updates.push(data),
  });
  assert.equal(await reconcileReplyCount(ref(3), 9000), 3);
  assert.deepEqual(updates, [{ replyCount: 3 }]);
  assert.equal(await reconcileReplyCount(ref(3), 3), 3);
  assert.equal(updates.length, 1, "no write when it already matches");
  const broken = { id: "p1", collection: () => ({ count: () => ({ get: async () => { throw new Error("unavailable"); } }) }) };
  assert.equal(await reconcileReplyCount(broken, 1), null, "best effort");
});

test("an invite rings the recipient's phone only when its sender has a verified phone", async () => {
  const { senderHasPhone } = require("./index").internals;
  assert.equal(await senderHasPhone("u1", async () => ({ uid: "u1", phoneNumber: "+972501234567" })), true);
  assert.equal(await senderHasPhone("u1", async () => ({ uid: "u1", email: "x@example.com" })), false, "a minted email/password account");
  assert.equal(await senderHasPhone("u1", async () => ({ uid: "u1", phoneNumber: "" })), false);
  assert.equal(await senderHasPhone("ghost", async () => { throw Object.assign(new Error("no user"), { code: "auth/user-not-found" }); }), false);
  assert.equal(await senderHasPhone("u1", async () => { throw Object.assign(new Error("quota"), { code: "auth/internal-error" }); }), true, "Auth unreadable: let the push through");
  assert.equal(await senderHasPhone("", async () => ({ phoneNumber: "+1" })), false);
});

test("a reply tells the thread only from an account with a phone (or a console persona), within its allowance", async () => {
  const { replierMayTell } = require("./index").internals;
  const spent = [];
  const spend = async (uid) => { spent.push(uid); return true; };
  assert.equal(await replierMayTell("real", { hasPhone: async () => true, spend }), true);
  assert.equal(await replierMayTell("throwaway", { hasPhone: async () => false, spend }), false);
  assert.deepEqual(spent, ["real"], "a phone-less replier does not even spend the allowance");
  assert.equal(await replierMayTell("seed_dana", { hasPhone: async () => assert.fail("personas have no Auth record"), spend }), true);
  assert.equal(await replierMayTell("real", { hasPhone: async () => true, spend: async () => false }), false, "allowance spent");
});

test("a thread's reply counter is rechecked whenever it rises, and only then", () => {
  const { replyCountRose } = require("./index").internals;
  assert.equal(replyCountRose({ replyCount: 3 }, { replyCount: 4 }), true, "a bare +1 (or a real reply)");
  assert.equal(replyCountRose({}, { replyCount: 1 }), true, "a thread from before the counter");
  assert.equal(replyCountRose({ replyCount: 9000 }, { replyCount: 3 }), false, "the reconcile's own write down");
  assert.equal(replyCountRose({ replyCount: 3, likeCount: 1 }, { replyCount: 3, likeCount: 2 }), false, "a like");
  assert.equal(replyCountRose({ replyCount: 3 }, { replyCount: "999" }), false, "not a number");
  assert.equal(replyCountRose(undefined, undefined), false);
});

test("a like counter is put back to the likes that exist after a like is removed (the author's sweep-and-relike loop)", async () => {
  const { reconcileLikeCount } = require("./index").internals;
  // Documents by path; `likes` lists the like ids under each liked path.
  const fakeDb = (docs, likes, { failCount = false } = {}) => {
    const updates = [];
    const ref = (path) => ({
      path,
      collection: (name) => ({ count: () => ({ kind: "count", path: `${path}/${name}` }) }),
    });
    const tx = {
      get: async (target) => {
        if (target.kind === "count") {
          if (failCount) throw new Error("unavailable");
          return { data: () => ({ count: (likes[target.path.replace(/\/likes$/, "")] || []).length }) };
        }
        const data = docs[target.path];
        return { exists: data !== undefined, get: (f) => (data || {})[f] };
      },
      update: (target, data) => updates.push({ path: target.path, ...data }),
    };
    return { updates, doc: ref, runTransaction: async (fn) => fn(tx) };
  };
  // The author liked their own post three times over, sweeping the like
  // in between: the counter says 3, one like (or none) is there.
  let db = fakeDb({ "shared_recipes/p1": { likeCount: 3 } }, { "shared_recipes/p1": [] });
  assert.equal(await reconcileLikeCount(db, "shared_recipes/p1"), 0);
  assert.deepEqual(db.updates, [{ path: "shared_recipes/p1", likeCount: 0 }]);
  db = fakeDb({ "forum_posts/t1/replies/r1": { likeCount: 9 } }, { "forum_posts/t1/replies/r1": ["bob"] });
  assert.equal(await reconcileLikeCount(db, "forum_posts/t1/replies/r1"), 1);
  assert.deepEqual(db.updates, [{ path: "forum_posts/t1/replies/r1", likeCount: 1 }]);
  // Already right: no write. A thread from before likes (no field) with none: no write.
  db = fakeDb({ "forum_posts/t1": { likeCount: 2 }, "forum_posts/t2": {} }, { "forum_posts/t1": ["a", "b"] });
  assert.equal(await reconcileLikeCount(db, "forum_posts/t1"), 2);
  assert.equal(await reconcileLikeCount(db, "forum_posts/t2"), 0);
  assert.equal(db.updates.length, 0);
  // The post is gone (the sweep's last batch): nothing recreated.
  db = fakeDb({}, {});
  assert.equal(await reconcileLikeCount(db, "shared_recipes/gone"), null);
  assert.equal(db.updates.length, 0);
  // A failing count is logged, not thrown, and writes nothing.
  db = fakeDb({ "shared_recipes/p1": { likeCount: 3 } }, {}, { failCount: true });
  assert.equal(await reconcileLikeCount(db, "shared_recipes/p1"), null);
  assert.equal(db.updates.length, 0);
});

// A tiny Firestore stand-in for the two fan-out triggers.
function fanoutDb({ copies = [], post = null, replies = [], households = {} } = {}) {
  const log = { scans: [] };
  const snap = (docs) => ({ empty: docs.length === 0, size: docs.length, docs });
  const query = (name, docs) => {
    const q = {
      where: () => q, select: () => q, orderBy: () => q,
      limit: (n) => {
        const page = { get: async () => { log.scans.push({ name, limit: n }); return snap(docs.slice(0, n)); } };
        page.select = () => page;
        return page;
      },
    };
    return q;
  };
  const db = {
    log,
    collectionGroup: () => query("copies", copies.map((path) => ({ ref: refAt(path) }))),
    getAll: async (...refs) => refs.map((r) => ({ id: r.id, exists: !!households[r.id], get: () => households[r.id] })),
    doc: (path) => {
      if (path.startsWith("households/")) return { id: path.split("/")[1] };
      return {
        id: path.split("/")[1],
        get: async () => ({ exists: !!post, get: (f) => (post || {})[f] }),
        collection: () => query("replies", replies.map((uid) => ({ get: () => uid }))),
      };
    },
  };
  return db;
}

test("a recipe edit spends the author's allowance before scanning saved copies, and scans a bounded page", async () => {
  const { tellSaversOfEdit, COPY_SCAN_LIMIT } = require("./index").internals;
  const before = { title: "a" };
  const after = { title: "b", authorUid: "author" };
  // Over budget: only the one-row probe ran, no full scan, nobody told.
  let db = fanoutDb({ copies: ["users/u1/recipes/r", "users/u2/recipes/r"] });
  let r = await tellSaversOfEdit(db, { sharedId: "s", before, after }, { allowed: async () => false, write: async () => assert.fail("no writes") });
  assert.equal(r.reason, "budget");
  assert.deepEqual(db.log.scans, [{ name: "copies", limit: 1 }]);
  // Nobody saved it: nothing spent.
  db = fanoutDb();
  let spent = 0;
  r = await tellSaversOfEdit(db, { sharedId: "s", before, after }, { allowed: async () => { spent++; return true; } });
  assert.equal(r.reason, "no_copies");
  assert.equal(spent, 0);
  // Allowed: the scan is limited.
  db = fanoutDb({ copies: ["users/u1/recipes/r", "users/author/recipes/r"] });
  let told = null;
  r = await tellSaversOfEdit(db, { sharedId: "s", before, after }, { allowed: async () => true, write: async (_db, uids) => { told = uids; } });
  assert.deepEqual(told, ["u1"]);
  assert.deepEqual(db.log.scans[1], { name: "copies", limit: COPY_SCAN_LIMIT });
});

test("a forum reply spends the replier's allowance before scanning earlier replies", async () => {
  const { tellThreadOfReply } = require("./index").internals;
  const reconcile = async () => 3;
  let db = fanoutDb({ post: { authorUid: "op" }, replies: ["x", "y"] });
  let r = await tellThreadOfReply(db, { postId: "p", replyId: "r", reply: { authorUid: "me", body: "hi" } }, { allowed: async () => false, reconcile, write: async () => assert.fail("no writes") });
  assert.equal(r.reason, "budget");
  assert.deepEqual(db.log.scans, []);
  db = fanoutDb({ post: { authorUid: "op" }, replies: ["x", "me", "op"] });
  let told = null;
  r = await tellThreadOfReply(db, { postId: "p", replyId: "r", reply: { authorUid: "me", body: "hi" } }, { allowed: async () => true, reconcile, write: async (_db, uids) => { told = uids; return uids.length; } });
  assert.deepEqual(told.sort(), ["op", "x"]);
  // My own thread, my first reply: nobody to tell, nothing spent.
  db = fanoutDb({ post: { authorUid: "me" }, replies: ["me"] });
  let spent = 0;
  r = await tellThreadOfReply(db, { postId: "p", replyId: "r", reply: { authorUid: "me" } }, { allowed: async () => { spent++; return true; }, reconcile: async () => 1 });
  assert.equal(r.reason, "nobody");
  assert.equal(spent, 0);
});

test("a new support conversation takes one of the author's daily slots; past them it is closed and marked", async () => {
  const { admitFeedback } = require("./index").internals;
  const { KINDS } = require("./dailyBudget");
  const template = require("../remoteconfig.template.json");
  assert.equal(KINDS.feedback.param, "quota_feedback_daily");
  assert.equal(KINDS.feedback.fallback, 5);
  assert.equal(template.parameters.quota_feedback_daily.defaultValue.value, String(KINDS.feedback.fallback));
  assert.equal(template.parameters.quota_feedback_daily.valueType, "NUMBER");

  const refWith = (onUpdate) => ({ id: "f1", update: async (patch) => onUpdate(patch) });
  const seen = [];
  let written = null;
  assert.equal(await admitFeedback(refWith((p) => { written = p; }), { authorUid: "u1" }, async ({ uid, kind }) => { seen.push(`${kind}:${uid}`); return { allowed: true }; }), true);
  assert.deepEqual(seen, ["feedback:u1"]);
  assert.deepEqual(written, { admitted: true });

  written = null;
  assert.equal(await admitFeedback(refWith((p) => { written = p; }), { authorUid: "u1" }, async () => ({ allowed: false })), false);
  assert.equal(written.rejected, "daily_limit");
  // Closed and read: out of the open inbox and the unread badge on every
  // console, locked for follow-ups in older builds.
  assert.equal(written.status, "closed");
  assert.equal(written.read, true);
  assert.ok("closedAt" in written && "readAt" in written);
  assert.ok(!("admitted" in written));

  // An unreadable budget lets support through; a vanished document is not an error.
  written = null;
  assert.equal(await admitFeedback(refWith((p) => { written = p; }), { authorUid: "u1" }, async () => { throw new Error("down"); }), true);
  assert.deepEqual(written, { admitted: true });
  assert.equal(await admitFeedback(refWith(() => { throw new Error("NOT_FOUND"); }), { authorUid: "u1" }, async () => ({ allowed: false })), false);

  // No author, nothing spent or written.
  assert.equal(await admitFeedback(refWith(() => assert.fail("no write")), {}, async () => assert.fail("no spend")), null);
  assert.equal(await admitFeedback(refWith(() => assert.fail("no write")), null, async () => assert.fail("no spend")), null);
});
