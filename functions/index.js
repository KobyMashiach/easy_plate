// Mirrors every in-app notification as a push. A client cannot send FCM to
// another device (that needs the server key), so this is the one piece that
// has to run server-side.
const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");
const { logger } = require("firebase-functions");
const notificationPrefs = require("./notificationPrefs");
const remoteFlags = require("./remoteFlags");

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

// Google image results for a recipe photo, one page of ten at a time.
exports.imageSearch = require("./imageSearch").imageSearch;

// The signed-in user deleting their own account, as the stores require.
exports.deleteAccount = require("./deleteAccount").deleteAccount;

// Shefi's voice: a reply read out by Google Cloud Text-to-Speech.
exports.speak = require("./speak").speak;

// The administrator's account actions: block, delete, push to one or all.
exports.adminUsers = require("./adminUsers").adminUsers;

// The web console at aieasyplate.app/admin: every privileged action it
// takes, behind the same administrator check, with an audit row each.
exports.adminPanel = require("./adminPanel").adminPanel;

// Translates the account's own content into the language it picked.
exports.translateContent = require("./translateContent").translateContent;

// Once a week: the shekel rate and Google's token prices, so the dashboard's
// cost figure never depends on a number somebody typed. Each half is on its
// own so a missing Cloud Billing API does not stop the rate.
const { onSchedule } = require("firebase-functions/v2/scheduler");
const pricingCatalog = require("./pricingCatalog");
exports.weeklyPricing = onSchedule(
  { schedule: "every monday 06:00", timeZone: "Asia/Jerusalem", region: "europe-west1", retryCount: 1 },
  async () => {
    try {
      await pricingCatalog.syncRate();
    } catch (err) {
      logger.warn("weekly rate sync failed", { reason: err.message });
    }
    try {
      await pricingCatalog.syncPricing();
    } catch (err) {
      logger.warn("weekly catalog sync failed", { reason: err.message });
    }
  },
);

// Once a day, after Apple's daily report is out (about 5am Pacific): the
// exact store install counts for the console's Downloads page. A platform
// that is not configured yet is skipped, not failed.
const storeStats = require("./storeStats");
exports.dailyStoreStats = onSchedule(
  { schedule: "every day 16:30", timeZone: "Asia/Jerusalem", region: "europe-west1", retryCount: 1, timeoutSeconds: 540, memory: "512MiB" },
  async () => {
    const result = await storeStats.sync({ db: admin.firestore(), platform: "all" });
    logger.info("daily store stats", { android: result.android, ios: result.ios, errors: result.errors });
  },
);

// The recipient's locale is not known here; Hebrew is the app's primary
// language, and the in-app inbox is localised properly once they open it.
const bodyFor = (data, fromName) => {
  if (data.type === "shareInvite") {
    const role = data.role === "editor" ? "לעריכה" : "לצפייה";
    // `recipeTitle` holds whatever was shared: a recipe, a book or a plan.
    const what = data.kind === "book" ? "את הספר" : data.kind === "mealPlan" ? "את התפריט" : data.kind === "groceryList" ? "את רשימת הקניות" : "את";
    return `${fromName} שיתף/ה איתך ${what} "${data.recipeTitle}" ${role}`;
  }
  if (data.type === "sharedRecipeUpdated") {
    return `${fromName} עדכן/ה את "${data.recipeTitle}" — יש גרסה חדשה למתכון ששמרת`;
  }
  if (data.type === "adminMessage") {
    const title = String(data.title || "").trim();
    const message = String(data.message || "").trim();
    return title && message ? `${title}: ${message.slice(0, 180)}` : message || title || "הודעה מ-EasyPlate";
  }
  if (data.type === "adminReply") {
    const message = String(data.message || "").trim();
    return message ? `תשובה לפנייה שלך: ${message.slice(0, 180)}` : "יש תשובה לפנייה שלך";
  }
  if (data.type === "forumReply") {
    const title = String(data.postTitle || "").trim();
    const excerpt = String(data.excerpt || "").trim();
    const where = data.onMyPost === true ? `הגיב/ה לפוסט שלך "${title}"` : `הגיב/ה בדיון "${title}"`;
    return excerpt ? `${fromName} ${where}: ${excerpt.slice(0, 140)}` : `${fromName} ${where}`;
  }
  return "יש לך התראה חדשה";
};

exports.pushOnNotification = onDocumentCreated(
  "notifications/{uid}/items/{itemId}",
  async (event) => {
    const data = event.data?.data();
    if (!data) return;
    // A broadcast writes one item per inbox and sends the push itself, in
    // one multicast; pushing again here would ring every phone twice.
    if (data.silent === true) return;

    const db = admin.firestore();
    const [user, from, prefs, entitlement] = await Promise.all([
      db.doc(`users/${event.params.uid}`).get(),
      db.doc(`public_profiles/${data.fromUid}`).get(),
      notificationPrefs.load(db, event.params.uid),
      // The plan lives beside the account, not in it (the RevenueCat
      // webhook and admin grants write entitlements/{uid}).
      db.doc(`entitlements/${event.params.uid}`).get(),
    ]);

    // The account's own choice, checked before the token: an inbox item
    // is written for every kind, the push only for the kinds they asked for.
    if (!notificationPrefs.wantsPush(prefs, data)) {
      logger.info("push muted by preference", { uid: event.params.uid, type: String(data.type || "") });
      return;
    }

    // The plan's say, after the preference: on a gated plan a free account
    // keeps its inbox item but no phone rings.
    if (!(await remoteFlags.pushAllowedFor(entitlement))) {
      logger.info("push withheld: free plan", { uid: event.params.uid, type: String(data.type || "") });
      return;
    }

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
        // For a forum reply: what the tap opens, and which reply to land on.
        postId: String(data.postId || ""),
        replyId: String(data.replyId || ""),
        onMyPost: String(data.onMyPost === true),
        notificationId: String(event.params.itemId || ""),
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

    const item = {
      type: "sharedRecipeUpdated",
      fromUid: authorUid,
      sharedId,
      recipeTitle: String(after.title || ""),
      read: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    const uids = [...savers];
    const prefs = await Promise.all(uids.map((uid) => notificationPrefs.load(db, uid)));
    const batch = db.batch();
    let written = 0;
    uids.forEach((uid, i) => {
      // A saver who switched these off gets neither the item nor the push.
      if (!notificationPrefs.wantsInboxItem(prefs[i], item)) return;
      batch.set(db.collection("notifications").doc(uid).collection("items").doc(), item);
      written++;
    });
    if (written > 0) await batch.commit();
  },
);

// Someone replied in a thread: the thread's author and everyone who has
// replied in it before are told, except the replier themself. Each gets
// one inbox item (and, through pushOnNotification, a push), subject to
// their own notification choices. The reply's opening words travel with
// the item so the inbox row reads without a second lookup, and the ids
// are what a tap on the push opens.
exports.onForumReplyCreated = onDocumentCreated(
  "forum_posts/{postId}/replies/{replyId}",
  async (event) => {
    const reply = event.data?.data();
    if (!reply) return;
    const { postId, replyId } = event.params;
    const db = admin.firestore();
    const postRef = db.doc(`forum_posts/${postId}`);
    const [post, earlier] = await Promise.all([
      postRef.get(),
      postRef.collection("replies").select("authorUid").get(),
    ]);
    if (!post.exists) return;

    const replierUid = String(reply.authorUid || "");
    const postAuthorUid = String(post.get("authorUid") || "");

    // uid → whether the thread is theirs. The author's own entry wins over
    // a "joined" one, since a thread's author has usually replied in it too.
    const recipients = new Map();
    if (postAuthorUid && postAuthorUid !== replierUid) recipients.set(postAuthorUid, true);
    for (const doc of earlier.docs) {
      const uid = String(doc.get("authorUid") || "");
      if (!uid || uid === replierUid || recipients.has(uid)) continue;
      recipients.set(uid, false);
    }
    if (recipients.size === 0) {
      logger.info("forum reply, nobody to tell", { postId, replyId });
      return;
    }

    const body = String(reply.body || "").trim();
    const attached = String(reply.sharedRecipeTitle || "").trim();
    const excerpt = (body || (attached ? `🍽 ${attached}` : "")).slice(0, 140);
    const uids = [...recipients.keys()];
    const prefs = await Promise.all(uids.map((uid) => notificationPrefs.load(db, uid)));

    const batch = db.batch();
    let written = 0;
    uids.forEach((uid, i) => {
      const item = {
        type: "forumReply",
        fromUid: replierUid,
        postId,
        replyId,
        postTitle: String(post.get("title") || ""),
        excerpt,
        onMyPost: recipients.get(uid) === true,
        read: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      };
      if (!notificationPrefs.wantsInboxItem(prefs[i], item)) return;
      batch.set(db.collection("notifications").doc(uid).collection("items").doc(), item);
      written++;
    });
    if (written > 0) await batch.commit();
    logger.info("forum reply told", { postId, replyId, recipients: uids.length, written });
  },
);

exports.shareCodes = require("./shareCodes").shareCodes;

// The administrator editing Remote Config from the dashboard.
exports.adminRemoteConfig = require("./adminRemoteConfig").adminRemoteConfig;

// One signed-in device per account, a month at a time; the daily sweep
// revokes the tokens of sessions that ran out.
exports.sessions = require("./sessions").sessions;
exports.expireSessions = require("./sessions").expireSessions;

// Pro Duo / Pro Family: membership, inherited entitlement, the owner's
// subscription following to every member.
exports.households = require("./households").households;
exports.onOwnerEntitlementChanged = require("./households").onOwnerEntitlementChanged;
