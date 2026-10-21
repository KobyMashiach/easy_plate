// Households: one Pro Duo (2 seats) or Pro Family (6 seats) subscription
// shared by several accounts. Members share one cloud root
// (`households/{hid}/…`, see the app's CloudRoot) and inherit the owner's
// entitlement. Membership is written here only: the rules let members read
// the household document and nothing else about it.
const { onRequest } = require("firebase-functions/v2/https");
const { onDocumentWritten } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");
const proxy = require("./aiProxy").internals;
// The website (aieasyplate.app/app) calls this from the browser too.
const { ORIGINS } = require("./origins");

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

// Pure: the seats the owner's plan pays for now, against the members the
// household has. Null when the plan lapsed (the inherited entitlements
// already turn every member off) or is itself inherited. A downgrade —
// Family to Duo, or to a single-seat Pro — never removes anyone: the owner
// chooses who leaves. Until then the household is `overSeats` and takes no
// one new (join refuses it as full).
function seatCheck(data, ownerEnt, nowMs = Date.now()) {
  if (!entitlementActive(ownerEnt, nowMs) || ownerEnt.source === "household") return null;
  const tier = tierOf(ownerEnt.productId);
  const seats = seatsFor(tier);
  const members = ((data && data.memberUids) || []).length;
  return { seats, overSeats: members > seats, ...(tier === "pro" ? {} : { tier }) };
}

async function householdOf(db, uid) {
  const snap = await db.collection("households").where("memberUids", "array-contains", uid).limit(1).get();
  return snap.empty ? null : snap.docs[0];
}

// Each member's inherited document is written in a transaction that reads
// the household again and finds them still in it: the roster this trigger
// started from may be stale by the time it writes, and a member who left
// (or was removed, or whose household was dissolved) in between would get
// premium back with nothing left to take it away.
async function syncMembers(db, householdSnap, ownerEnt) {
  const data = householdSnap.data();
  const now = Date.now();
  let writes = 0;
  for (const memberUid of data.memberUids || []) {
    if (memberUid === data.ownerUid) continue;
    const ref = db.collection("entitlements").doc(memberUid);
    const wrote = await db.runTransaction(async (tx) => {
      const fresh = await tx.get(householdSnap.ref);
      if (!fresh.exists || !(fresh.get("memberUids") || []).includes(memberUid)) return false;
      const memberEnt = (await tx.get(ref)).data();
      if (!mayInherit(memberEnt, now)) return false;
      tx.set(ref, { ...inheritedEntitlement(ownerEnt, householdSnap.id, now), updatedAt: admin.firestore.FieldValue.serverTimestamp() }, { merge: true });
      return true;
    });
    if (wrote) writes++;
  }
  return writes;
}

// Pure: what a member whose own subscription just ran out gets back from
// their household, or null. Only when the owner's plan is live and the
// member's document may be replaced (mayInherit: their own ran out).
function regainedEntitlement(ownerEnt, memberEnt, householdId, nowMs = Date.now()) {
  if (!entitlementActive(ownerEnt, nowMs) || ownerEnt.source === "household") return null;
  if (!mayInherit(memberEnt, nowMs)) return null;
  return inheritedEntitlement(ownerEnt, householdId, nowMs);
}

// A member's own subscription lapsed (or its document was removed): the
// household's Premium comes back. The joining write skipped them while
// their own was live, and nothing else would rewrite it until the owner's
// entitlement next moved. One transaction: still a member, the owner's
// document as it is now, their own still lapsed.
async function restoreInherited(db, memberUid) {
  const household = await householdOf(db, memberUid);
  if (!household || household.get("ownerUid") === memberUid) return false;
  const ownerUid = household.get("ownerUid");
  const ref = db.collection("entitlements").doc(memberUid);
  return db.runTransaction(async (tx) => {
    const fresh = await tx.get(household.ref);
    if (!fresh.exists || !(fresh.get("memberUids") || []).includes(memberUid) || fresh.get("ownerUid") !== ownerUid) return false;
    const ownerEnt = (await tx.get(db.collection("entitlements").doc(ownerUid))).data();
    const memberEnt = (await tx.get(ref)).data();
    const doc = regainedEntitlement(ownerEnt, memberEnt, household.id);
    if (!doc) return false;
    tx.set(ref, { ...doc, updatedAt: admin.firestore.FieldValue.serverTimestamp() }, { merge: true });
    return true;
  });
}

// The seats the owner's plan pays for, against the roster as it is when
// written (a removal that just cleared `overSeats` is not undone by a
// trigger that read the roster before it).
async function syncSeats(db, ref, ownerEnt) {
  return db.runTransaction(async (tx) => {
    const fresh = await tx.get(ref);
    if (!fresh.exists) return null;
    const data = fresh.data();
    const seats = seatCheck(data, ownerEnt);
    if (!seats || (seats.seats === data.seats && seats.overSeats === (data.overSeats === true) && !(seats.tier && seats.tier !== data.tier))) return null;
    tx.update(ref, { ...seats, updatedAt: admin.firestore.FieldValue.serverTimestamp() });
    return { ...seats, members: (data.memberUids || []).length };
  });
}

// One transaction from "not in a household yet" to the new document: two
// taps on "create" at once (or two devices) used to read no membership
// each and open two households for one owner, with the app following
// whichever the query returned first.
async function create(db, uid, title) {
  const ref = db.collection("households").doc();
  return db.runTransaction(async (tx) => {
    const elsewhere = await tx.get(db.collection("households").where("memberUids", "array-contains", uid).limit(1));
    if (!elsewhere.empty) return { error: "in_household" };
    const ent = (await tx.get(db.collection("entitlements").doc(uid))).data();
    const tier = householdTierFor(ent);
    if (!tier) return { error: "not_eligible" };
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
    tx.set(ref, data);
    return { household: publicHousehold(ref.id, data) };
  });
}

// Called by shareCodes.redeem for a code of kind household. Inside the
// caller's transaction when one is given, so the seat count read here is
// the one the write lands on: two people redeeming the last seat at once
// used to both get in. `issuerUid` is who wrote the code: a household is
// the owner's to open, and a member who knows the id must not be able to
// seat strangers on the owner's plan.
async function join(db, householdId, uid, { tx = null, issuerUid = null } = {}) {
  const read = (target) => (tx ? tx.get(target) : target.get());
  const ref = db.collection("households").doc(householdId);
  const snap = await read(ref);
  if (!snap.exists) return { error: "gone" };
  const data = snap.data();
  if (issuerUid && data.ownerUid !== issuerUid) return { error: "gone" };
  if ((data.memberUids || []).includes(uid)) return { already: true, household: publicHousehold(snap.id, data) };
  if (data.overSeats === true) return { error: "full" };
  const elsewhere = await read(db.collection("households").where("memberUids", "array-contains", uid).limit(1));
  if (!elsewhere.empty) return { error: "in_household" };
  if ((data.memberUids || []).length >= (data.seats || 1)) return { error: "full" };
  const ownerEnt = (await read(db.collection("entitlements").doc(data.ownerUid))).data();
  if (!householdTierFor(ownerEnt)) return { error: "not_eligible" };
  const entRef = db.collection("entitlements").doc(uid);
  const memberEnt = (await read(entRef)).data();

  const writer = tx || db.batch();
  writer.update(ref, {
    memberUids: admin.firestore.FieldValue.arrayUnion(uid),
    [`members.${uid}`]: { joinedAt: admin.firestore.Timestamp.now(), role: "member" },
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  if (mayInherit(memberEnt)) {
    writer.set(entRef, { ...inheritedEntitlement(ownerEnt, snap.id), updatedAt: admin.firestore.FieldValue.serverTimestamp() }, { merge: true });
  }
  if (!tx) await writer.commit();
  return { household: publicHousehold(snap.id, { ...data, memberUids: [...(data.memberUids || []), uid] }) };
}

// One transaction from the membership read to the write: the roster, the
// seat count behind `overSeats` and the member's entitlement are the ones
// the update lands on. A leave racing a removal (or a redeem, or a
// downgrade's seat check) used to read a roster another write had already
// changed, and could clear `overSeats` on a household still over its seats.
// `check(data)` returns a refusal, or nothing to go ahead.
async function removeMember(db, lookupUid, memberUid, check) {
  return db.runTransaction(async (tx) => {
    const found = await tx.get(db.collection("households").where("memberUids", "array-contains", lookupUid).limit(1));
    const snap = found.empty ? null : found.docs[0];
    const refusal = check(snap ? snap.data() || {} : null);
    if (refusal) return refusal;
    const data = snap.data() || {};
    const entRef = db.collection("entitlements").doc(memberUid);
    const ent = (await tx.get(entRef)).data();
    const remaining = (data.memberUids || []).filter((m) => m !== memberUid).length;
    tx.update(snap.ref, {
      memberUids: admin.firestore.FieldValue.arrayRemove(memberUid),
      [`members.${memberUid}`]: admin.firestore.FieldValue.delete(),
      // Back within the plan's seats: the household takes new members again.
      ...(data.overSeats === true && remaining <= (data.seats || 1) ? { overSeats: false } : {}),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    if (ent && ent.source === "household") {
      tx.set(entRef, { ...releasedEntitlement(), updatedAt: admin.firestore.FieldValue.serverTimestamp() }, { merge: true });
    }
    return { ok: true };
  });
}

async function leave(db, uid) {
  return removeMember(db, uid, uid, (data) => {
    if (!data) return { error: "not_member" };
    if (data.ownerUid === uid) return { error: "owner_cannot_leave" };
    return null;
  });
}

async function remove(db, uid, memberUid) {
  return removeMember(db, uid, memberUid, (data) => {
    if (!data || data.ownerUid !== uid) return { error: "not_owner" };
    if (memberUid === uid) return { error: "owner_cannot_leave" };
    if (!(data.memberUids || []).includes(memberUid)) return { error: "not_member" };
    return null;
  });
}

// The owner closes the household: members lose the inherited entitlement,
// the document and every mirrored collection under it are deleted. The
// owner's own device still holds the data and pushes it back to its own
// root (the app rehomes without wiping for the owner).
//
// The roster is read, every member released and the document deleted in
// one transaction: a code redeemed at the same moment (shareCodes.redeem
// joins inside its own transaction) either lands first and is released
// here, or finds the household gone. The mirrored collections under it go
// afterwards; nothing can join a document that no longer exists.
async function dissolve(db, uid) {
  const found = await householdOf(db, uid);
  if (!found || found.get("ownerUid") !== uid) return { error: "not_owner" };
  const ref = found.ref;
  const result = await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) return { ok: true };
    if (snap.get("ownerUid") !== uid) return { error: "not_owner" };
    const memberUids = (snap.get("memberUids") || []).filter((m) => m !== uid);
    const entRefs = memberUids.map((m) => db.collection("entitlements").doc(m));
    const ents = entRefs.length ? await tx.getAll(...entRefs) : [];
    ents.forEach((entSnap, i) => {
      const ent = entSnap.exists ? entSnap.data() : null;
      if (ent && ent.source === "household") {
        tx.set(entRefs[i], { ...releasedEntitlement(), updatedAt: admin.firestore.FieldValue.serverTimestamp() }, { merge: true });
      }
    });
    tx.delete(ref);
    return { ok: true };
  });
  if (result.error) return result;
  await db.recursiveDelete(ref);
  return { ok: true };
}

// A member's own Premium that simply ran out — an administrator's grant
// (adminLock) with a premiumUntil, or any plan whose end date passed with
// no webhook write — never fired onOwnerEntitlementChanged (nothing was
// written), so the household's Premium did not come back until the owner's
// document next moved. Once a day: the entitlements that ended in the last
// LAPSE_WINDOW_MS (a missed run is covered by the next), each member handed
// to restoreInherited, which re-checks everything in its transaction.
// premiumUntil alone is queried (its automatic index; no composite needed).
const LAPSE_WINDOW_MS = 2 * 24 * 60 * 60 * 1000;
const LAPSE_PAGE = 300;

async function restoreLapsed(db, { now = Date.now(), restore = restoreInherited, page = LAPSE_PAGE } = {}) {
  const from = admin.firestore.Timestamp.fromMillis(now - LAPSE_WINDOW_MS);
  const to = admin.firestore.Timestamp.fromMillis(now);
  let cursor = null;
  let restored = 0;
  let seen = 0;
  for (;;) {
    let query = db.collection("entitlements").where("premiumUntil", ">", from).where("premiumUntil", "<=", to).orderBy("premiumUntil").limit(page);
    if (cursor) query = query.startAfter(cursor);
    const snap = await query.get();
    for (const doc of snap.docs) {
      seen++;
      const ent = doc.data();
      if (ent.source === "household" || entitlementActive(ent, now)) continue;
      try {
        if (await restore(db, doc.id)) restored++;
      } catch (err) {
        logger.warn("household premium not restored", { uid: doc.id, reason: err.message });
      }
    }
    if (snap.size < page) break;
    cursor = snap.docs[snap.docs.length - 1];
  }
  return { seen, restored };
}

exports.restoreHouseholdPremium = onSchedule(
  { schedule: "every day 04:25", timeZone: "Asia/Jerusalem", region: "europe-west1", retryCount: 1, timeoutSeconds: 300 },
  async () => {
    const out = await restoreLapsed(admin.firestore());
    logger.info("lapsed entitlements checked for household premium", out);
  },
);

exports.internals = { restoreLapsed, LAPSE_WINDOW_MS, seatCheck, tierOf, seatsFor, entitlementActive, householdTierFor, inheritedEntitlement, mayInherit, regainedEntitlement, restoreInherited, releasedEntitlement, publicHousehold, join, create, leave, remove, dissolve, syncMembers, syncSeats };

const STATUS = { in_household: 409, not_eligible: 403, gone: 404, full: 409, not_member: 404, not_owner: 403, owner_cannot_leave: 409 };

exports.households = onRequest(
  { region: "europe-west1", cors: ORIGINS, maxInstances: 5 },
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
      // The plan may now pay for fewer (or more) seats than are taken.
      const seats = await syncSeats(db, snap.ref, ent);
      if (seats && seats.overSeats) logger.warn("household over its seats", { householdId: snap.id, seats: seats.seats, members: seats.members });
    }
    // Their own ran out: a member falls back on the household's Premium.
    if (owned.empty && !entitlementActive(ent)) {
      if (await restoreInherited(db, uid)) logger.info("household entitlement restored after a lapse", { uid });
    }
  },
);
