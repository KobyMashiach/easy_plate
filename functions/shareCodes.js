// Share codes: a recipe, book or meal plan (and, later, a household) can be
// shared with a short code instead of a contact. The owner writes the code
// document from the app; redeeming it is done here, as the server, because
// the invite it creates belongs to the owner and the rules let only the
// owner write invites.
const { onRequest } = require("firebase-functions/v2/https");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");
const proxy = require("./aiProxy").internals;
const households = require("./households").internals;

const CODE_RE = /^[A-Z2-9]{8}$/;
const KINDS = new Set(["recipe", "book", "mealPlan", "household"]);

// Normalises "ep-7k3m 9qx2" → "7K3M9QX2".
function normalizeCode(raw) {
  if (typeof raw !== "string") return null;
  const code = raw.toUpperCase().replace(/[^A-Z0-9]/g, "").replace(/^EP/, "");
  return CODE_RE.test(code) ? code : null;
}

// Pure: why a code may not be redeemed by this caller, or null when it may.
function rejectReason(doc, uid, nowMs = Date.now()) {
  if (!doc) return "not_found";
  if (doc.revoked === true) return "revoked";
  if (!KINDS.has(doc.kind)) return "not_found";
  const expires = doc.expiresAt && typeof doc.expiresAt.toMillis === "function" ? doc.expiresAt.toMillis() : null;
  if (expires !== null && expires <= nowMs) return "expired";
  if (typeof doc.maxUses === "number" && (doc.uses || 0) >= doc.maxUses) return "used_up";
  if (doc.ownerUid === uid) return "self";
  return null;
}

function inviteId(collabId, uid) {
  return `${collabId}_${uid}`;
}

function inviteFields({ collabId, title, ownerUid, targetUid, role, kind, via }) {
  return {
    collabId,
    recipeTitle: title,
    ownerUid,
    targetUid,
    role,
    status: "pending",
    kind,
    ...(via ? { via } : {}),
    createdAt: admin.firestore.Timestamp.now(),
  };
}

function notificationFields({ collabId, title, ownerUid, targetUid, role, kind }) {
  return {
    type: "shareInvite",
    kind,
    fromUid: ownerUid,
    inviteId: inviteId(collabId, targetUid),
    collabId,
    recipeTitle: title,
    role,
    read: false,
    createdAt: admin.firestore.Timestamp.now(),
  };
}

// Recipe collab ids a container's content refers to (books: recipes[].collabId,
// plans: meals[].items[].recipeCollabId), as the app's CollabContainerEntity.
function recipeCollabIdsIn(content) {
  const ids = new Set();
  for (const r of (content && content.recipes) || []) {
    if (r && typeof r.collabId === "string") ids.add(r.collabId);
  }
  for (const meal of (content && content.meals) || []) {
    for (const item of (meal && meal.items) || []) {
      if (item && typeof item.recipeCollabId === "string") ids.add(item.recipeCollabId);
    }
  }
  return [...ids];
}

async function redeem(db, code, uid) {
  const ref = db.collection("share_codes").doc(code);
  const snap = await ref.get();
  const doc = snap.exists ? snap.data() : null;
  const reason = rejectReason(doc, uid);
  if (reason) return { error: reason };

  const role = doc.role === "editor" ? "editor" : "viewer";
  const batch = db.batch();
  let invite;

  if (doc.kind === "recipe") {
    const collab = await db.collection("collab_recipes").doc(doc.targetId).get();
    if (!collab.exists) return { error: "gone" };
    if ((collab.get("memberUids") || []).includes(uid)) return { already: true };
    const existing = await db.collection("share_invites").doc(inviteId(doc.targetId, uid)).get();
    if (existing.exists && existing.get("status") === "accepted") return { already: true };
    const fields = { collabId: doc.targetId, title: doc.title || collab.get("title") || "", ownerUid: doc.ownerUid, targetUid: uid, role, kind: "recipe" };
    batch.set(db.collection("share_invites").doc(inviteId(doc.targetId, uid)), inviteFields(fields));
    batch.set(db.collection("notifications").doc(uid).collection("items").doc(inviteId(doc.targetId, uid)), notificationFields(fields));
    invite = { id: inviteId(doc.targetId, uid), ...fields };
  } else if (doc.kind === "book" || doc.kind === "mealPlan") {
    const container = await db.collection("collab_containers").doc(doc.targetId).get();
    if (!container.exists) return { error: "gone" };
    if ((container.get("memberUids") || []).includes(uid)) return { already: true };
    const existing = await db.collection("share_invites").doc(inviteId(doc.targetId, uid)).get();
    if (existing.exists && existing.get("status") === "accepted") return { already: true };
    const fields = { collabId: doc.targetId, title: doc.title || container.get("title") || "", ownerUid: doc.ownerUid, targetUid: uid, role, kind: doc.kind };
    batch.set(db.collection("share_invites").doc(inviteId(doc.targetId, uid)), inviteFields(fields));
    batch.set(db.collection("notifications").doc(uid).collection("items").doc(inviteId(doc.targetId, uid)), notificationFields(fields));
    // The recipes inside travel with the container: a silent invite for each
    // one the owner owns and the member does not have yet.
    const recipeIds = recipeCollabIdsIn(container.get("content"));
    for (const recipeId of recipeIds) {
      const [recipe, recipeInvite] = await Promise.all([
        db.collection("collab_recipes").doc(recipeId).get(),
        db.collection("share_invites").doc(inviteId(recipeId, uid)).get(),
      ]);
      if (!recipe.exists || recipe.get("ownerUid") !== doc.ownerUid) continue;
      if (recipeInvite.exists) continue;
      if ((recipe.get("memberUids") || []).includes(uid)) continue;
      batch.set(
        db.collection("share_invites").doc(inviteId(recipeId, uid)),
        inviteFields({ collabId: recipeId, title: recipe.get("title") || "", ownerUid: doc.ownerUid, targetUid: uid, role, kind: "recipe", via: doc.targetId }),
      );
    }
    invite = { id: inviteId(doc.targetId, uid), ...fields };
  } else if (doc.kind === "household") {
    // Membership is written directly: there is no invite to accept, the
    // app's household listener sees the new document.
    const joined = await households.join(db, doc.targetId, uid);
    if (joined.error) return joined;
    if (joined.already) return { already: true, household: joined.household };
    await ref.update({ uses: admin.firestore.FieldValue.increment(1), lastUsedAt: admin.firestore.FieldValue.serverTimestamp() });
    return { household: joined.household };
  } else {
    return { error: "unsupported" };
  }

  batch.update(ref, { uses: admin.firestore.FieldValue.increment(1), lastUsedAt: admin.firestore.FieldValue.serverTimestamp() });
  await batch.commit();
  return { invite };
}

exports.internals = { normalizeCode, rejectReason, recipeCollabIdsIn, inviteFields, notificationFields, redeem };

exports.shareCodes = onRequest(
  { region: "europe-west1", cors: false, maxInstances: 5 },
  async (req, res) => {
    if (req.method !== "POST") return res.status(405).json({ error: { message: "Method not allowed" } });
    const caller = await proxy.verifyCaller(req);
    if (!caller) return res.status(401).json({ error: { message: "A valid Firebase ID token is required" } });
    const action = req.body && req.body.action;
    if (action !== "redeem") return res.status(400).json({ error: { message: "Unknown action" } });
    const code = normalizeCode(req.body && req.body.code);
    if (!code) return res.status(400).json({ error: { code: "invalid", message: "Invalid code" } });
    try {
      const result = await redeem(admin.firestore(), code, caller.uid);
      if (result.error) {
        logger.info("share code refused", { uid: caller.uid, reason: result.error });
        return res.status(result.error === "not_found" || result.error === "gone" ? 404 : result.error === "not_eligible" ? 403 : 409).json({ error: { code: result.error, message: result.error } });
      }
      logger.info("share code redeemed", { uid: caller.uid, already: result.already === true });
      return res.status(200).json(result);
    } catch (err) {
      logger.error("share code redeem failed", { uid: caller.uid, reason: err.message });
      return res.status(500).json({ error: { message: "Redeem failed" } });
    }
  },
);
