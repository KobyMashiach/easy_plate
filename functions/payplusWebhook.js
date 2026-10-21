// PayPlus → Firestore. PayPlus calls this URL after every successful charge
// or refund on our terminal — the first charge of a subscription (the
// payment page sends it to `refURL_callback`) and every recurring renewal
// (the account-level callback URL) — and, because webBilling asks for it,
// after a failed attempt on the payment page too.
//
// Each call is verified (header `hash` = base64 HMAC-SHA256 of the body with
// the PAYPLUS_SECRET_KEY, `user-agent: PayPlus`), applied once per PayPlus
// transaction (billing_events), and mapped onto entitlements/{uid} through
// the shared writer (webEntitlement.js → revenueCatWebhook.applyInTransaction):
//   Charge, status 000, recurring  → active; Premium until the period this
//                                    charge pays for + 3 days' grace
//   Charge, failed, known recurring → past_due; Premium keeps its end (grace)
//   Refund, status 000              → refunded: Premium off now, and the
//                                    recurring is deleted so it never charges again
// A renewal PayPlus never reports (the card failed for good) simply lets
// premiumUntil pass — that is the end of the subscription.
//
// Setup, once (PayPlus dashboard): the account's callback URL = this
// function's URL (https://europe-west1-easy-plate.cloudfunctions.net/payplusWebhook).
const { onRequest } = require("firebase-functions/v2/https");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");
const payplus = require("./payplusClient");
const catalogs = require("./billingCatalog");
const web = require("./webEntitlement");

const { payplusApiKey: apiKey, payplusSecretKey: secretKey, payplusTerminalUid: terminalUid, payplusPageUid: pageUid } = require("./billingSecrets");

const UID = /^[A-Za-z0-9]{10,128}$/;

// Pure: the facts of one callback, before any lookup.
function facts(body) {
  const t = (body && body.transaction) || {};
  const data = (body && body.data) || {};
  const rec = t.recurring_charge_information || {};
  const type = String(body && body.transaction_type ? body.transaction_type : "").toLowerCase();
  return {
    transactionUid: typeof t.uid === "string" ? t.uid : "",
    type, // "charge" | "refund" | …
    ok: String(t.status_code ?? "") === "000",
    at: payplus.israelMs(t.date),
    amount: typeof t.amount === "number" ? t.amount : Number(t.amount) || null,
    currency: String(t.currency || ""),
    recurringUid: typeof rec.recurring_uid === "string" && rec.recurring_uid ? rec.recurring_uid : null,
    pageRequestUid: typeof t.payment_request_uid === "string" && t.payment_request_uid ? t.payment_request_uid : null,
    customerUid: typeof data.customer_uid === "string" && data.customer_uid ? data.customer_uid : null,
    uid: typeof t.more_info === "string" && UID.test(t.more_info) ? t.more_info : null,
    planId: typeof t.more_info_1 === "string" && catalogs.PLAN_ID.test(t.more_info_1) ? t.more_info_1 : null,
  };
}

// Pure: one callback → the normalised event webEntitlement.apply() takes, or
// null for "audit only". `stored` is the account's web_customers record (for
// a renewal, which names no plan), `catalog` the parsed catalogue.
function decide(body, { stored = null, catalog = { payplus: { plans: [] } }, nowMs = Date.now() } = {}) {
  const f = facts(body);
  if (!f.transactionUid) return null;
  const at = f.at || nowMs;
  const storedOurs = stored && stored.provider === "payplus" ? stored : null;
  const subscriptionId = f.recurringUid || (f.pageRequestUid ? `page:${f.pageRequestUid}` : null) || (storedOurs ? storedOurs.subscriptionId : null);
  const base = {
    provider: "payplus",
    eventId: `${f.transactionUid}_${f.type || "event"}`,
    eventType: `payplus.${f.type || "event"}${f.ok ? "" : ".failed"}`,
    at,
    subscriptionId,
    amount: f.amount,
    currency: f.currency,
    environment: catalog.payplus && catalog.payplus.env === "staging" ? "SANDBOX" : "PRODUCTION",
    customer: {
      ...(f.customerUid ? { payplusCustomerUid: f.customerUid } : {}),
      ...(f.recurringUid ? { payplusRecurringUid: f.recurringUid } : {}),
    },
  };
  if (f.type === "charge" && f.ok) {
    if (!f.recurringUid && !f.pageRequestUid) return null; // not one of our subscriptions
    const planId = f.planId || (storedOurs ? storedOurs.planId : null);
    const plan = planId ? catalogs.findPlan(catalog, "payplus", planId) : null;
    // A plan removed from the catalogue still renews: monthly unless the id says yearly.
    const interval = plan ? plan.interval : /year/.test(String(planId || "")) ? "year" : "month";
    if (!planId) return null;
    return { ...base, status: "active", planId, periodEndMs: catalogs.addInterval(at, interval), cancelAtPeriodEnd: false, revoke: false };
  }
  if (f.type === "charge" && !f.ok) {
    // A first payment that failed is nothing to record; a renewal that
    // failed puts a live subscription into its grace.
    if (!storedOurs || !web.storedLive(storedOurs, nowMs)) return null;
    if (f.recurringUid && storedOurs.subscriptionId !== f.recurringUid && storedOurs.payplusRecurringUid !== f.recurringUid) return null;
    return { ...base, subscriptionId: storedOurs.subscriptionId, status: "past_due", planId: storedOurs.planId, periodEndMs: null, cancelAtPeriodEnd: null, revoke: false };
  }
  if (f.type === "refund" && f.ok) {
    if (!storedOurs) return null;
    return { ...base, subscriptionId: f.recurringUid || storedOurs.subscriptionId, status: "refunded", planId: storedOurs.planId, periodEndMs: null, cancelAtPeriodEnd: false, revoke: true };
  }
  return null;
}

function keysFrom(catalog) {
  return { apiKey: apiKey.value(), secretKey: secretKey.value(), terminalUid: terminalUid.value(), pageUid: pageUid.value(), env: catalog.payplus.env };
}

// Stops a recurring at PayPlus (refund, duplicate, account deletion).
async function deleteRecurring(keys, recurringUid, fetchImpl) {
  if (!recurringUid || String(recurringUid).startsWith("page:")) return false;
  await payplus.request(keys, "POST", `/RecurringPayments/DeleteRecurring/${encodeURIComponent(recurringUid)}`, { terminal_uid: keys.terminalUid }, { fetchImpl });
  return true;
}

async function process(db, body, { catalog, keys, fetchImpl, userExists = web.authUserExists, nowMs = Date.now() } = {}) {
  const f = facts(body);
  // Which account: our own uid on the first charge; a renewal is found by
  // the recurring it belongs to, or the PayPlus customer.
  let uid = f.uid;
  if (!uid && f.recurringUid) uid = (await web.uidBy(db, "subscriptionId", f.recurringUid)) || (await web.uidBy(db, "payplusRecurringUid", f.recurringUid));
  if (!uid && f.customerUid) uid = await web.uidBy(db, "payplusCustomerUid", f.customerUid);
  const storedSnap = uid ? await db.collection(web.CUSTOMERS).doc(uid).get() : null;
  const stored = storedSnap && storedSnap.exists ? storedSnap.data() : null;
  const sub = decide(body, { stored, catalog, nowMs });
  const auditSub = sub || { eventId: `${f.transactionUid || "unknown"}_${f.type || "event"}`, eventType: `payplus.${f.type || "event"}${f.ok ? "" : ".failed"}`, at: f.at || nowMs, status: f.ok ? "" : "failed", amount: f.amount, currency: f.currency, subscriptionId: f.recurringUid };
  if (!sub || !uid) {
    await web.audit(db, "payplus", auditSub, uid, { payplusTransactionUid: f.transactionUid || null, ignored: true });
    return { uid, outcome: "audit_only" };
  }
  if (!(await userExists(uid))) {
    await web.audit(db, "payplus", sub, uid, { payplusTransactionUid: f.transactionUid, orphan: true });
    return { uid, outcome: "orphan" };
  }
  const result = await web.apply(db, uid, sub, { nowMs });
  await web.audit(db, "payplus", sub, uid, { payplusTransactionUid: f.transactionUid, outcome: result.outcome, ...(result.outcome === "duplicate" ? { duplicate: true, refundDue: true } : {}) });
  // After the verdict, the provider side follows it: a refunded or doubled
  // subscription must not charge again. Best effort, logged; the entitlement
  // is already right.
  if ((result.outcome === "duplicate" || (result.outcome === "apply" && sub.revoke)) && keys) {
    try {
      await deleteRecurring(keys, f.recurringUid || sub.subscriptionId, fetchImpl);
    } catch (err) {
      logger.error("payplus recurring could not be deleted — stop it in the PayPlus dashboard", { uid, recurring: f.recurringUid || sub.subscriptionId, reason: err.message });
    }
  }
  return { uid, outcome: result.outcome, entitlementWritten: result.entitlementWritten };
}

exports.payplusWebhook = onRequest(
  { region: "europe-west1", secrets: [apiKey, secretKey, terminalUid, pageUid], minInstances: 0, maxInstances: 5, timeoutSeconds: 30 },
  async (req, res) => {
    if (req.method !== "POST") return res.status(405).send("POST only");
    if (!payplus.isSet(secretKey.value())) return res.status(503).json({ error: { code: "billing_disabled", message: "PayPlus is not configured" } });
    const refused = payplus.verifyCallback(req.headers, req.rawBody, secretKey.value());
    if (refused) {
      logger.warn("payplus callback refused", { reason: refused });
      return res.status(401).send(`bad signature: ${refused}`);
    }
    let body;
    try {
      body = JSON.parse(req.rawBody.toString("utf8"));
    } catch (_) {
      return res.status(400).send("not json");
    }
    try {
      const { catalog } = await catalogs.load();
      const result = await process(admin.firestore(), body, { catalog, keys: keysFrom(catalog) });
      logger.info("payplus callback handled", { type: body.transaction_type, uid: result.uid, outcome: result.outcome });
      return res.status(200).json({ ok: true });
    } catch (err) {
      console.error("payplusWebhook failed", err);
      return res.status(500).send("failed");
    }
  },
);

exports.internals = { facts, decide, process, deleteRecurring, keysFrom };
