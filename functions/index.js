// Mirrors every in-app notification as a push. A client cannot send FCM to
// another device (that needs the server key), so this is the one piece that
// has to run server-side.
const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");
const { logger } = require("firebase-functions");
const notificationPrefs = require("./notificationPrefs");
const remoteFlags = require("./remoteFlags");
const budget = require("./dailyBudget");

admin.initializeApp();

// The Gemini proxy lives in its own file; it shares this app instance.
exports.aiProxy = require("./aiProxy").aiProxy;
// Daily: the conversation-owner rows (ai_interactions) past their 30 days.
exports.cleanupAiInteractions = require("./aiProxy").cleanupAiInteractions;
// RevenueCat's subscription events, written onto entitlements/{uid}.
exports.revenueCatWebhook = require("./revenueCatWebhook").revenueCatWebhook;
// Premium bought on the website: webBilling routes Israeli accounts to
// PayPlus (payplusWebhook) and everyone else to RevenueCat's Paddle Billing
// integration (a Web Purchase Link; revenueCatWebhook above reports it as
// store PADDLE). Both write the same entitlements/{uid} document.
// paddleWebhook.js (the direct Paddle route) is retired and deliberately
// NOT exported: RevenueCat owns the Paddle notifications now, and a second
// receiver would grant the same purchase twice. stripeWebhook is dormant
// (no route sells through Stripe) and kept for a future US entity.
exports.webBilling = require("./webBilling").webBilling;
exports.payplusWebhook = require("./payplusWebhook").payplusWebhook;
exports.stripeWebhook = require("./stripeWebhook").stripeWebhook;
// One-time personal links that open the website signed in, on the pricing
// page (the app's "upgrade on the web" row, SMS / email delivery).
exports.upgradeLinks = require("./upgradeLinks").upgradeLinks;
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
// A share invite's item is written by the sharer's own client, so its title
// is whatever that client sent: cut to a line, or a megabyte of it made the
// push too large to send (FCM takes 4 KB) and a map printed as
// "[object Object]".
const clip = (value, max) => (typeof value === "string" ? value : "").slice(0, max);

const bodyFor = (data, fromName) => {
  fromName = clip(fromName, 80) || "מישהו";
  if (data.type === "shareInvite") {
    const role = data.role === "editor" ? "לעריכה" : "לצפייה";
    // `recipeTitle` holds whatever was shared: a recipe, a book or a plan.
    const what = data.kind === "book" ? "את הספר" : data.kind === "mealPlan" ? "את התפריט" : data.kind === "groceryList" ? "את רשימת הקניות" : "את";
    return `${fromName} שיתף/ה איתך ${what} "${clip(data.recipeTitle, 120)}" ${role}`;
  }
  if (data.type === "sharedRecipeUpdated") {
    return `${fromName} עדכן/ה את "${clip(data.recipeTitle, 120)}" — יש גרסה חדשה למתכון ששמרת`;
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

// Spends one unit of the sender's daily invite-push allowance and one of
// the sender→recipient pair's. A budget that cannot be read lets the push
// through: a Firestore hiccup must not silence real invites.
async function invitePushAllowed(fromUid, toUid, spend = budget.spend) {
  if (!fromUid) return true;
  try {
    const sender = await spend({ uid: fromUid, kind: "invitePush" });
    if (!sender.allowed) return false;
    const pair = await spend({ uid: `${fromUid}_${toUid}`, kind: "invitePushPair" });
    return pair.allowed;
  } catch (err) {
    logger.warn("invite push allowance unreadable", { reason: err.message });
    return true;
  }
}

// Spends one of the replier's daily reply notifications. Unreadable
// budget: told anyway (a Firestore hiccup must not silence a thread).
async function replyFanoutAllowed(uid, spend = budget.spend) {
  if (!uid) return false;
  try {
    return (await spend({ uid, kind: "forumReplyFanout" })).allowed;
  } catch (err) {
    logger.warn("reply fan-out allowance unreadable", { reason: err.message });
    return true;
  }
}

// Spends one of the author's daily recipe-update notifications. Unreadable
// budget: told anyway, like the reply fan-out.
async function recipeUpdateFanoutAllowed(uid, spend = budget.spend) {
  if (!uid) return false;
  try {
    return (await spend({ uid, kind: "recipeUpdateFanout" })).allowed;
  } catch (err) {
    logger.warn("recipe update fan-out allowance unreadable", { reason: err.message });
    return true;
  }
}

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
    if (typeof token !== "string" || !token) return;

    // An invite is the one kind a client writes into someone else's inbox
    // (the rules hold it to a real invite from the sender), and a browser
    // can write one invite after another: past a daily allowance per sender,
    // and per sender and recipient, the item stays but the phone does not
    // ring again.
    if (data.type === "shareInvite" && !(await invitePushAllowed(String(data.fromUid || ""), event.params.uid))) {
      logger.info("push withheld: invite push allowance spent", { uid: event.params.uid, fromUid: String(data.fromUid || "") });
      return;
    }

    const fromName = from.get("fullName") || "מישהו";
    try {
      await admin.messaging().send({
      token,
      notification: { title: "EasyPlate", body: bodyFor(data, fromName) },
      data: {
        type: String(data.type || "").slice(0, 40),
        inviteId: String(data.inviteId || "").slice(0, 300),
        collabId: String(data.collabId || "").slice(0, 300),
        kind: String(data.kind || "").slice(0, 40),
        // For a forum reply: what the tap opens, and which reply to land on.
        postId: String(data.postId || "").slice(0, 300),
        replyId: String(data.replyId || "").slice(0, 300),
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

// Pure: where a saved copy lives, from its document path. A copy is
// users/{uid}/recipes/{id} on a personal root or households/{hid}/recipes/{id}
// when the saver's account is in a household (CloudRoot in the app moves the
// whole recipes mirror there). Anything else under a `recipes` collection is
// not a saved copy of anyone's.
function copyRootOf(ref) {
  const root = ref && ref.parent && ref.parent.parent;
  const collection = root && root.parent && root.parent.id;
  if (collection === "users" || collection === "households") return { collection, id: root.id };
  return null;
}

// Pure: who is told about an edit. Personal copies name their saver; a
// household copy is every member of that household (the copy is in all their
// boxes, and the refresh the inbox card offers works from each of them).
// The author is never told about their own edit.
function saversFor(roots, membersByHousehold, authorUid) {
  const savers = new Set();
  for (const root of roots) {
    if (!root) continue;
    if (root.collection === "users") savers.add(root.id);
    else for (const uid of membersByHousehold.get(root.id) || []) savers.add(uid);
  }
  savers.delete(authorUid);
  return [...savers];
}

// How many preference documents are read at once, and how many inbox items
// go into one batch (Firestore stops a batch at 500 operations).
const PREFS_BATCH = 50;
// How many of a thread's latest replies are looked at for who to tell.
const REPLY_SCAN_LIMIT = 500;
const WRITE_BATCH = 400;

// One inbox item per uid, each subject to that account's own notification
// choices, in bounded groups: a popular post saved by thousands used to put
// every item into one batch, which Firestore refuses past 500, so nobody
// was told at all.
async function writeInboxItems(db, uids, itemFor) {
  let written = 0;
  let batch = db.batch();
  let pending = 0;
  for (let i = 0; i < uids.length; i += PREFS_BATCH) {
    const chunk = uids.slice(i, i + PREFS_BATCH);
    const prefs = await Promise.all(chunk.map((uid) => notificationPrefs.load(db, uid)));
    for (const [j, uid] of chunk.entries()) {
      const item = itemFor(uid);
      // A recipient who switched these off gets neither the item nor the push.
      if (!notificationPrefs.wantsInboxItem(prefs[j], item)) continue;
      batch.set(db.collection("notifications").doc(uid).collection("items").doc(), item);
      written++;
      if (++pending === WRITE_BATCH) {
        await batch.commit();
        batch = db.batch();
        pending = 0;
      }
    }
  }
  if (pending > 0) await batch.commit();
  return written;
}

// The author edited a community post: everyone who saved a copy gets an
// inbox item (and, through pushOnNotification, a push) offering to refresh
// or keep their copy. The saved copies are found through a collection
// group query on `savedFromSharedId` (see firestore.indexes.json).
// Saved copies read per edit, at most. A popular post's savers past this
// are not told of this one edit (logged); the edit itself stands.
const COPY_SCAN_LIMIT = 5000;

/// The work of onSharedRecipeUpdated, with its collaborators passed in for
/// the test. The author's daily allowance is spent before the saved copies
/// are scanned — the scan is the expensive part (a collection-group query
/// over every account's recipes), and a loop of one-character edits used
/// to run it on every edit even when the allowance was long gone. A one-row
/// probe first, so an edit of a post nobody saved spends nothing.
async function tellSaversOfEdit(db, { sharedId, before, after }, { allowed = recipeUpdateFanoutAllowed, write = writeInboxItems } = {}) {
  const changed = before && after ? changedFields(before, after) : [];
  if (changed.length === 0) {
    logger.info("post touched, nothing to tell", { sharedId });
    return { told: 0, reason: "unchanged" };
  }
  const authorUid = String(after.authorUid || "");
  // Only the paths are needed; a saved copy is a whole recipe, and
  // reading every one of them in full put megabytes into memory for a
  // popular post (or for one somebody pointed thousands of copies at).
  const query = db.collectionGroup("recipes").where("savedFromSharedId", "==", sharedId).select();
  const probe = await query.limit(1).get();
  if (probe.empty) return { told: 0, reason: "no_copies" };
  // The edit itself stands; only the telling is capped.
  if (!(await allowed(authorUid))) {
    logger.info("recipe update fan-out over the author's daily budget", { sharedId, authorUid });
    return { told: 0, reason: "budget" };
  }
  const copies = await query.limit(COPY_SCAN_LIMIT).get();
  if (copies.size >= COPY_SCAN_LIMIT) logger.warn("saved copies past the scan limit; the rest are not told", { sharedId, limit: COPY_SCAN_LIMIT });
  const roots = copies.docs.map((doc) => copyRootOf(doc.ref));
  // A household copy used to be read as a saver named by the household
  // id, and its inbox item written under notifications/{hid}, where no
  // account ever looks. The members are read instead, in one getAll.
  const householdIds = [...new Set(roots.filter((r) => r && r.collection === "households").map((r) => r.id))];
  const membersByHousehold = new Map();
  if (householdIds.length) {
    const snaps = await db.getAll(...householdIds.map((id) => db.doc(`households/${id}`)));
    for (const snap of snaps) {
      if (snap.exists) membersByHousehold.set(snap.id, (snap.get("memberUids") || []).map(String));
    }
  }
  const uids = saversFor(roots, membersByHousehold, authorUid);
  logger.info("post edited", { sharedId, changed, copies: copies.size, households: householdIds.length, savers: uids.length });
  if (uids.length === 0) return { told: 0, reason: "no_savers" };
  const item = {
    type: "sharedRecipeUpdated",
    fromUid: authorUid,
    sharedId,
    recipeTitle: String(after.title || ""),
    read: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  };
  await write(db, uids, () => item);
  return { told: uids.length };
}

exports.onSharedRecipeUpdated = onDocumentUpdated(
  "shared_recipes/{sharedId}",
  async (event) => {
    await tellSaversOfEdit(admin.firestore(), {
      sharedId: event.params.sharedId,
      before: event.data?.before.data(),
      after: event.data?.after.data(),
    });
  },
);

// The thread's replyCount set back to the replies that exist. The rules let
// any signed-in client move it up by one (the app's reply batch does), and
// cannot tie that step to a reply id they never see, so a loop of bare
// increments could make a thread read "9,000 replies"; deletions never
// took it down either. One count aggregation per reply puts it right. Best
// effort: a failure leaves the counter as it was.
async function reconcileReplyCount(postRef, stored) {
  try {
    const actual = (await postRef.collection("replies").count().get()).data().count;
    if (stored !== actual) await postRef.update({ replyCount: actual });
    return actual;
  } catch (err) {
    logger.warn("reply count not reconciled", { post: postRef.id, reason: err.message });
    return null;
  }
}

/// The work of onForumReplyCreated, collaborators passed in for the test.
/// The replier's daily allowance is spent before the earlier replies are
/// scanned (up to REPLY_SCAN_LIMIT reads): past it, a reply loop used to
/// pay that scan on every reply only to tell nobody. Spent only when there
/// can be someone to tell (another author, or earlier replies).
async function tellThreadOfReply(db, { postId, replyId, reply }, { allowed = replyFanoutAllowed, write = writeInboxItems, reconcile = reconcileReplyCount } = {}) {
  if (!reply) return { told: 0, reason: "no_reply" };
  const postRef = db.doc(`forum_posts/${postId}`);
  const post = await postRef.get();
  if (!post.exists) return { told: 0, reason: "no_post" };
  const count = await reconcile(postRef, post.get("replyCount"));

  const replierUid = String(reply.authorUid || "");
  const postAuthorUid = String(post.get("authorUid") || "");
  const othersReplied = typeof count === "number" ? count > 1 : true;
  if (!(postAuthorUid && postAuthorUid !== replierUid) && !othersReplied) {
    logger.info("forum reply, nobody to tell", { postId, replyId });
    return { told: 0, reason: "nobody" };
  }
  // One account's replies tell others only so many times a day: past
  // that the reply stands, but nobody's inbox or phone hears of it.
  if (!(await allowed(replierUid))) {
    logger.info("forum reply not fanned out: daily allowance spent", { postId, replyId, uid: replierUid });
    return { told: 0, reason: "budget" };
  }
  // The most recent participants, bounded: every reply used to read every
  // earlier one, so a long (or spammed) thread cost reads in the square of
  // its length.
  const earlier = await postRef.collection("replies").orderBy("createdAt", "desc").limit(REPLY_SCAN_LIMIT).select("authorUid").get();

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
    return { told: 0, reason: "nobody" };
  }

  const body = String(reply.body || "").trim();
  const attached = String(reply.sharedRecipeTitle || "").trim();
  const excerpt = (body || (attached ? `🍽 ${attached}` : "")).slice(0, 140);
  const uids = [...recipients.keys()];
  const written = await write(db, uids, (uid) => ({
    type: "forumReply",
    fromUid: replierUid,
    postId,
    replyId,
    postTitle: String(post.get("title") || ""),
    excerpt,
    onMyPost: recipients.get(uid) === true,
    read: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  }));
  logger.info("forum reply told", { postId, replyId, recipients: uids.length, written });
  return { told: uids.length };
}

// Someone replied in a thread: the thread's author and everyone who has
// replied in it before are told, except the replier themself. Each gets
// one inbox item (and, through pushOnNotification, a push), subject to
// their own notification choices. The reply's opening words travel with
// the item so the inbox row reads without a second lookup, and the ids
// are what a tap on the push opens.
exports.onForumReplyCreated = onDocumentCreated(
  "forum_posts/{postId}/replies/{replyId}",
  async (event) => {
    const { postId, replyId } = event.params;
    await tellThreadOfReply(admin.firestore(), { postId, replyId, reply: event.data?.data() });
  },
);

exports.shareCodes = require("./shareCodes").shareCodes;

// The administrator editing Remote Config from the dashboard.
exports.adminRemoteConfig = require("./adminRemoteConfig").adminRemoteConfig;

// One signed-in device per account, a month at a time; the daily sweep
// revokes the tokens of sessions that ran out.
// users/{uid}.permission ("admin" | "user"): who the administrator is.
exports.onUserCreated = require("./permissions").onUserCreated;

// Notification templates on a schedule (adminNotifications.js).
exports.runNotificationTemplates = require("./adminNotifications").runNotificationTemplates;

exports.sessions = require("./sessions").sessions;
exports.expireSessions = require("./sessions").expireSessions;

// Pro Duo / Pro Family: membership, inherited entitlement, the owner's
// subscription following to every member.
exports.households = require("./households").households;
exports.onOwnerEntitlementChanged = require("./households").onOwnerEntitlementChanged;
exports.restoreHouseholdPremium = require("./households").restoreHouseholdPremium;

// The pure parts of the triggers above, for the unit test.
exports.internals = { tellSaversOfEdit, tellThreadOfReply, COPY_SCAN_LIMIT, reconcileReplyCount, bodyFor, invitePushAllowed, replyFanoutAllowed, recipeUpdateFanoutAllowed, REPLY_SCAN_LIMIT, changedFields, recipeChanged, copyRootOf, saversFor, writeInboxItems, PREFS_BATCH, WRITE_BATCH };
