// The one writer for a web subscription bought through PayPlus or Paddle:
// `web_customers/{uid}` (what the website shows: provider, status, period,
// whether it cancels) and `entitlements/{uid}` (what the app and the website
// unlock on), in one transaction with a per-event marker, so
//   - a webhook delivered twice is applied once (billing_events/{provider}_{id}),
//   - an older event arriving late loses (per subscription, then the shared
//     applyInTransaction rule on the entitlement),
//   - the administrator's lock, another source's live grant and a second
//     subscription paid by mistake are respected — the same rules RevenueCat
//     and Stripe already follow (revenueCatWebhook.applyInTransaction).
//
// Both webhooks reduce their events to one shape before calling apply():
//   { provider, eventId, eventType, at, subscriptionId, status, planId,
//     periodEndMs, cancelAtPeriodEnd, revoke, customer: {…ids}, environment }
// status ∈ active | trialing | past_due | paused | canceled | refunded.
const admin = require("firebase-admin");
const revenueCat = require("./revenueCatWebhook").internals;

const CUSTOMERS = "web_customers";
const MARKERS = "billing_events";
const ON = new Set(["active", "trialing", "past_due"]);
// After a period's end, how long Premium waits for the renewal's verdict:
// PayPlus retries a failed recurring charge daily and tells us only about
// successes, so a short grace stands in for Stripe's past_due; Paddle sends
// past_due / canceled itself.
const GRACE_MS = { payplus: 3 * 86_400_000, paddle: 86_400_000 };

const ms = (v) => (v && typeof v.toMillis === "function" ? v.toMillis() : typeof v === "number" ? v : null);

// Pure: how far along a subscription's life a status is, for a same-instant tie.
function statusRank(status) {
  if (status === "canceled" || status === "refunded") return 2;
  if (ON.has(status)) return 1;
  return 0;
}

// Pure: the instant a stored subscription stops granting Premium.
function grantEndMs(stored) {
  if (!stored) return null;
  const end = ms(stored.currentPeriodEnd);
  if (end === null) return null;
  return end + (stored.cancelAtPeriodEnd === true ? 0 : GRACE_MS[stored.provider] || 0);
}

// Pure: whether the stored subscription is still live (granting Premium).
function storedLive(stored, nowMs = Date.now()) {
  if (!stored || !stored.subscriptionId || !ON.has(String(stored.subscriptionStatus || ""))) return false;
  const end = grantEndMs(stored);
  return end === null || end > nowMs;
}

// Pure: whether an event is about the stored subscription. A PayPlus
// subscription first known by its payment page (no recurring uid yet in the
// first callback) is adopted by the renewal that names the recurring uid
// for the same PayPlus customer.
function sameSubscription(stored, sub) {
  if (!stored || !stored.subscriptionId) return false;
  if (stored.provider !== sub.provider) return false;
  if (stored.subscriptionId === sub.subscriptionId) return true;
  const c = sub.customer || {};
  return sub.provider === "payplus" && String(stored.subscriptionId).startsWith("page:") && !!stored.payplusCustomerUid && stored.payplusCustomerUid === c.payplusCustomerUid;
}

// Pure: (stored web_customers doc, normalised event, now) → what to write.
//   { outcome: "apply" | "stale" | "duplicate" | "ignored", customer, entitlement }
// `duplicate`: a second live subscription for an account that already has
// one — nothing changes here; the webhook cancels the newcomer at the
// provider and the purchase_events row flags it for a refund.
function plan(stored, sub, nowMs = Date.now()) {
  stored = stored || null;
  const live = !sub.revoke && ON.has(sub.status);
  const same = sameSubscription(stored, sub);
  if (stored && stored.subscriptionId && !same && storedLive(stored, nowMs)) {
    return { outcome: live ? "duplicate" : "ignored", customer: null, entitlement: null };
  }
  if (same) {
    const seen = Number(stored.lastEventAt) || 0;
    if (seen > sub.at) return { outcome: "stale", customer: null, entitlement: null };
    if (seen === sub.at && statusRank(String(stored.subscriptionStatus || "")) > statusRank(sub.status)) {
      return { outcome: "stale", customer: null, entitlement: null };
    }
  }
  const planId = sub.planId || (same ? stored.planId : null) || "";
  const periodEndMs = sub.periodEndMs ?? (same ? ms(stored.currentPeriodEnd) : null);
  // A grant with no end would be Premium for ever: a live event that cannot
  // say until when is not applied (the next one with a period will be).
  if (live && !periodEndMs) return { outcome: "ignored", customer: null, entitlement: null };
  const cancelAtPeriodEnd = sub.cancelAtPeriodEnd ?? (same ? stored.cancelAtPeriodEnd === true : false);
  const customer = {
    provider: sub.provider,
    subscriptionId: same && !String(sub.subscriptionId).length ? stored.subscriptionId : sub.subscriptionId,
    subscriptionStatus: sub.status,
    cancelAtPeriodEnd: live ? cancelAtPeriodEnd : false,
    planId,
    currentPeriodEnd: periodEndMs,
    everSubscribed: true,
    lastEventAt: sub.at,
    lastEventType: sub.eventType,
    ...(sub.customer || {}),
  };
  const grace = cancelAtPeriodEnd ? 0 : GRACE_MS[sub.provider] || 0;
  const entitlement = {
    source: sub.provider,
    store: sub.provider,
    premium: live,
    premiumUntil: live && periodEndMs ? new Date(periodEndMs + grace) : null,
    productId: planId,
    subscriptionId: customer.subscriptionId,
    cancelAtPeriodEnd: customer.cancelAtPeriodEnd,
    lastEventType: sub.eventType,
    lastEventId: sub.eventId,
    lastEventAt: sub.at,
    environment: sub.environment || "",
  };
  return { outcome: "apply", customer, entitlement };
}

// Customer-only facts (a Paddle customer id from transaction.completed):
// merged without touching status or the entitlement, never over a newer
// record's ids.
function customerPatch(sub) {
  return { ...(sub.customer || {}), everSubscribed: true };
}

function toFirestore(customer) {
  const out = { ...customer, updatedAt: admin.firestore.FieldValue.serverTimestamp() };
  if (typeof out.currentPeriodEnd === "number") out.currentPeriodEnd = admin.firestore.Timestamp.fromMillis(out.currentPeriodEnd);
  else if (out.currentPeriodEnd === null) out.currentPeriodEnd = null;
  for (const [k, v] of Object.entries(out)) if (v === undefined) delete out[k];
  return out;
}

// Applies one normalised event for `uid`. Returns { outcome, entitlementWritten }.
// `sub.customerOnly` → only customerPatch(sub) is merged.
async function apply(db, uid, sub, { nowMs = Date.now() } = {}) {
  const markerRef = db.collection(MARKERS).doc(`${sub.provider}_${sub.eventId}`.replace(/\//g, "_").slice(0, 300));
  const custRef = db.collection(CUSTOMERS).doc(uid);
  const entRef = db.collection("entitlements").doc(uid);
  return db.runTransaction(async (tx) => {
    const marker = await tx.get(markerRef);
    if (marker.exists) return { outcome: "replayed", entitlementWritten: false };
    const custSnap = await tx.get(custRef);
    const entSnap = await tx.get(entRef);
    const stored = custSnap.exists ? custSnap.data() : null;
    const markerData = { provider: sub.provider, uid, type: sub.eventType, at: sub.at, receivedAt: admin.firestore.FieldValue.serverTimestamp() };
    if (sub.customerOnly) {
      tx.set(custRef, toFirestore(customerPatch(sub)), { merge: true });
      tx.set(markerRef, { ...markerData, outcome: "customer" });
      return { outcome: "customer", entitlementWritten: false };
    }
    const decided = plan(stored, sub, nowMs);
    tx.set(markerRef, { ...markerData, outcome: decided.outcome });
    if (decided.outcome !== "apply") return { outcome: decided.outcome, entitlementWritten: false };
    const customer = { ...decided.customer };
    // A live subscription ends the "checkout started" hold.
    if (decided.entitlement.premium) {
      customer.checkoutPendingUntil = admin.firestore.FieldValue.delete();
      customer.checkoutRef = admin.firestore.FieldValue.delete();
    }
    tx.set(custRef, toFirestore(customer), { merge: true });
    const wrote = revenueCat.applyInTransaction(tx, entRef, entSnap, decided.entitlement);
    return { outcome: "apply", entitlementWritten: wrote, entitlement: decided.entitlement };
  });
}

// A server-side change of our own (PayPlus "cancel at period end" from the
// manage action): the same writer with a synthetic event.
async function applyLocal(db, uid, sub, opts) {
  return apply(db, uid, { ...sub, eventId: sub.eventId || `local_${sub.subscriptionId}_${sub.at}` }, opts);
}

// The uid that owns a provider-side id, from our own records.
async function uidBy(db, field, value) {
  if (!value) return null;
  const snap = await db.collection(CUSTOMERS).where(field, "==", value).limit(1).get();
  return snap.empty ? null : snap.docs[0].id;
}

// Whether a Firebase uid still exists: a deleted account's late webhook
// writes an audit row only (as stripeWebhook.js does).
async function authUserExists(uid) {
  try {
    await admin.auth().getUser(uid);
    return true;
  } catch (err) {
    return err.code !== "auth/user-not-found";
  }
}

// The audit row for the administrator's subscriptions screen (purchase_events,
// the collection RevenueCat and Stripe rows already live in).
async function audit(db, provider, sub, uid, extra = {}) {
  const id = `${provider}_${sub.eventId}`.replace(/\//g, "_").slice(0, 300);
  await db.collection("purchase_events").doc(id).set(
    {
      type: sub.eventType,
      appUserId: uid || "",
      aliases: [],
      uid: uid || null,
      productId: sub.planId || "",
      store: provider,
      entitlementIds: !sub.revoke && ON.has(sub.status) ? [revenueCat.PREMIUM_ENTITLEMENT] : [],
      grantsPremium: !sub.revoke && ON.has(sub.status),
      environment: sub.environment || "",
      periodType: sub.status === "trialing" ? "TRIAL" : "NORMAL",
      eventAt: admin.firestore.Timestamp.fromMillis(sub.at),
      expiresAt: sub.periodEndMs ? admin.firestore.Timestamp.fromMillis(sub.periodEndMs) : null,
      price: typeof sub.amount === "number" ? sub.amount : null,
      currency: sub.currency || "",
      subscriptionId: sub.subscriptionId || null,
      status: sub.status || "",
      receivedAt: admin.firestore.FieldValue.serverTimestamp(),
      ...extra,
    },
    { merge: true },
  );
}

module.exports = { CUSTOMERS, MARKERS, ON, GRACE_MS, statusRank, grantEndMs, storedLive, sameSubscription, plan, apply, applyLocal, uidBy, authUserExists, audit, toFirestore };
