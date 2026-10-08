// Self-service account deletion, as the stores require: the signed-in user
// asks, and everything the account holds goes — the Auth user, the profile
// and its mirrored boxes, the inbox, the photos, the shared documents it
// owns, its codes and invites, and what it posted in the community. The
// administrator's `delete` action in adminUsers.js does the core of this;
// here the caller can only ever delete themselves.
const { onRequest } = require("firebase-functions/v2/https");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");
const proxy = require("./aiProxy").internals;
const adminUsers = require("./adminUsers").internals;
const households = require("./households").internals;

// Pure: the request has to say so in as many words. A stray POST from a
// retry or a misrouted client must not take an account down.
function parseRequest(body) {
  if (!body || body.confirm !== true) return { error: "confirm is required" };
  return { confirm: true };
}

async function deleteQuery(db, query, { subtrees = false } = {}) {
  const snap = await query.get();
  if (subtrees) {
    for (const doc of snap.docs) await db.recursiveDelete(doc.ref);
    return snap.size;
  }
  let batch = db.batch();
  let pending = 0;
  for (const doc of snap.docs) {
    batch.delete(doc.ref);
    if (++pending === 400) {
      await batch.commit();
      batch = db.batch();
      pending = 0;
    }
  }
  if (pending) await batch.commit();
  return snap.size;
}

async function deleteStorage(uid) {
  const bucket = admin.storage().bucket();
  const counts = {};
  for (const prefix of [`recipe_images/${uid}/`, `profile_photos/${uid}`]) {
    try {
      const [files] = await bucket.getFiles({ prefix });
      await Promise.all(files.map((f) => f.delete({ ignoreNotFound: true })));
      counts[prefix] = files.length;
    } catch (err) {
      // Photos that cannot be listed are not a reason to keep the account;
      // they carry no name, and the log says they are still there.
      logger.warn("storage cleanup incomplete", { uid, prefix, reason: err.message });
    }
  }
  return counts;
}

// The account's seat in other people's shares: a dead uid left in a roster
// keeps being invited (and its inbox tree recreated) on every save.
async function leaveRosters(db, uid) {
  let left = 0;
  for (const collection of ["collab_recipes", "collab_containers"]) {
    const snap = await db.collection(collection).where("memberUids", "array-contains", uid).get();
    for (const doc of snap.docs) {
      await doc.ref.update({
        [`members.${uid}`]: admin.firestore.FieldValue.delete(),
        memberUids: admin.firestore.FieldValue.arrayRemove(uid),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      left++;
    }
  }
  return left;
}

// Replies in other people's threads: each one taken off its thread's count
// as it goes, so "5 replies" does not keep saying so over 3.
async function deleteReplies(db, uid) {
  const snap = await db.collectionGroup("replies").where("authorUid", "==", uid).get();
  const perThread = new Map();
  let batch = db.batch();
  let pending = 0;
  for (const doc of snap.docs) {
    batch.delete(doc.ref);
    const thread = doc.ref.parent.parent;
    if (thread) perThread.set(thread.path, { ref: thread, count: (perThread.get(thread.path)?.count || 0) + 1 });
    if (++pending === 400) {
      await batch.commit();
      batch = db.batch();
      pending = 0;
    }
  }
  if (pending) await batch.commit();
  for (const { ref, count } of perThread.values()) {
    try {
      await ref.update({ replyCount: admin.firestore.FieldValue.increment(-count) });
    } catch (err) {
      // The thread may be gone (its author deleted it, or is this account).
      if (err.code !== 5) throw err;
    }
  }
  return snap.size;
}

// What leaves with the account, beyond what the admin removal covers.
// Likes stay as counters: a like document is keyed by uid under a post with
// no field to query by, and the counter it moved is anonymous.
async function deleteOwned(db, uid) {
  const out = {};
  out.rostersLeft = await leaveRosters(db, uid);
  out.collabRecipes = await deleteQuery(db, db.collection("collab_recipes").where("ownerUid", "==", uid), { subtrees: true });
  out.collabContainers = await deleteQuery(db, db.collection("collab_containers").where("ownerUid", "==", uid), { subtrees: true });
  await db.doc(`sessions/${uid}`).delete().catch(() => {});
  out.shareCodes = await deleteQuery(db, db.collection("share_codes").where("ownerUid", "==", uid));
  out.invitesSent = await deleteQuery(db, db.collection("share_invites").where("ownerUid", "==", uid));
  out.invitesReceived = await deleteQuery(db, db.collection("share_invites").where("targetUid", "==", uid));
  out.sharedRecipes = await deleteQuery(db, db.collection("shared_recipes").where("authorUid", "==", uid));
  out.forumPosts = await deleteQuery(db, db.collection("forum_posts").where("authorUid", "==", uid), { subtrees: true });
  out.forumReplies = await deleteReplies(db, uid);
  out.feedback = await deleteQuery(db, db.collection("feedback").where("uid", "==", uid));
  return out;
}

async function deleteAccount(db, uid) {
  // A household the account owns is not taken down behind the members'
  // backs: the owner closes it first, from the household screen.
  const owned = await db.collection("households").where("ownerUid", "==", uid).limit(1).get();
  if (!owned.empty) return { error: "household_owner" };
  const membership = await households.leave(db, uid);
  if (membership && membership.error && membership.error !== "not_member") {
    logger.warn("household leave on delete", { uid, reason: membership.error });
  }
  // Firestore and Auth first, the photos last: a failure part-way must
  // leave an account that still works, not one with its pictures gone.
  const owned_ = await deleteOwned(db, uid);
  await adminUsers.remove(uid);
  const storage = await deleteStorage(uid);
  return { ok: true, storage, ...owned_ };
}

exports.deleteAccount = onRequest(
  { region: "europe-west1", cors: false, maxInstances: 3, timeoutSeconds: 300 },
  async (req, res) => {
    if (req.method !== "POST") return res.status(405).json({ error: { message: "Method not allowed" } });
    const caller = await proxy.verifyCaller(req);
    if (!caller) return res.status(401).json({ error: { message: "A valid Firebase ID token is required" } });
    const request = parseRequest(req.body);
    if (request.error) return res.status(400).json({ error: { message: request.error } });
    try {
      const result = await deleteAccount(admin.firestore(), caller.uid);
      if (result.error) {
        logger.info("account deletion refused", { uid: caller.uid, reason: result.error });
        return res.status(409).json({ error: { code: result.error, message: result.error } });
      }
      logger.info("account deleted", { uid: caller.uid, ...result });
      return res.status(200).json({ ok: true });
    } catch (err) {
      logger.error("account deletion failed", { uid: caller.uid, reason: err.message });
      return res.status(500).json({ error: { message: "Deletion failed" } });
    }
  },
);

exports.internals = { parseRequest, deleteQuery, deleteOwned, deleteAccount, leaveRosters, deleteReplies };
