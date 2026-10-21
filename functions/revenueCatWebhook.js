// RevenueCat → Firestore. RevenueCat posts one event per subscription change
// and this writes the verdict onto `entitlements/{uid}`, the document the app
// follows (lib/core/monetization/entitlement_service.dart). The client can
// read that document but never write it, which is the whole point: an
// entitlement the owner could grant themselves is not one.
//
// Setup, once: in the RevenueCat dashboard (Project → Integrations → Webhooks)
// point the URL at this function and set the Authorization header to the
// value stored in the REVENUECAT_WEBHOOK_AUTH secret:
//   firebase functions:secrets:set REVENUECAT_WEBHOOK_AUTH
//
// Web Premium sold outside Israel arrives here too (decision of 2026-10-18):
// RevenueCat's Paddle Billing integration reports those purchases with
// store PADDLE and the Firebase uid as app_user_id (the Web Purchase Link
// carries it). Their product_id is RevenueCat's id for the imported Paddle
// price (pri_…), which names no household tier, so it is mapped back to the
// plan id in `web_billing_catalog` (revenuecat.plans[].productId) before it
// is stored as productId; the raw id is kept as storeProductId.
const crypto = require("node:crypto");
const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const admin = require("firebase-admin");
const catalogs = require("./billingCatalog");

const webhookAuth = defineSecret("REVENUECAT_WEBHOOK_AUTH");

// Must match PurchasesConfig.premiumEntitlementId in the app and the
// entitlement identifier in the RevenueCat dashboard.
const PREMIUM_ENTITLEMENT = "easy_plate_ai_pro";

// Every event, verbatim in the fields that matter, for the administrator's
// subscriptions screen: who paid, under which id, and whether the entitlement
// was on the receipt. Written whatever `decide` makes of the event, so a
// purchase the mapping ignored (a product not attached to the entitlement,
// an anonymous receipt) is still there to be seen and fixed.
const EVENTS_COLLECTION = "purchase_events";

// Event types after which the account is *not* premium. Everything else that
// names the entitlement (INITIAL_PURCHASE, RENEWAL, PRODUCT_CHANGE,
// UNCANCELLATION, NON_RENEWING_PURCHASE, BILLING_ISSUE during grace,
// CANCELLATION — which only turns auto-renew off — …) keeps it, bounded by
// expiration_at_ms, which the app already treats as the real cut-off.
const REVOKING = new Set(["EXPIRATION"]);

// RevenueCat's own ids for a device that never logged in. The app always logs
// in with the Firebase uid, so one of these means a receipt with no account —
// there is no document to write, and the next event after logIn carries the
// real uid.
//
// An id that cannot be a Firestore document id (a slash makes it a path,
// "." / ".." / `__…__` are refused) is no Firebase uid either: treated as
// anonymous, so the event is acknowledged instead of failing with a 500
// that RevenueCat would retry for days.
const isAnonymous = (id) =>
  typeof id !== "string" || id.startsWith("$RCAnonymousID:") || id === "" ||
  id.length > 128 || id.includes("/") || id === "." || id === ".." || /^__.*__$/.test(id);

// Which Firebase uid an event is about, or null when there is none.
function uidFor(event) {
  if (!isAnonymous(event.app_user_id)) return event.app_user_id;
  for (const alias of event.aliases || []) {
    if (!isAnonymous(alias)) return alias;
  }
  return null;
}

// Whether an event is a web purchase (Paddle through RevenueCat, or
// RevenueCat's own billing) rather than a store one.
const isWebStore = (store) => catalogs.RC_WEB_STORES.has(String(store || "").toUpperCase());

// Pure: the product id to store — for a web store, the catalogue's plan id
// (which names the tier) when the RevenueCat product is listed there.
function productFor(event, catalog) {
  const raw = String(event.product_id || "");
  if (!isWebStore(event.store) || !catalog) return { productId: raw, storeProductId: null };
  const plan = catalogs.planByStoreProduct(catalog, raw);
  return plan ? { productId: plan.planId, storeProductId: raw } : { productId: raw, storeProductId: null };
}

// Pure: a refund of the latest period. RevenueCat reports it as a
// CANCELLATION with cancel_reason CUSTOMER_SUPPORT and a negative price
// (revenuecat.com/docs/integrations/webhooks/event-types-and-fields).
function isRefund(event) {
  if (event.type !== "CANCELLATION" || event.cancel_reason !== "CUSTOMER_SUPPORT") return false;
  const price = Number(event.price ?? event.price_in_purchased_currency);
  return Number.isFinite(price) && price < 0;
}

// Turns one event into the writes it implies: a list of {uid, data}. Pure,
// so the mapping is testable without Firestore. [catalog] (the parsed
// web_billing_catalog) maps web product ids to plan ids.
function decide(event, now = Date.now(), { catalog = null } = {}) {
  if (!event || typeof event !== "object") return [];
  const at = Number(event.event_timestamp_ms) || now;
  const base = {
    source: "revenuecat",
    lastEventType: String(event.type || ""),
    lastEventId: String(event.id || ""),
    lastEventAt: at,
    environment: String(event.environment || ""),
  };

  // The dashboard's "send test event" button: acknowledge, write nothing.
  if (event.type === "TEST") return [];

  // A receipt moved between accounts (the same store account signed into a
  // second Firebase account and restored). The old account loses it now; the
  // new one is unlocked by the next event, and by the SDK on that device
  // meanwhile (EntitlementService merges both sources).
  if (event.type === "TRANSFER") {
    return (event.transferred_from || [])
      .filter((id) => !isAnonymous(id))
      .map((uid) => ({ uid, data: { ...base, premium: false, premiumUntil: null } }));
  }

  const uid = uidFor(event);
  if (!uid) return [];
  const ids = Array.isArray(event.entitlement_ids) ? event.entitlement_ids : [];
  if (!ids.includes(PREMIUM_ENTITLEMENT)) return [];

  // The store rides on revocations too, so one store's end does not undo a
  // plan still live in another (revokesAnotherSource).
  const store = String(event.store || "");
  if (REVOKING.has(event.type) || isRefund(event)) {
    return [{ uid, data: { ...base, store, premium: false, premiumUntil: null, cancelAtPeriodEnd: false } }];
  }
  const expiresMs = Number(event.expiration_at_ms);
  const { productId, storeProductId } = productFor(event, catalog);
  const data = {
    ...base,
    premium: true,
    // Lifetime / non-renewing purchases carry no expiry: premium stays
    // until an explicit revoke.
    premiumUntil: Number.isFinite(expiresMs) && expiresMs > 0 ? new Date(expiresMs) : null,
    productId,
    store,
  };
  if (storeProductId) data.storeProductId = storeProductId;
  // Auto-renew off (CANCELLATION) / back on: the website says "ends on"
  // rather than "renews on".
  if (event.type === "CANCELLATION") data.cancelAtPeriodEnd = true;
  else if (["INITIAL_PURCHASE", "RENEWAL", "UNCANCELLATION", "PRODUCT_CHANGE"].includes(event.type)) data.cancelAtPeriodEnd = false;
  return [{ uid, data }];
}

// The audit row for one event. Pure, like `decide`.
function eventRecord(event, now = Date.now(), { catalog = null } = {}) {
  if (!event || typeof event !== "object" || event.type === "TEST") return null;
  const at = Number(event.event_timestamp_ms) || now;
  const expiresMs = Number(event.expiration_at_ms);
  const price = Number(event.price_in_purchased_currency);
  return {
    // The document id: a slash in RevenueCat's id would make it a path.
    id: String(event.id || `${event.type || "event"}-${at}`).replace(/\//g, "_").slice(0, 200),
    data: {
      type: String(event.type || ""),
      appUserId: String(event.app_user_id || ""),
      aliases: (event.aliases || []).map(String),
      uid: uidFor(event),
      productId: String(event.product_id || ""),
      planId: isWebStore(event.store) ? productFor(event, catalog).productId : null,
      store: String(event.store || ""),
      cancelReason: String(event.cancel_reason || ""),
      entitlementIds: Array.isArray(event.entitlement_ids) ? event.entitlement_ids.map(String) : [],
      grantsPremium: Array.isArray(event.entitlement_ids) && event.entitlement_ids.includes(PREMIUM_ENTITLEMENT),
      environment: String(event.environment || ""),
      periodType: String(event.period_type || ""),
      eventAt: new Date(at),
      expiresAt: Number.isFinite(expiresMs) && expiresMs > 0 ? new Date(expiresMs) : null,
      price: Number.isFinite(price) ? price : null,
      currency: String(event.currency || ""),
    },
  };
}

function authorized(header, secret) {
  if (typeof header !== "string" || !secret) return false;
  // RevenueCat sends the header verbatim; accept it with or without a
  // "Bearer " prefix so either dashboard convention works.
  const presented = header.replace(/^Bearer\s+/i, "");
  const a = Buffer.from(presented);
  const b = Buffer.from(secret);
  return a.length === b.length && crypto.timingSafeEqual(a, b);
}

// Applies one write unless a newer event already landed on the document —
// RevenueCat retries and can deliver out of order, and a stale EXPIRATION
// must not undo a fresh RENEWAL.
/// Whether an administrator's dated grant is over, so its lock lapsed too.
function lockExpired(premiumUntil, nowMs) {
  return !!premiumUntil && typeof premiumUntil.toMillis === "function" && premiumUntil.toMillis() <= nowMs;
}

// Pure: whether a revocation from one source would end premium another
// source still holds. One store's cancellation must not wipe a live plan
// bought in the other (web after App Store, or the reverse), nor premium
// inherited from a household or granted by the administrator: each source
// ends its own. A grant is live while it is on and its end, if any, is
// still ahead.
//
// RevenueCat speaks for several stores under one source: an App Store plan
// and a Paddle (web) plan are both "revenuecat". When both sides name their
// store and the stores differ, they count as different sources too.
function revokesAnotherSource(stored, data, nowMs) {
  if (!stored || data.premium !== false || stored.premium !== true) return false;
  if (!stored.source) return false;
  if (stored.source === data.source) {
    const a = String(stored.store || "").toUpperCase();
    const b = String(data.store || "").toUpperCase();
    if (!(stored.source === "revenuecat" && a && b && a !== b)) return false;
  }
  const until = stored.premiumUntil;
  return !(until && typeof until.toMillis === "function" && until.toMillis() <= nowMs);
}

// Inside a transaction that already read [snap] (entitlements/{uid}):
// writes [data] unless it is older than what is stored, the administrator
// holds the account, or it would revoke Premium another source grants.
// Shared with the Stripe webhook, which runs it in the same transaction as
// its customer merge so two deliveries cannot land in the wrong order.
function applyInTransaction(tx, ref, snap, data) {
  const seenAt = snap.exists ? Number(snap.get("lastEventAt")) || 0 : 0;
  if (seenAt > data.lastEventAt) return false;
  // The administrator set this account by hand; the store's verdict waits
  // until they release it (see the admin subscriptions screen).
  // A dated grant that has run out no longer holds the lock: a gifted
  // week must not stop a later real purchase from unlocking.
  if (snap.exists && snap.get("adminLock") === true && !lockExpired(snap.get("premiumUntil"), Date.now())) return false;
  if (snap.exists && revokesAnotherSource(snap.data(), data, Date.now())) return false;
  tx.set(
    ref,
    {
      ...data,
      premiumFrom: null,
      adminLock: false,
      premiumUntil: data.premiumUntil
        ? admin.firestore.Timestamp.fromDate(data.premiumUntil)
        : null,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
  return true;
}

async function apply(db, { uid, data }) {
  const ref = db.collection("entitlements").doc(uid);
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    applyInTransaction(tx, ref, snap, data);
  });
}

exports.revenueCatWebhook = onRequest(
  {
    region: "europe-west1",
    secrets: [webhookAuth],
    // Webhooks are rare and tiny; never worth a warm instance.
    minInstances: 0,
    maxInstances: 5,
    timeoutSeconds: 30,
  },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).send("POST only");
      return;
    }
    if (!authorized(req.get("authorization"), webhookAuth.value())) {
      res.status(401).send("unauthorized");
      return;
    }
    const event = req.body && req.body.event;
    if (!event) {
      res.status(400).send("no event");
      return;
    }
    try {
      // A web purchase's product id is mapped through the catalogue. A
      // Remote Config failure throws: RevenueCat retries, rather than the
      // entitlement landing with the wrong household tier.
      const catalog = isWebStore(event.store) ? (await catalogs.load()).catalog : null;
      const writes = decide(event, Date.now(), { catalog });
      const db = admin.firestore();
      const record = eventRecord(event, Date.now(), { catalog });
      if (record) {
        await db.collection(EVENTS_COLLECTION).doc(record.id).set(
          {
            ...record.data,
            eventAt: admin.firestore.Timestamp.fromDate(record.data.eventAt),
            expiresAt: record.data.expiresAt
              ? admin.firestore.Timestamp.fromDate(record.data.expiresAt)
              : null,
            receivedAt: admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true },
        );
      }
      for (const write of writes) await apply(db, write);
      res.status(200).json({ ok: true, writes: writes.length });
    } catch (e) {
      console.error("revenueCatWebhook failed", e);
      // Non-2xx makes RevenueCat retry with backoff, which is what we want
      // for a transient Firestore failure.
      res.status(500).send("failed");
    }
  },
);

// `apply` is shared with stripeWebhook.js: a web purchase lands on the same
// document under the same out-of-order and admin-lock rules.
exports.internals = { isAnonymous, lockExpired, revokesAnotherSource, decide, eventRecord, authorized, uidFor, apply, applyInTransaction, productFor, isRefund, isWebStore, PREMIUM_ENTITLEMENT };
