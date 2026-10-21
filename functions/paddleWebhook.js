// RETIRED 2026-10-18 — not exported from index.js, so not deployed. Web
// Premium outside Israel now goes through RevenueCat's Paddle Billing
// integration: RevenueCat owns the Paddle notification destination and
// reports Paddle purchases through revenueCatWebhook.js (store PADDLE).
// Exporting this again would grant the same purchase twice. Kept for
// reference only.
//
// Paddle → Firestore. Paddle (merchant of record for web Premium outside
// Israel) posts one notification per event to this URL. Each is verified
// (Paddle-Signature: ts;h1 = HMAC-SHA256 of `${ts}:${rawBody}` with the
// destination's secret, 5-minute window), applied once per event_id
// (billing_events), and mapped onto entitlements/{uid} through the shared
// writer (webEntitlement.js → revenueCatWebhook.applyInTransaction):
//   subscription.created / activated / updated / trialing / resumed
//                         → active or trialing, Premium to current_billing_period.ends_at
//   subscription.past_due → past_due: Paddle is retrying; Premium keeps its end
//   subscription.paused   → off
//   subscription.canceled → off (scheduled_change "cancel" before that only
//                           marks cancelAtPeriodEnd)
//   adjustment.created / adjustment.updated, action refund (full, approved)
//                         or chargeback → refunded: off now, and the
//                           subscription is cancelled at Paddle
//   transaction.completed → remembers the Paddle customer id (for the portal)
// The uid travels as the transaction's custom_data, which Paddle copies onto
// the subscription it creates.
//
// Setup, once (Paddle > Developer tools > Notifications): a destination with
// this URL (https://europe-west1-easy-plate.cloudfunctions.net/paddleWebhook)
// and the events above; its secret key goes into PADDLE_WEBHOOK_SECRET.
const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");
const paddle = require("./paddleClient");
const catalogs = require("./billingCatalog");
const web = require("./webEntitlement");

const { paddleApiKey: apiKey } = require("./billingSecrets");
const webhookSecret = defineSecret("PADDLE_WEBHOOK_SECRET");

const UID = /^[A-Za-z0-9]{10,128}$/;
const iso = (v) => {
  const t = typeof v === "string" ? Date.parse(v) : NaN;
  return Number.isFinite(t) ? t : null;
};

function uidOf(data) {
  const uid = data && data.custom_data && data.custom_data.uid;
  return typeof uid === "string" && UID.test(uid) ? uid : null;
}

function firstPriceId(sub) {
  const item = sub && Array.isArray(sub.items) ? sub.items[0] : null;
  return (item && item.price && item.price.id) || (item && item.price_id) || null;
}

// Pure: one notification → { uid?, lookup?, sub } or null (audit only).
// `lookup` names how to find the account when custom_data has no uid.
function decide(event, { catalog = { paddle: { plans: [] } }, nowMs = Date.now() } = {}) {
  if (!event || typeof event !== "object" || !event.event_id) return null;
  const type = String(event.event_type || "");
  const data = event.data || {};
  const at = iso(event.occurred_at) || nowMs;
  const environment = catalog.paddle && catalog.paddle.environment === "sandbox" ? "SANDBOX" : "PRODUCTION";
  const base = { provider: "paddle", eventId: String(event.event_id), eventType: type, at, environment };

  if (type.startsWith("subscription.")) {
    const status = String(data.status || "");
    const priceId = firstPriceId(data);
    const byPrice = priceId ? catalogs.planByPaddlePrice(catalog, priceId) : null;
    const customPlan = data.custom_data && typeof data.custom_data.plan_id === "string" && catalogs.PLAN_ID.test(data.custom_data.plan_id) ? data.custom_data.plan_id : null;
    const planId = (byPrice && byPrice.planId) || customPlan || null;
    const period = data.current_billing_period || null;
    const revoke = status === "canceled" || status === "paused";
    return {
      uid: uidOf(data),
      lookup: { field: "subscriptionId", value: data.id || null },
      sub: {
        ...base,
        subscriptionId: String(data.id || ""),
        status: status === "paused" ? "paused" : status,
        planId,
        periodEndMs: revoke ? null : iso(period && period.ends_at),
        cancelAtPeriodEnd: !!(data.scheduled_change && data.scheduled_change.action === "cancel"),
        revoke,
        currency: String(data.currency_code || ""),
        customer: data.customer_id ? { paddleCustomerId: String(data.customer_id) } : {},
      },
    };
  }

  if (type === "adjustment.created" || type === "adjustment.updated") {
    const action = String(data.action || "");
    const refund = action === "refund" && data.status === "approved" && data.type === "full";
    const chargeback = action === "chargeback";
    if (!(refund || chargeback) || !data.subscription_id) return null;
    return {
      uid: null,
      lookup: { field: "subscriptionId", value: String(data.subscription_id) },
      sub: { ...base, subscriptionId: String(data.subscription_id), status: "refunded", planId: null, periodEndMs: null, cancelAtPeriodEnd: false, revoke: true, customer: {} },
    };
  }

  if (type === "transaction.completed") {
    if (!data.customer_id) return null;
    return {
      uid: uidOf(data),
      lookup: data.subscription_id ? { field: "subscriptionId", value: String(data.subscription_id) } : null,
      sub: { ...base, customerOnly: true, subscriptionId: data.subscription_id || null, status: "", customer: { paddleCustomerId: String(data.customer_id) } },
    };
  }
  return null;
}

// Cancels a subscription at Paddle (refund, duplicate, account deletion).
const cancelSubscription = paddle.cancelSubscription;

async function process(db, event, { catalog, key, fetchImpl, userExists = web.authUserExists, nowMs = Date.now() } = {}) {
  const decided = decide(event, { catalog, nowMs });
  const auditSub = (decided && decided.sub) || { eventId: String(event.event_id || "unknown"), eventType: String(event.event_type || ""), at: iso(event.occurred_at) || nowMs, status: "" };
  let uid = decided ? decided.uid : null;
  if (decided && !uid && decided.lookup) uid = await web.uidBy(db, decided.lookup.field, decided.lookup.value);
  if (decided && !uid && decided.sub.customer && decided.sub.customer.paddleCustomerId && !decided.sub.customerOnly) {
    uid = await web.uidBy(db, "paddleCustomerId", decided.sub.customer.paddleCustomerId);
  }
  if (!decided || !uid) {
    await web.audit(db, "paddle", auditSub, uid, { ignored: true });
    return { uid, outcome: "audit_only" };
  }
  if (!(await userExists(uid))) {
    await web.audit(db, "paddle", decided.sub, uid, { orphan: true });
    return { uid, outcome: "orphan" };
  }
  const result = await web.apply(db, uid, decided.sub, { nowMs });
  if (!decided.sub.customerOnly) {
    await web.audit(db, "paddle", decided.sub, uid, { outcome: result.outcome, ...(result.outcome === "duplicate" ? { duplicate: true, refundDue: true } : {}) });
  }
  if ((result.outcome === "duplicate" || (result.outcome === "apply" && decided.sub.status === "refunded")) && key) {
    try {
      await cancelSubscription(key, decided.sub.subscriptionId, "immediately", fetchImpl);
    } catch (err) {
      logger.error("paddle subscription could not be cancelled — cancel it in the Paddle dashboard", { uid, subscription: decided.sub.subscriptionId, reason: err.message });
    }
  }
  return { uid, outcome: result.outcome, entitlementWritten: result.entitlementWritten };
}

exports.paddleWebhook = onRequest(
  { region: "europe-west1", secrets: [apiKey, webhookSecret], minInstances: 0, maxInstances: 5, timeoutSeconds: 30 },
  async (req, res) => {
    if (req.method !== "POST") return res.status(405).send("POST only");
    if (!paddle.isSet(webhookSecret.value())) return res.status(503).json({ error: { code: "billing_disabled", message: "Paddle is not configured" } });
    const refused = paddle.verifySignature(req.get("paddle-signature"), req.rawBody, webhookSecret.value());
    if (refused) {
      logger.warn("paddle webhook refused", { reason: refused });
      return res.status(401).send(`bad signature: ${refused}`);
    }
    let event;
    try {
      event = JSON.parse(req.rawBody.toString("utf8"));
    } catch (_) {
      return res.status(400).send("not json");
    }
    try {
      const { catalog } = await catalogs.load();
      const result = await process(admin.firestore(), event, { catalog, key: apiKey.value() });
      logger.info("paddle event handled", { type: event.event_type, id: event.event_id, uid: result.uid, outcome: result.outcome });
      return res.status(200).json({ ok: true });
    } catch (err) {
      console.error("paddleWebhook failed", err);
      // Non-2xx: Paddle retries with backoff.
      return res.status(500).send("failed");
    }
  },
);

exports.internals = { decide, process, cancelSubscription, uidOf };
