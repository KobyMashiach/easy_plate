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
const crypto = require("node:crypto");
const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const admin = require("firebase-admin");

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
const isAnonymous = (id) => typeof id !== "string" || id.startsWith("$RCAnonymousID:") || id === "";

// Which Firebase uid an event is about, or null when there is none.
function uidFor(event) {
  if (!isAnonymous(event.app_user_id)) return event.app_user_id;
  for (const alias of event.aliases || []) {
    if (!isAnonymous(alias)) return alias;
  }
  return null;
}

// Turns one event into the writes it implies: a list of {uid, data}. Pure,
// so the mapping is testable without Firestore.
function decide(event, now = Date.now()) {
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

  if (REVOKING.has(event.type)) {
    return [{ uid, data: { ...base, premium: false, premiumUntil: null } }];
  }
  const expiresMs = Number(event.expiration_at_ms);
  return [
    {
      uid,
      data: {
        ...base,
        premium: true,
        // Lifetime / non-renewing purchases carry no expiry: premium stays
        // until an explicit revoke.
        premiumUntil: Number.isFinite(expiresMs) && expiresMs > 0 ? new Date(expiresMs) : null,
        productId: String(event.product_id || ""),
        store: String(event.store || ""),
      },
    },
  ];
}

// The audit row for one event. Pure, like `decide`.
function eventRecord(event, now = Date.now()) {
  if (!event || typeof event !== "object" || event.type === "TEST") return null;
  const at = Number(event.event_timestamp_ms) || now;
  const expiresMs = Number(event.expiration_at_ms);
  const price = Number(event.price_in_purchased_currency);
  return {
    id: String(event.id || `${event.type || "event"}-${at}`),
    data: {
      type: String(event.type || ""),
      appUserId: String(event.app_user_id || ""),
      aliases: (event.aliases || []).map(String),
      uid: uidFor(event),
      productId: String(event.product_id || ""),
      store: String(event.store || ""),
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
async function apply(db, { uid, data }) {
  const ref = db.collection("entitlements").doc(uid);
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const seenAt = snap.exists ? Number(snap.get("lastEventAt")) || 0 : 0;
    if (seenAt > data.lastEventAt) return;
    // The administrator set this account by hand; the store's verdict waits
    // until they release it (see the admin subscriptions screen).
    if (snap.exists && snap.get("adminLock") === true) return;
    tx.set(
      ref,
      {
        ...data,
        premiumUntil: data.premiumUntil
          ? admin.firestore.Timestamp.fromDate(data.premiumUntil)
          : null,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
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
      const writes = decide(event);
      const db = admin.firestore();
      const record = eventRecord(event);
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

exports.internals = { decide, eventRecord, authorized, uidFor, PREMIUM_ENTITLEMENT };
