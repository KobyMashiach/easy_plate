// Mirrors every in-app notification as a push. A client cannot send FCM to
// another device (that needs the server key), so this is the one piece that
// has to run server-side.
const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");
const { logger } = require("firebase-functions");

admin.initializeApp();

// The Gemini proxy lives in its own file; it shares this app instance.
exports.aiProxy = require("./aiProxy").aiProxy;
// RevenueCat's subscription events, written onto entitlements/{uid}.
exports.revenueCatWebhook = require("./revenueCatWebhook").revenueCatWebhook;
// A recipe out of a TikTok / Instagram / YouTube / Facebook video: the video
// itself goes to the model, not just the page around it.
exports.socialRecipe = require("./socialRecipe").socialRecipe;
// Community price averages, fed by receipts users chose to share.
exports.priceStats = require("./priceStats").priceStats;

// The recipient's locale is not known here; Hebrew is the app's primary
// language, and the in-app inbox is localised properly once they open it.
const bodyFor = (data, fromName) => {
  if (data.type === "shareInvite") {
    const role = data.role === "editor" ? "לעריכה" : "לצפייה";
    // `recipeTitle` holds whatever was shared: a recipe, a book or a plan.
    const what = data.kind === "book" ? "את הספר" : data.kind === "mealPlan" ? "את התפריט" : "את";
    return `${fromName} שיתף/ה איתך ${what} "${data.recipeTitle}" ${role}`;
  }
  if (data.type === "sharedRecipeUpdated") {
    return `${fromName} עדכן/ה את "${data.recipeTitle}" — יש גרסה חדשה למתכון ששמרת`;
  }
  return "יש לך התראה חדשה";
};

exports.pushOnNotification = onDocumentCreated(
  "notifications/{uid}/items/{itemId}",
  async (event) => {
    const data = event.data?.data();
    if (!data) return;

    const db = admin.firestore();
    const [user, from] = await Promise.all([
      db.doc(`users/${event.params.uid}`).get(),
      db.doc(`public_profiles/${data.fromUid}`).get(),
    ]);

    const token = user.get("pushToken");
    if (!token) return;

    const fromName = from.get("fullName") || "מישהו";
    try {
      await admin.messaging().send({
      token,
      notification: { title: "EasyPlate", body: bodyFor(data, fromName) },
      data: {
        type: String(data.type || ""),
        inviteId: String(data.inviteId || ""),
        collabId: String(data.collabId || ""),
        kind: String(data.kind || ""),
      },
      android: { priority: "high" },
      apns: { payload: { aps: { sound: "default" } } },
      });
      logger.info("push sent", { uid: event.params.uid, type: String(data.type || "") });
    } catch (err) {
      // A stale token is the common case: the user reinstalled and the
      // profile still holds the old one. Logged, not thrown — the inbox
      // item exists either way.
      logger.warn("push failed", { uid: event.params.uid, reason: err.message });
    }
  },
);

// The fields of a post a saver would care about changing. Likes and the
// like counter change all the time and are not an edit.
const RECIPE_FIELDS = [
  "title", "prepTimeMinutes", "cookTimeMinutes", "ingredients", "steps",
  "dietaryTags", "allergens", "mayContain", "imageFileName", "imageStoragePath",
  "servings", "nutrition",
];

// The fields that differ between two versions of a post — empty when only
// likes or metadata moved.
function changedFields(before, after) {
  return RECIPE_FIELDS.filter(
    (f) => JSON.stringify(before[f] ?? null) !== JSON.stringify(after[f] ?? null),
  );
}

function recipeChanged(before, after) {
  return changedFields(before, after).length > 0;
}

// The author edited a community post: everyone who saved a copy gets an
// inbox item (and, through pushOnNotification, a push) offering to refresh
// or keep their copy. The saved copies are found through a collection
// group query on `savedFromSharedId` (see firestore.indexes.json).
exports.onSharedRecipeUpdated = onDocumentUpdated(
  "shared_recipes/{sharedId}",
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    const sharedId = event.params.sharedId;
    const changed = before && after ? changedFields(before, after) : [];
    if (changed.length === 0) {
      logger.info("post touched, nothing to tell", { sharedId });
      return;
    }

    const db = admin.firestore();
    const copies = await db.collectionGroup("recipes").where("savedFromSharedId", "==", sharedId).get();
    const authorUid = String(after.authorUid || "");
    const savers = new Set();
    for (const doc of copies.docs) {
      // users/{uid}/recipes/{id}
      const uid = doc.ref.parent.parent?.id;
      if (uid && uid !== authorUid) savers.add(uid);
    }
    logger.info("post edited", { sharedId, changed, copies: copies.size, savers: savers.size });
    if (savers.size === 0) return;

    const batch = db.batch();
    for (const uid of savers) {
      batch.set(db.collection("notifications").doc(uid).collection("items").doc(), {
        type: "sharedRecipeUpdated",
        fromUid: authorUid,
        sharedId,
        recipeTitle: String(after.title || ""),
        read: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  },
);
