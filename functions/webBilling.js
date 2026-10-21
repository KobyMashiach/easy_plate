// Premium bought on the website (aieasyplate.app/app) instead of the stores.
// One endpoint, a provider layer underneath (billingCatalog.js):
//   Israeli account (verified phone +972…) → PayPlus, a hosted payment page
//                                             with a recurring charge in ILS
//   everyone else                          → RevenueCat (Paddle Billing):
//                                             a Web Purchase Link on
//                                             pay.rev.cat, Paddle the
//                                             merchant of record
// Stripe is dormant (stripeBilling.js): Stripe does not accept Israeli
// businesses (decision of 2026-10-18), so no route chooses it. The direct
// Paddle route (Paddle.js + paddleWebhook) is retired: the international
// checkout goes through RevenueCat so every subscription — App Store, Play,
// web — is in one RevenueCat dashboard.
//
// Actions:
//   plans    — what is on sale for this visitor (public; signed-in callers
//              are routed by their phone, visitors by page language)
//   checkout — PayPlus: a payment page URL; RevenueCat: the Web Purchase
//              Link with the caller's uid (from the verified ID token, never
//              from the request) as App User ID
//   manage   — RevenueCat/Paddle: the authenticated Paddle customer-portal
//              URL from RevenueCat's API; PayPlus: cancel at period end,
//              after `confirm: true` (there is no PayPlus portal)
//   status   — the account's web subscription as we recorded it
//   portal   — the old name of `manage` (older pages)
//
// The purchase itself never touches this code: payplusWebhook.js and
// revenueCatWebhook.js write entitlements/{uid}, the document the app and
// the website already follow.
const { onRequest } = require("firebase-functions/v2/https");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");
const proxy = require("./aiProxy").internals;
const permissions = require("./permissions");
const remoteFlags = require("./remoteFlags");
const catalogs = require("./billingCatalog");
const payplus = require("./payplusClient");
const rc = require("./revenueCatClient");
const web = require("./webEntitlement");
const { ORIGINS } = require("./origins");

const billingSecrets = require("./billingSecrets");

const FLAG = catalogs.FLAG;
const WEB_ORIGIN = process.env.WEB_ORIGIN || "https://aieasyplate.app";
const APP_PATH = "/app";
const FUNCTIONS_ORIGIN = "https://europe-west1-easy-plate.cloudfunctions.net";
// How long a started checkout holds the account (the anti-double-checkout
// marker on web_customers/{uid}); the PayPlus page expires at the same time.
const CHECKOUT_PENDING_MS = 30 * 60 * 1000;
const ACTIONS = ["plans", "checkout", "manage", "status", "portal"];

// ---------------------------------------------------------------------------
// Pure parts

function parseRequest(body) {
  body = body || {};
  const action = typeof body.action === "string" ? body.action : "";
  if (!ACTIONS.includes(action)) return { error: "Unknown action" };
  const lang = typeof body.lang === "string" && /^[a-z]{2}$/.test(body.lang) ? body.lang : "en";
  const out = { action: action === "portal" ? "manage" : action, lang };
  if (typeof body.provider === "string" && catalogs.PROVIDERS.includes(body.provider)) out.provider = body.provider;
  if (out.action === "checkout") {
    if (typeof body.planId !== "string" || !catalogs.PLAN_ID.test(body.planId)) return { error: "planId required" };
    out.planId = body.planId;
  }
  if (out.action === "manage") out.confirm = body.confirm === true;
  return out;
}

// Whether a provider can sell: PayPlus needs its keys; RevenueCat only the
// purchase link (the checkout is RevenueCat's page, the grant its webhook).
function configured(provider, keys, catalog) {
  if (provider === "payplus") return payplus.configured(keys.payplus);
  if (provider === "revenuecat") return !!(catalog.revenuecat && catalog.revenuecat.purchaseLink);
  return false;
}

// Whether RevenueCat's API can be asked (manage, account deletion).
function rcApiReady(keys, catalog) {
  return rc.isSet(keys && keys.revenuecat && keys.revenuecat.secretKey) && !!(catalog && catalog.revenuecat && catalog.revenuecat.projectId);
}

// Pure: premium bought on the web through RevenueCat (Paddle) rather than
// in a store.
function rcWebEntitlement(ent) {
  return !!ent && ent.source === "revenuecat" && catalogs.RC_WEB_STORES.has(String(ent.store || "").toUpperCase());
}

// Why this account may not start a web subscription now, or null.
//   store_subscription — paying through Apple/Google (cancel there first)
//   household_member   — their Premium is the household owner's
//   gifted             — an administrator's locked grant
//   already_subscribed — a live PayPlus or RevenueCat-web (Paddle)
//                        subscription: manage it
function eligibility(entitlement, customer, nowMs = Date.now()) {
  const premium = remoteFlags.isPremium(entitlement || null, nowMs);
  const source = entitlement ? entitlement.source : null;
  if (premium && rcWebEntitlement(entitlement)) return "already_subscribed";
  if (premium && source === "revenuecat") return "store_subscription";
  if (premium && source === "household") return "household_member";
  if (premium && entitlement.adminLock === true) return "gifted";
  if (web.storedLive(customer, nowMs)) return "already_subscribed";
  if (premium && source === "stripe") return "already_subscribed";
  return null;
}

function checkoutBlock(entitlement, customer, nowMs = Date.now()) {
  const reason = eligibility(entitlement, customer, nowMs);
  if (reason) return reason;
  const pending = customer && customer.checkoutPendingUntil;
  const until = pending && typeof pending.toMillis === "function" ? pending.toMillis() : null;
  if (until !== null && until > nowMs) return "checkout_pending";
  return null;
}

// A failed checkout drops its marker only when nothing payable can exist:
// the provider was never asked, or it refused (4xx). A network error or a
// 5xx may have opened a page we never heard about.
function pendingClearable(err, requested) {
  if (!requested) return true;
  const known = err instanceof payplus.PayPlusError;
  return known && err.status >= 400 && err.status < 500;
}

const PAYPLUS_LANGS = new Set(["he", "en", "ru", "ar", "fr"]);

// The PayPlus payment page request (POST /PaymentPages/generateLink). Pure,
// so the one place money is configured is pinned by a test: a recurring
// charge (charge_method 3) taken at once and then every month/year with no
// end, our uid and plan in more_info / more_info_1 (they come back in every
// callback), the callback pointed at payplusWebhook.
function payplusLinkBody({ uid, plan, keys, lang, user = {} }) {
  const amount = plan.amount / 100;
  return {
    payment_page_uid: keys.pageUid.trim(),
    charge_method: 3,
    amount,
    currency_code: "ILS",
    language_code: PAYPLUS_LANGS.has(lang) ? lang : "he",
    sendEmailApproval: true,
    sendEmailFailure: false,
    expiry_datetime: String(CHECKOUT_PENDING_MS / 60000),
    refURL_success: `${WEB_ORIGIN}${APP_PATH}/checkout/success?provider=payplus`,
    refURL_failure: `${WEB_ORIGIN}${APP_PATH}/pricing?failed=1`,
    refURL_cancel: `${WEB_ORIGIN}${APP_PATH}/pricing?cancelled=1`,
    refURL_callback: `${FUNCTIONS_ORIGIN}/payplusWebhook`,
    send_failure_callback: true,
    more_info: uid,
    more_info_1: plan.planId,
    customer: {
      customer_name: user.name || user.email || user.phone || "EasyPlate",
      ...(user.email ? { email: user.email } : {}),
      ...(user.phone ? { phone: user.phone } : {}),
      customer_external_number: uid,
    },
    items: [{ name: plan.name || `EasyPlate Premium (${plan.tier}, ${plan.interval === "year" ? "yearly" : "monthly"})`, quantity: 1, price: amount, vat_type: 0 }],
    recurring_settings: {
      instant_first_payment: true,
      recurring_type: 2, // monthly
      recurring_range: plan.interval === "year" ? 12 : 1,
      number_of_charges: 0, // until cancelled
      start_date_on_payment_date: true,
      jump_payments: 0,
      successful_invoice: true,
      customer_failure_email: true,
      send_customer_success_email: true,
    },
  };
}

// The redirect allow-lists the website applies too (webapp/src/lib/api.ts).
function isPayPlusPage(url) {
  return typeof url === "string" && /^https:\/\/[a-z0-9-]+\.payplus\.co\.il\//.test(url);
}
function isPurchaseLink(url) {
  return typeof url === "string" && /^https:\/\/pay\.rev\.cat\//.test(url);
}
// Where a RevenueCat management URL may lead: Paddle's customer portal
// (customer-portal.paddle.com / sandbox-…) or a RevenueCat page.
function isManagePage(url) {
  return typeof url === "string" && /^https:\/\/([a-z0-9-]+\.)*(paddle\.com|revenuecat\.com|rev\.cat)\//.test(url);
}

const err = (status, code, message, extra = {}) => ({ status, body: { error: { code, message }, ...extra } });

// ---------------------------------------------------------------------------
// Provider calls

async function closePrevious(provider, ref, keys, fetchImpl) {
  try {
    if (provider !== "payplus") return true;
    await payplus.request(keys.payplus, "POST", `/PaymentPages/Disable/${encodeURIComponent(ref)}`, {}, { fetchImpl });
    return true;
  } catch (_) {
    // Paid, being paid, or the provider could not be asked: keep the hold.
    return false;
  }
}

async function userFacts(uid, caller) {
  try {
    const r = await admin.auth().getUser(uid);
    return { name: r.displayName || null, email: r.email || caller.email || null, phone: r.phoneNumber || caller.phone_number || null };
  } catch (_) {
    return { name: null, email: caller.email || null, phone: caller.phone_number || null };
  }
}

async function payplusRecurringUid(cust, keys, fetchImpl) {
  if (cust.payplusRecurringUid) return cust.payplusRecurringUid;
  if (cust.subscriptionId && !String(cust.subscriptionId).startsWith("page:")) return cust.subscriptionId;
  if (!cust.payplusCustomerUid) return null;
  const list = await payplus.request(keys.payplus, "GET", "/RecurringPayments/View", null, { fetchImpl, query: { terminal_uid: keys.payplus.terminalUid, customer_uid: cust.payplusCustomerUid } });
  const live = ((list && list.data) || []).filter((r) => r && r.valid !== false);
  return live.length ? live[0].uid : null;
}

// ---------------------------------------------------------------------------
// The handler (dependencies passed in so the tests drive it)

async function handle({ db, caller, request, keys, catalog, switches, isAdmin = false, fetchImpl, nowMs = Date.now(), user }) {
  const provider = catalogs.providerFor(caller, { override: request.provider, isAdmin, lang: request.lang });
  const open = catalogs.providerOpen(switches, provider, isAdmin);
  const ready = configured(provider, keys, catalog);

  if (request.action === "plans") {
    const plans = open ? (catalog[provider] && catalog[provider].plans) || [] : [];
    return {
      status: 200,
      body: {
        enabled: open && ready && plans.length > 0,
        flag: switches.master,
        provider,
        providerFlag: switches[provider] || 0,
        comingSoon: !open && switches.master >= 1 && (switches[provider] || 0) === 1,
        configured: ready,
        plans,
      },
    };
  }

  if (!caller) return err(401, "unauthenticated", "A valid Firebase ID token is required");
  const custRef = db.collection(web.CUSTOMERS).doc(caller.uid);

  if (request.action === "status") {
    const snap = await custRef.get();
    const c = snap.exists ? snap.data() : null;
    if (!(c && c.subscriptionId)) {
      // A RevenueCat (Paddle) subscription lives on the entitlement only.
      const entSnap = await db.collection("entitlements").doc(caller.uid).get();
      const ent = entSnap.exists ? entSnap.data() : null;
      if (rcWebEntitlement(ent)) {
        const until = ent.premiumUntil && typeof ent.premiumUntil.toMillis === "function" ? ent.premiumUntil.toMillis() : null;
        return {
          status: 200,
          body: { provider, enabled: open && ready, subscription: { provider: "revenuecat", status: String(ent.lastEventType || "").toLowerCase() || null, planId: ent.productId || null, cancelAtPeriodEnd: ent.cancelAtPeriodEnd === true, currentPeriodEnd: until, live: remoteFlags.isPremium(ent, nowMs) } },
        };
      }
    }
    const end = c && c.currentPeriodEnd && typeof c.currentPeriodEnd.toMillis === "function" ? c.currentPeriodEnd.toMillis() : null;
    return {
      status: 200,
      body: {
        provider,
        enabled: open && ready,
        subscription: c && c.subscriptionId ? { provider: c.provider, status: c.subscriptionStatus || null, planId: c.planId || null, cancelAtPeriodEnd: c.cancelAtPeriodEnd === true, currentPeriodEnd: end, live: web.storedLive(c, nowMs) } : null,
      },
    };
  }

  if (request.action === "manage") {
    const snap = await custRef.get();
    const c = snap.exists ? snap.data() : null;
    if (!c || !c.subscriptionId || c.provider !== "payplus") {
      // RevenueCat (Paddle): the subscription is RevenueCat's to report; its
      // management URL is an authenticated Paddle customer portal (payment
      // method, receipts, cancel).
      const entSnap = await db.collection("entitlements").doc(caller.uid).get();
      const ent = entSnap.exists ? entSnap.data() : null;
      if (!rcWebEntitlement(ent)) return err(404, "no_subscription", "No web subscription on this account");
      if (!rcApiReady(keys, catalog)) return err(503, "billing_disabled", "The payment service is not configured");
      const sub = rc.paddleSubscription(await rc.subscriptions(keys.revenuecat.secretKey, catalog.revenuecat.projectId, caller.uid, { fetchImpl }));
      if (!sub) return err(404, "no_subscription", "No web subscription on this account");
      const url = await rc.managementUrl(keys.revenuecat.secretKey, catalog.revenuecat.projectId, sub, { fetchImpl });
      if (!isManagePage(url)) return err(502, "provider_error", "The payment service gave no portal link");
      return { status: 200, body: { provider: "revenuecat", url } };
    }
    if (!configured(c.provider, keys, catalog)) return err(503, "billing_disabled", "The payment service is not configured");
    // PayPlus: no hosted portal. Cancelling stops the recurring charge; the
    // paid period runs out as bought.
    const end = c.currentPeriodEnd && typeof c.currentPeriodEnd.toMillis === "function" ? c.currentPeriodEnd.toMillis() : null;
    if (!web.storedLive(c, nowMs)) return err(409, "not_active", "The subscription is not active");
    if (c.cancelAtPeriodEnd === true) return { status: 200, body: { provider: "payplus", cancelled: true, alreadyCancelled: true, currentPeriodEnd: end } };
    if (!request.confirm) return { status: 200, body: { provider: "payplus", confirmRequired: true, currentPeriodEnd: end, planId: c.planId || null } };
    const recurringUid = await payplusRecurringUid(c, keys, fetchImpl);
    if (!recurringUid) return err(409, "no_recurring", "The recurring charge could not be found; contact support");
    await payplus.request(keys.payplus, "POST", `/RecurringPayments/DeleteRecurring/${encodeURIComponent(recurringUid)}`, { terminal_uid: keys.payplus.terminalUid }, { fetchImpl });
    await web.applyLocal(db, caller.uid, {
      provider: "payplus",
      eventType: "payplus.cancel_requested",
      eventId: `cancel_${recurringUid}`,
      at: nowMs,
      subscriptionId: c.subscriptionId,
      status: "active",
      planId: c.planId,
      periodEndMs: end,
      cancelAtPeriodEnd: true,
      revoke: false,
      customer: { payplusRecurringUid: recurringUid },
    }, { nowMs });
    logger.info("payplus subscription set to end at period end", { uid: caller.uid, recurring: recurringUid });
    return { status: 200, body: { provider: "payplus", cancelled: true, currentPeriodEnd: end } };
  }

  // checkout
  const refusal = proxy.paidCallerRefusal(caller);
  if (refusal) return err(refusal.status, refusal.code, refusal.message);
  if (!open) return err(403, "disabled", "Web checkout is switched off");
  if (!ready) return err(503, "billing_disabled", "The payment service is not configured");
  const plan = catalogs.findPlan(catalog, provider, request.planId);
  if (!plan) return err(404, "unknown_price", "Not a plan on sale");

  if (provider === "revenuecat") {
    // RevenueCat's hosted checkout: nothing is created on our side or the
    // provider's until the buyer pays, so there is no page to close and no
    // pending hold — only the eligibility check. RevenueCat itself refuses a
    // second active subscription to the same product.
    const [entSnap, custSnap] = await Promise.all([db.collection("entitlements").doc(caller.uid).get(), custRef.get()]);
    const cust = custSnap.exists ? custSnap.data() : null;
    const reason = eligibility(entSnap.exists ? entSnap.data() : null, cust, nowMs);
    if (reason === "already_subscribed") return err(409, "already_subscribed", "Already subscribed on the web", { provider: (cust && web.storedLive(cust, nowMs) && cust.provider) || "revenuecat", manage: true });
    if (reason) return err(409, reason, reason);
    const email = (user && user.email) || caller.email || null;
    const url = catalogs.purchaseUrl(catalog.revenuecat.purchaseLink, caller.uid, { packageId: plan.packageId, email });
    if (!isPurchaseLink(url)) return err(503, "billing_disabled", "The payment service is not configured");
    logger.info("revenuecat purchase link handed out", { uid: caller.uid, plan: plan.planId });
    return { status: 200, body: { provider: "revenuecat", url } };
  }

  // PayPlus. The check and the "checkout started" marker in one transaction: two tabs
  // clicking at once get one payment page between them.
  const expiresAtMs = nowMs + CHECKOUT_PENDING_MS;
  const gate = await db.runTransaction(async (tx) => {
    const [entSnap, custSnap] = await Promise.all([tx.get(db.collection("entitlements").doc(caller.uid)), tx.get(custRef)]);
    const cust = custSnap.exists ? custSnap.data() : null;
    const reason = checkoutBlock(entSnap.exists ? entSnap.data() : null, cust, nowMs);
    // A pending checkout whose page is known (the buyer pressed Back) is
    // replaced: the old page is closed first. Claimed here, so two tabs
    // racing for the replacement get one between them.
    const previous = reason === "checkout_pending" && cust && typeof cust.checkoutRef === "string" && cust.checkoutRef && cust.checkoutProvider ? { ref: cust.checkoutRef, provider: cust.checkoutProvider } : null;
    if (reason && !previous) return { reason, cust };
    tx.set(custRef, { checkoutPendingUntil: admin.firestore.Timestamp.fromMillis(expiresAtMs), checkoutRef: admin.firestore.FieldValue.delete(), checkoutProvider: provider }, { merge: true });
    return { reason: null, previous, cust };
  });
  if (gate.reason === "already_subscribed") {
    return err(409, "already_subscribed", "Already subscribed on the web", { provider: (gate.cust && gate.cust.provider) || provider, manage: true });
  }
  const pendingBody = err(409, "checkout_pending", "A checkout was just started for this account; finish it or try again later");
  if (gate.reason === "checkout_pending") return pendingBody;
  if (gate.reason) return err(409, gate.reason, gate.reason);
  if (gate.previous && !(await closePrevious(gate.previous.provider, gate.previous.ref, keys, fetchImpl))) {
    await custRef.set({ checkoutRef: gate.previous.ref, checkoutProvider: gate.previous.provider }, { merge: true }).catch(() => {});
    return pendingBody;
  }

  let requested = false;
  try {
    const facts = user || (await userFacts(caller.uid, caller));
    requested = true;
    const res = await payplus.request(keys.payplus, "POST", "/PaymentPages/generateLink", payplusLinkBody({ uid: caller.uid, plan, keys: keys.payplus, lang: request.lang, user: facts }), { fetchImpl });
    const data = (res && res.data) || {};
    if (!isPayPlusPage(data.payment_page_link) || !data.page_request_uid) throw new payplus.PayPlusError(502, res, "bad_response");
    await custRef.set({ checkoutRef: data.page_request_uid }, { merge: true }).catch(() => {});
    logger.info("payplus payment page created", { uid: caller.uid, plan: plan.planId, page: data.page_request_uid });
    return { status: 200, body: { provider: "payplus", url: data.payment_page_link } };
  } catch (e) {
    if (pendingClearable(e, requested)) {
      await custRef.set({ checkoutPendingUntil: admin.firestore.FieldValue.delete(), checkoutProvider: admin.firestore.FieldValue.delete() }, { merge: true }).catch(() => {});
    }
    throw e;
  }
}

exports.webBilling = onRequest(
  { region: "europe-west1", cors: ORIGINS, maxInstances: 5, timeoutSeconds: 30, secrets: billingSecrets.SECRETS },
  async (req, res) => {
    if (req.method !== "POST") return res.status(405).json({ error: { message: "POST only" } });
    const request = parseRequest(req.body || {});
    if (request.error) return res.status(400).json({ error: { code: "invalid", message: request.error } });
    // `plans` answers visitors too; a token, when sent, routes by phone.
    const hasToken = /^Bearer\s+/i.test(req.get("authorization") || "");
    const caller = request.action === "plans" && !hasToken ? null : await proxy.verifyCaller(req);
    try {
      const db = admin.firestore();
      const { catalog, switches } = await catalogs.load();
      // Only asked when it matters: an override, or a switch still closed
      // (an administrator tests a route before launch).
      const isAdmin = caller && (request.provider || switches.master < 2 || switches.payplus < 2 || switches.revenuecat < 2) ? await permissions.isAdmin(caller, db) : false;
      const keys = billingSecrets.keys();
      keys.payplus.env = catalog.payplus.env;
      const out = await handle({ db, caller, request, keys, catalog, switches, isAdmin });
      return res.status(out.status).json(out.body);
    } catch (e) {
      if (e instanceof payplus.PayPlusError || e instanceof rc.RevenueCatError) {
        logger.error("payment provider refused", { action: request.action, provider: e instanceof rc.RevenueCatError ? "revenuecat" : "payplus", status: e.status, code: e.code, message: e.message });
        if (e.code === "not_configured") return res.status(503).json({ error: { code: "billing_disabled", message: "The payment service is not configured" } });
        return res.status(502).json({ error: { code: "provider_error", message: "The payment service refused the request" } });
      }
      logger.error("webBilling failed", { action: request.action, reason: e.message });
      return res.status(500).json({ error: { message: "Failed" } });
    }
  },
);

exports.internals = {
  parseRequest, eligibility, checkoutBlock, pendingClearable, payplusLinkBody, isPayPlusPage, isPurchaseLink, isManagePage, rcWebEntitlement,
  handle, configured, rcApiReady, CHECKOUT_PENDING_MS, FLAG, WEB_ORIGIN, APP_PATH, ORIGINS, FUNCTIONS_ORIGIN,
};
