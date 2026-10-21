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
// The website (aieasyplate.app/app) calls this from the browser too.
const { ORIGINS } = require("./origins");

const CODE_RE = /^[A-Z2-9]{8}$/;
const KINDS = new Set(["recipe", "book", "mealPlan", "groceryList", "household"]);
// Recipes a shared container may carry along in one redemption: each is two
// reads and a write inside one transaction (Firestore takes 500 writes).
const MAX_CONTAINER_RECIPES = 400;

// Normalises "ep-7k3m 9qx2" → "7K3M9QX2". The "EP" is stripped only from
// the 10-character display form: E and P are both in the alphabet, so an
// 8-character string that starts with them is the code itself.
function normalizeCode(raw) {
  if (typeof raw !== "string") return null;
  const cleaned = raw.toUpperCase().replace(/[^A-Z0-9]/g, "");
  const code = cleaned.length === 10 && cleaned.startsWith("EP") ? cleaned.slice(2) : cleaned;
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

// Pure: a title as the invite and the inbox item carry it. The code and the
// shared document are the owner's own writing, so a title there may be any
// type and any length; what reaches the redeemer's inbox is a short string.
function titleOf(...candidates) {
  for (const value of candidates) {
    if (typeof value === "string" && value.trim()) return value.slice(0, 200);
  }
  return "";
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

// Pure: an id Firestore takes as one document segment. The content is the
// owner's own writing; an id that would be a path is skipped, not followed.
function validId(id) {
  return typeof id === "string" && /^[^/]{1,128}$/.test(id) && id !== "." && id !== ".." && !/^__.*__$/.test(id);
}

// Recipe collab ids a container's content refers to (books: recipes[].collabId,
// plans: meals[].items[].recipeCollabId), as the app's CollabContainerEntity.
function recipeCollabIdsIn(content) {
  const ids = new Set();
  const take = (id) => {
    if (validId(id)) ids.add(id);
  };
  for (const r of (content && Array.isArray(content.recipes) ? content.recipes : [])) {
    if (r) take(r.collabId);
  }
  for (const meal of (content && Array.isArray(content.meals) ? content.meals : [])) {
    for (const item of (meal && Array.isArray(meal.items) ? meal.items : [])) {
      if (item) take(item.recipeCollabId);
    }
  }
  return [...ids];
}

// One transaction from the code to the invite: the `maxUses` check and the
// `uses` increment see the same count (two redemptions of a one-use code at
// once used to both pass), and so does a household's seat count. Firestore
// wants every read before the first write, which is why the container's
// recipes are read in one `getAll` up front rather than as they are written.
async function redeem(db, code, uid) {
  const ref = db.collection("share_codes").doc(code);
  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const doc = snap.exists ? snap.data() : null;
    const reason = rejectReason(doc, uid);
    if (reason) return { error: reason };

    const role = doc.role === "editor" ? "editor" : "viewer";
    const used = { uses: admin.firestore.FieldValue.increment(1), lastUsedAt: admin.firestore.FieldValue.serverTimestamp() };

    if (doc.kind === "household") {
      // Membership is written directly: there is no invite to accept, the
      // app's household listener sees the new document.
      const joined = await households.join(db, doc.targetId, uid, { tx, issuerUid: doc.ownerUid });
      if (joined.error) return joined;
      if (joined.already) return { already: true, household: joined.household };
      tx.update(ref, used);
      return { household: joined.household };
    }

    const isRecipe = doc.kind === "recipe";
    const target = await tx.get(db.collection(isRecipe ? "collab_recipes" : "collab_containers").doc(doc.targetId));
    if (!target.exists) return { error: "gone" };
    // A code is the owner's to write: one minted by a member for a document
    // they only read would otherwise hand out seats on it.
    if (target.get("ownerUid") !== doc.ownerUid) return { error: "gone" };
    // The roster is the one truth about membership. An invite document that
    // still says `accepted` while the uid is off the roster is from before
    // the owner removed them: redeeming again is a fresh invite (pending,
    // with its inbox item), not "already a member" — the same call the
    // app's inviteIsDead makes.
    if ((target.get("memberUids") || []).includes(uid)) return { already: true };
    const fields = { collabId: doc.targetId, title: titleOf(doc.title, target.get("title")), ownerUid: doc.ownerUid, targetUid: uid, role, kind: doc.kind };

    // The recipes inside a container travel with it: a silent invite for
    // each one the owner owns and the member does not have. A pending or
    // declined one stands; an accepted one the roster no longer honours is
    // written afresh, as above.
    const silent = [];
    const recipeIds = isRecipe ? [] : recipeCollabIdsIn(target.get("content"));
    // Refused whole rather than cut: a member who silently got half a book's
    // recipes would see the rest as broken links.
    if (recipeIds.length > MAX_CONTAINER_RECIPES) return { error: "too_many_recipes" };
    if (recipeIds.length) {
      const [recipes, recipeInvites] = await Promise.all([
        tx.getAll(...recipeIds.map((id) => db.collection("collab_recipes").doc(id))),
        tx.getAll(...recipeIds.map((id) => db.collection("share_invites").doc(inviteId(id, uid)))),
      ]);
      recipes.forEach((recipe, i) => {
        if (!recipe.exists || recipe.get("ownerUid") !== doc.ownerUid) return;
        if ((recipe.get("memberUids") || []).includes(uid)) return;
        if (recipeInvites[i].exists && recipeInvites[i].get("status") !== "accepted") return;
        silent.push({ collabId: recipe.id, title: titleOf(recipe.get("title")), ownerUid: doc.ownerUid, targetUid: uid, role, kind: "recipe", via: doc.targetId });
      });
    }

    tx.set(db.collection("share_invites").doc(inviteId(doc.targetId, uid)), inviteFields(fields));
    tx.set(db.collection("notifications").doc(uid).collection("items").doc(inviteId(doc.targetId, uid)), notificationFields(fields));
    for (const recipeFields of silent) {
      tx.set(db.collection("share_invites").doc(inviteId(recipeFields.collabId, uid)), inviteFields(recipeFields));
    }
    tx.update(ref, used);
    return { invite: { id: inviteId(doc.targetId, uid), ...fields } };
  });
}

exports.internals = { MAX_CONTAINER_RECIPES, titleOf, validId, normalizeCode, rejectReason, recipeCollabIdsIn, inviteFields, notificationFields, redeem };

exports.shareCodes = onRequest(
  { region: "europe-west1", cors: ORIGINS, maxInstances: 5 },
  async (req, res) => {
    if (req.method !== "POST") return res.status(405).json({ error: { message: "Method not allowed" } });
    const caller = await proxy.verifyCaller(req);
    if (!caller) return res.status(401).json({ error: { message: "A valid Firebase ID token is required" } });
    // Switched off from the console (the `disabled` claim, adminUsers.disable).
    if (caller.disabled === true) return res.status(403).json({ error: { code: "account_disabled", message: "This account is disabled" } });
    const action = req.body && req.body.action;
    if (action !== "redeem") return res.status(400).json({ error: { message: "Unknown action" } });
    const code = normalizeCode(req.body && req.body.code);
    if (!code) return res.status(400).json({ error: { code: "invalid", message: "Invalid code" } });
    try {
      const result = await redeem(admin.firestore(), code, caller.uid);
      if (result.error) {
        logger.info("share code refused", { uid: caller.uid, reason: result.error });
        const status = result.error === "not_found" || result.error === "gone" ? 404 : result.error === "not_eligible" ? 403 : 409;
        const message = result.error === "too_many_recipes" ? `This share carries more than ${MAX_CONTAINER_RECIPES} recipes; ask the owner to split it` : result.error;
        return res.status(status).json({ error: { code: result.error, message } });
      }
      logger.info("share code redeemed", { uid: caller.uid, already: result.already === true });
      return res.status(200).json(result);
    } catch (err) {
      logger.error("share code redeem failed", { uid: caller.uid, reason: err.message });
      return res.status(500).json({ error: { message: "Redeem failed" } });
    }
  },
);
