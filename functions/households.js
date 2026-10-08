// Households: one Pro Duo (2 seats) or Pro Family (6 seats) subscription
// shared by several accounts. Members share one cloud root
// (`households/{hid}/…`, see the app's CloudRoot) and inherit the owner's
// entitlement. Membership is written here only: the rules let members read
// the household document and nothing else about it.
const { onRequest } = require("firebase-functions/v2/https");
const { onDocumentWritten } = require("firebase-functions/v2/firestore");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");
const proxy = require("./aiProxy").internals;

const SEATS = { duo: 2, family: 6 };

// The tier a store product grants, by its id: `easyplate_duo_monthly` → duo.
function tierOf(productId) {
  const id = String(productId || "").toLowerCase();
  if (id.includes("family")) return "family";
  if (id.includes("duo")) return "duo";
  return "pro";
}

function seatsFor(tier) {
  return SEATS[tier] || 1;
}

function ms(ts) {
  return ts && typeof ts.toMillis === "function" ? ts.toMillis() : null;
}

// Mirrors EntitlementService.resolvePremium in the app.
function entitlementActive(ent, nowMs = Date.now()) {
  if (!ent || ent.premium !== true) return false;
  const from = ms(ent.premiumFrom);
  if (from !== null && from > nowMs) return false;
  const until = ms(ent.premiumUntil);
  if (until !== null && until <= nowMs) return false;
  return true;
}

// What an entitlement lets its holder open: a household of this tier, or
// nothing. Inherited premium never qualifies, or a member could nest one.
function householdTierFor(ent, nowMs = Date.now()) {
  if (!entitlementActive(ent, nowMs) || ent.source === "household") return null;
  const tier = tierOf(ent.productId);
  return tier === "pro" ? null : tier;
}

// A member's entitlement document, derived from the owner's. Premium false
// when the owner's lapsed, so the lapse reaches every device at once.
function inheritedEntitlement(ownerEnt, householdId, nowMs = Date.now()) {
  const active = entitlementActive(ownerEnt, nowMs) && ownerEnt.source !== "household";
  return {
    premium: active,
    premiumFrom: null,
    premiumUntil: active ? ownerEnt.premiumUntil || null : null,
    productId: active ? String(ownerEnt.productId || "") : "",
    source: "household",
    householdId,
    adminLock: false,
  };
}

// Whether a member's own document may be replaced by the inherited one: it
// is absent, already inherited, or holds a subscription that ran out. A live
// purchase of their own is never overwritten.
function mayInherit(memberEnt, nowMs = Date.now()) {
  if (!memberEnt) return true;
  if (memberEnt.source === "household") return true;
  if (memberEnt.adminLock === true && entitlementActive(memberEnt, nowMs)) return false;
  return !entitlementActive(memberEnt, nowMs);
}

// The entitlement a member is left with after leaving: nothing, unless it
// was their own all along.
function releasedEntitlement() {
  return { premium: false, premiumUntil: null, premiumFrom: null, productId: "", source: "household", householdId: null, adminLock: false };
}

function publicHousehold(id, data) {
  return {
    id,
    ownerUid: data.ownerUid,
    tier: data.tier,
    seats: data.seats,
    title: data.title || "",
    memberUids: data.memberUids || [],
    members: data.members || {},
  };
}

async function householdOf(db, uid) {
  const snap = await db.collection("households").where("memberUids", "array-contains", uid).limit(1).get();
  return snap.empty ? null : snap.docs[0];
}

async function syncMembers(db, householdSnap, ownerEnt) {
  const data = householdSnap.data();
  const now = Date.now();
  const batch = db.batch();
  let writes = 0;
  for (const memberUid of data.memberUids || []) {
    if (memberUid === data.ownerUid) continue;
    const ref = db.collection("entitlements").doc(memberUid);
    const memberEnt = (await ref.get()).data();
    if (!mayInherit(memberEnt, now)) continue;
    batch.set(ref, { ...inheritedEntitlement(ownerEnt, householdSnap.id, now), updatedAt: admin.firestore.FieldValue.serverTimestamp() }, { merge: true });
    writes++;
  }
  if (writes) await batch.commit();
  return writes;
}

async function create(db, uid, title) {
  if (await householdOf(db, uid)) return { error: "in_household" };
  const ent = (await db.collection("entitlements").doc(uid).get()).data();
  const tier = householdTierFor(ent);
  if (!tier) return { error: "not_eligible" };
  const ref = db.collection("households").doc();
  const data = {
    ownerUid: uid,
    tier,
    seats: seatsFor(tier),
    title: String(title || "").slice(0, 60),
    memberUids: [uid],
    members: { [uid]: { joinedAt: admin.firestore.Timestamp.now(), role: "owner" } },
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };
  await ref.set(data);
  return { household: publicHousehold(ref.id, data) };
}

// Called by shareCodes.redeem for a code of kind household.
async function join(db, householdId, uid) {
  const ref = db.collection("households").doc(householdId);
  const snap = await ref.get();
  if (!snap.exists) return { error: "gone" };
  const data = snap.data();
  if ((data.memberUids || []).includes(uid)) return { already: true, household: publicHousehold(snap.id, data) };
  if (await householdOf(db, uid)) return { error: "in_household" };
  if ((data.memberUids || []).length >= (data.seats || 1)) return { error: "full" };
  const ownerEnt = (await db.collection("entitlements").doc(data.ownerUid).get()).data();
  if (!householdTierFor(ownerEnt)) return { error: "not_eligible" };

  const batch = db.batch();
  batch.update(ref, {
    memberUids: admin.firestore.FieldValue.arrayUnion(uid),
    [`members.${uid}`]: { joinedAt: admin.firestore.Timestamp.now(), role: "member" },
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  const entRef = db.collection("entitlements").doc(uid);
  if (mayInherit((await entRef.get()).data())) {
    batch.set(entRef, { ...inheritedEntitlement(ownerEnt, snap.id), updatedAt: admin.firestore.FieldValue.serverTimestamp() }, { merge: true });
  }
  await batch.commit();
  return { household: publicHousehold(snap.id, { ...data, memberUids: [...(data.memberUids || []), uid] }) };
}

async function removeMember(db, householdSnap, memberUid) {
  const batch = db.batch();
  batch.update(householdSnap.ref, {
    memberUids: admin.firestore.FieldValue.arrayRemove(memberUid),
    [`members.${memberUid}`]: admin.firestore.FieldValue.delete(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  const entRef = db.collection("entitlements").doc(memberUid);
  const ent = (await entRef.get()).data();
  if (ent && ent.source === "household") {
    batch.set(entRef, { ...releasedEntitlement(), updatedAt: admin.firestore.FieldValue.serverTimestamp() }, { merge: true });
  }
  await batch.commit();
}

async function leave(db, uid) {
  const snap = await householdOf(db, uid);
  if (!snap) return { error: "not_member" };
  if (snap.get("ownerUid") === uid) return { error: "owner_cannot_leave" };
  await removeMember(db, snap, uid);
  return { ok: true };
}

async function remove(db, uid, memberUid) {
  const snap = await householdOf(db, uid);
  if (!snap || snap.get("ownerUid") !== uid) return { error: "not_owner" };
  if (memberUid === uid) return { error: "owner_cannot_leave" };
  if (!(snap.get("memberUids") || []).includes(memberUid)) return { error: "not_member" };
  await removeMember(db, snap, memberUid);
  return { ok: true };
}

// The owner closes the household: members lose the inherited entitlement,
// the document and every mirrored collection under it are deleted. The
// owner's own device still holds the data and pushes it back to its own
// root (the app rehomes without wiping for the owner).
async function dissolve(db, uid) {
  const snap = await householdOf(db, uid);
  if (!snap || snap.get("ownerUid") !== uid) return { error: "not_owner" };
  for (const memberUid of snap.get("memberUids") || []) {
    if (memberUid === uid) continue;
    const entRef = db.collection("entitlements").doc(memberUid);
    const ent = (await entRef.get()).data();
    if (ent && ent.source === "household") {
      await entRef.set({ ...releasedEntitlement(), updatedAt: admin.firestore.FieldValue.serverTimestamp() }, { merge: true });
    }
  }
  await db.recursiveDelete(snap.ref);
  return { ok: true };
}

exports.internals = { tierOf, seatsFor, entitlementActive, householdTierFor, inheritedEntitlement, mayInherit, releasedEntitlement, publicHousehold, join, create, leave, remove, dissolve, syncMembers };

const STATUS = { in_household: 409, not_eligible: 403, gone: 404, full: 409, not_member: 404, not_owner: 403, owner_cannot_leave: 409 };

exports.households = onRequest(
  { region: "europe-west1", cors: false, maxInstances: 5 },
  async (req, res) => {
    if (req.method !== "POST") return res.status(405).json({ error: { message: "Method not allowed" } });
    const caller = await proxy.verifyCaller(req);
    if (!caller) return res.status(401).json({ error: { message: "A valid Firebase ID token is required" } });
    const body = req.body || {};
    const db = admin.firestore();
    try {
      let result;
      switch (body.action) {
        case "create": result = await create(db, caller.uid, body.title); break;
        case "leave": result = await leave(db, caller.uid); break;
        case "remove": result = await remove(db, caller.uid, String(body.memberUid || "")); break;
        case "dissolve": result = await dissolve(db, caller.uid); break;
        default: return res.status(400).json({ error: { message: "Unknown action" } });
      }
      if (result.error) {
        logger.info("household action refused", { uid: caller.uid, action: body.action, reason: result.error });
        return res.status(STATUS[result.error] || 400).json({ error: { code: result.error, message: result.error } });
      }
      logger.info("household action", { uid: caller.uid, action: body.action });
      return res.status(200).json(result);
    } catch (err) {
      logger.error("household action failed", { uid: caller.uid, action: body.action, reason: err.message });
      return res.status(500).json({ error: { message: "Household action failed" } });
    }
  },
);

// The owner's entitlement moved (a renewal, a lapse, an upgrade): every
// member's inherited document follows. Inherited documents themselves are
// skipped, or each write would fan out again.
exports.onOwnerEntitlementChanged = onDocumentWritten(
  { document: "entitlements/{uid}", region: "europe-west1" },
  async (event) => {
    const after = event.data && event.data.after;
    const ent = after && after.exists ? after.data() : null;
    if (ent && ent.source === "household") return;
    const uid = event.params.uid;
    const db = admin.firestore();
    const owned = await db.collection("households").where("ownerUid", "==", uid).get();
    for (const snap of owned.docs) {
      const writes = await syncMembers(db, snap, ent || {});
      logger.info("household entitlement synced", { householdId: snap.id, writes });
    }
  },
);
