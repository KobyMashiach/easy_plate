// DORMANT since 2026-10-18: Stripe does not accept Israeli businesses, so
// webBilling.js routes web purchases to PayPlus (Israel) and Paddle
// (abroad) and no route reaches this file. It is kept, with its tests, for
// a future US-LLC path: wiring it back is a provider entry in
// billingCatalog.js and a branch in webBilling.handle.
//
// Premium bought on the website (aieasyplate.app/app) through Stripe
// Checkout instead of the stores. Three actions, one endpoint:
//
//   plans     — the prices on sale (public; read from Stripe, cached)
//   checkout  — a Stripe Checkout Session for the signed-in account → {url}
//   portal    — Stripe's Billing Portal for the signed-in account → {url}
//
// The purchase itself never touches this code: Stripe hosts the payment page
// (cards, Apple Pay, Google Pay) and reports back to stripeWebhook.js, which
// writes `entitlements/{uid}` — the same document the RevenueCat webhook
// writes and the app already follows. So the app notices a web purchase the
// same way it notices a store one, with no app change.
//
// Who is who: the Firebase uid rides along as the Checkout Session's
// `client_reference_id` and as metadata on the customer and the subscription,
// and `stripe_customers/{uid}` remembers the Stripe customer id so one account
// is one customer, however many times they buy.
//
// Setup, once:
//   firebase functions:secrets:set STRIPE_SECRET_KEY        (sk_live_… / sk_test_…)
//   In Stripe: one recurring price per plan with a lookup key starting with
//   `easy_plate_` (easy_plate_ai_pro_monthly, easy_plate_ai_pro_duo_monthly,
//   easy_plate_ai_pro_family_monthly …). The key is what the app reads as
//   `productId`, so the household tier words (duo / family) must be in it.
//   Optional per price: metadata intro_coupon = <coupon id>, intro_amount =
//   <minor units> for a first-month offer applied to first-time subscribers.
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");
const proxy = require("./aiProxy").internals;
const remoteFlags = require("./remoteFlags");
const stripe = require("./stripeClient");

// The Remote Config switch for the whole web purchase path: 0 hidden /
// 1 coming soon refuse checkout; 2 (and 3) allow it. Same name in the app's
// FeaturesFlags enum, where it shows or hides the "upgrade on the web" row.
const FLAG = "ff_web_checkout";

// Where the pages live. One constant so a staging site is a one-line change.
const WEB_ORIGIN = process.env.WEB_ORIGIN || "https://aieasyplate.app";
const APP_PATH = "/app";

const { ORIGINS } = require("./origins");

const LOOKUP_PREFIX = "easy_plate_";
const CUSTOMERS = "stripe_customers";
const PLAN_CACHE_MS = 5 * 60 * 1000;
// How long a started checkout holds the account: a second "upgrade" in
// another tab within this window is refused rather than opening a second
// Checkout Session (and, paid, a second subscription). The session itself
// expires at the same instant (`expires_at`), so no older session can still
// be paid once the hold lapses. Stripe's minimum is 30 minutes from the
// session's creation; the instant is taken from the start of the idempotency
// key's minute (so a retry sends identical parameters) plus 32 minutes,
// which leaves ≥ 31 minutes after the create call.
const CHECKOUT_PENDING_MS = 32 * 60 * 1000;

// The instant both the Checkout Session and the pending marker expire.
function checkoutExpiresAtMs(nowMs = Date.now()) {
  return Math.floor(nowMs / 60000) * 60000 + CHECKOUT_PENDING_MS;
}

// ---------------------------------------------------------------------------
// Pure parts

function parseRequest(body) {
  const action = typeof body.action === "string" ? body.action : "";
  if (!["plans", "checkout", "portal"].includes(action)) return { error: "Unknown action" };
  const lang = typeof body.lang === "string" && /^[a-z]{2}$/.test(body.lang) ? body.lang : "en";
  const out = { action, lang };
  if (action === "checkout") {
    if (typeof body.priceId !== "string" || !/^price_[A-Za-z0-9]{8,}$/.test(body.priceId)) return { error: "priceId required" };
    out.priceId = body.priceId;
  }
  return out;
}

// The household tier the app derives from a product id (HouseholdTier.fromProductId).
function tierOf(lookupKey) {
  const key = String(lookupKey || "").toLowerCase();
  if (key.includes("family")) return "family";
  if (key.includes("duo")) return "duo";
  return "pro";
}

// A Stripe price → what the pricing page shows. Null when the price is not
// one of ours: only active, recurring prices with our lookup-key prefix are
// ever offered, and `checkout` applies the same test to the id it is handed.
function planFromPrice(price) {
  if (!price || price.active !== true || !price.recurring) return null;
  const key = typeof price.lookup_key === "string" ? price.lookup_key : "";
  if (!key.startsWith(LOOKUP_PREFIX)) return null;
  if (typeof price.unit_amount !== "number") return null;
  const product = price.product && typeof price.product === "object" ? price.product : {};
  const meta = price.metadata || {};
  const introAmount = Number(meta.intro_amount);
  return {
    priceId: price.id,
    lookupKey: key,
    tier: tierOf(key),
    seats: tierOf(key) === "family" ? 6 : tierOf(key) === "duo" ? 2 : 1,
    interval: price.recurring.interval,
    intervalCount: price.recurring.interval_count || 1,
    amount: price.unit_amount,
    currency: String(price.currency || "ils").toLowerCase(),
    name: product.name || price.nickname || key,
    description: product.description || null,
    introCoupon: typeof meta.intro_coupon === "string" && meta.intro_coupon ? meta.intro_coupon : null,
    introAmount: Number.isFinite(introAmount) && introAmount >= 0 && meta.intro_coupon ? introAmount : null,
    order: Number(meta.order) || 0,
  };
}

const ACTIVE_STATUSES = new Set(["active", "trialing", "past_due"]);

// Why this account may not start a web subscription right now, or null.
//   store_subscription — paying through Apple/Google: cancel there first,
//                        or two subscriptions would run at once.
//   household_member   — their Premium is the household owner's.
//   gifted             — an administrator's grant with the lock on: a payment
//                        would not unlock anything until the lock lapses.
//   already_subscribed — a live Stripe subscription: the portal is the place.
function eligibility(entitlement, customer, nowMs = Date.now()) {
  const premium = remoteFlags.isPremium(entitlement || null, nowMs);
  const source = entitlement ? entitlement.source : null;
  if (premium && source === "revenuecat") return "store_subscription";
  if (premium && source === "household") return "household_member";
  if (premium && entitlement.adminLock === true) return "gifted";
  if (customer && ACTIVE_STATUSES.has(customer.subscriptionStatus)) return "already_subscribed";
  return null;
}

// Why a checkout may not start now: eligibility first, then a checkout
// this account started moments ago (`checkoutPendingUntil` on
// stripe_customers/{uid}, written in the same transaction as this check).
function checkoutBlock(entitlement, customer, nowMs = Date.now()) {
  const reason = eligibility(entitlement, customer, nowMs);
  if (reason) return reason;
  const pending = customer && customer.checkoutPendingUntil;
  const until = pending && typeof pending.toMillis === "function" ? pending.toMillis() : null;
  if (until !== null && until > nowMs) return "checkout_pending";
  return null;
}

// Stripe's idempotency key for the session create: a retried or doubled
// request within the same minute returns the one session.
function checkoutIdempotencyKey(uid, priceId, nowMs = Date.now()) {
  return `checkout_${uid}_${priceId}_${Math.floor(nowMs / 60000)}`;
}

// The Checkout Session body. Pure so the one place money is configured is
// pinned by a test: subscription mode, the uid on every object that comes
// back in a webhook, the intro coupon only for a first subscription (Stripe
// refuses a session that has both a fixed discount and a promo-code box).
function checkoutParams({ uid, customerId, plan, firstTime, lang, expiresAtMs }) {
  const params = {
    mode: "subscription",
    expires_at: Math.floor(expiresAtMs / 1000),
    customer: customerId,
    client_reference_id: uid,
    line_items: [{ price: plan.priceId, quantity: 1 }],
    metadata: { uid, lookup_key: plan.lookupKey, lang },
    subscription_data: { metadata: { uid, lookup_key: plan.lookupKey } },
    success_url: `${WEB_ORIGIN}${APP_PATH}/checkout/success?session_id={CHECKOUT_SESSION_ID}`,
    cancel_url: `${WEB_ORIGIN}${APP_PATH}/pricing?cancelled=1`,
    // Stripe's hosted page speaks no Hebrew or Arabic; `auto` follows the
    // browser and falls back to English, which is the honest option.
    locale: "auto",
    billing_address_collection: "auto",
    customer_update: { address: "auto", name: "auto" },
    // Apple Pay / Google Pay appear on their own once enabled in the Stripe
    // dashboard; `card` is the floor.
    payment_method_types: ["card"],
  };
  if (firstTime && plan.introCoupon) {
    params.discounts = [{ coupon: plan.introCoupon }];
  } else {
    params.allow_promotion_codes = true;
  }
  return params;
}

// ---------------------------------------------------------------------------
// Stripe-backed parts

let planCache = { at: 0, plans: null };

async function listPlans(secret, now = Date.now(), fetchImpl) {
  if (planCache.plans && now - planCache.at < PLAN_CACHE_MS) return planCache.plans;
  const res = await stripe.request(secret, "GET", "/prices", { active: true, type: "recurring", limit: 100, expand: ["data.product"] }, { fetchImpl });
  const plans = (res.data || [])
    .map(planFromPrice)
    .filter(Boolean)
    .sort((a, b) => a.order - b.order || a.amount - b.amount);
  planCache = { at: now, plans };
  return plans;
}

async function findPlan(secret, priceId, fetchImpl) {
  const plans = await listPlans(secret, Date.now(), fetchImpl);
  const cached = plans.find((p) => p.priceId === priceId);
  if (cached) return cached;
  // A price created a minute ago is not in the cache yet: ask for it.
  try {
    const price = await stripe.request(secret, "GET", `/prices/${priceId}`, { expand: ["product"] }, { fetchImpl });
    return planFromPrice(price);
  } catch (err) {
    if (err.status === 404) return null;
    throw err;
  }
}

// The Stripe customer for an account: remembered in stripe_customers/{uid},
// created on first use. The uid is the idempotency key, so two tabs clicking
// "upgrade" at once still end up with one customer.
async function customerFor(db, secret, caller, lang, fetchImpl) {
  const ref = db.collection(CUSTOMERS).doc(caller.uid);
  const snap = await ref.get();
  if (snap.exists && snap.get("stripeCustomerId")) return { id: snap.get("stripeCustomerId"), data: snap.data(), created: false };
  let record = null;
  try {
    record = await admin.auth().getUser(caller.uid);
  } catch (_) {
    record = null;
  }
  const customer = await stripe.request(
    secret,
    "POST",
    "/customers",
    {
      metadata: { uid: caller.uid },
      email: (record && record.email) || caller.email || null,
      phone: (record && record.phoneNumber) || null,
      name: (record && record.displayName) || null,
      preferred_locales: [lang],
    },
    { idempotencyKey: `customer_${caller.uid}`, fetchImpl },
  );
  const data = {
    stripeCustomerId: customer.id,
    email: customer.email || null,
    phone: customer.phone || null,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };
  await ref.set(data, { merge: true });
  return { id: customer.id, data: { ...(snap.exists ? snap.data() : {}), ...data }, created: true };
}

// Expires an open Checkout Session so it can no longer be paid. True when
// the session is (now) expired; false when it completed — or when Stripe's
// answer is unclear (a network error included), which keeps the account on
// the safe side; the caller then puts the session id back so the next try
// can ask again instead of waiting out the marker.
async function expireSession(secret, sessionId, fetchImpl) {
  try {
    await stripe.request(secret, "POST", `/checkout/sessions/${encodeURIComponent(sessionId)}/expire`, {}, { fetchImpl });
    return true;
  } catch (err) {
    if (!(err instanceof stripe.StripeError)) return false;
    try {
      const s = await stripe.request(secret, "GET", `/checkout/sessions/${encodeURIComponent(sessionId)}`, {}, { fetchImpl });
      return s && s.status === "expired";
    } catch (_) {
      return false;
    }
  }
}

// Pure: whether a failed checkout may drop its pending marker. Only when no
// session can exist: the session was never asked for, or Stripe refused the
// request (a 4xx). A network error or a 5xx may have opened one we never
// heard about — payable for its whole life — so the marker stays and runs
// out with it.
function pendingClearable(err, sessionRequested) {
  if (!sessionRequested) return true;
  return err instanceof stripe.StripeError && err.status >= 400 && err.status < 500;
}

async function flagValue() {
  const p = await remoteFlags.params();
  // No template read: closed, like the console default (0). Money must not
  // start flowing because Remote Config was unreachable at cold start.
  return remoteFlags.intFrom(p, FLAG, 0);
}

async function handle({ db, secret, caller, request, fetchImpl }) {
  const flag = await flagValue();
  const enabled = flag >= 2;

  if (request.action === "plans") {
    if (!enabled) return { status: 200, body: { enabled: false, flag, plans: [] } };
    const plans = await listPlans(secret, Date.now(), fetchImpl);
    return { status: 200, body: { enabled: true, flag, plans } };
  }

  if (!caller) return { status: 401, body: { error: { code: "unauthenticated", message: "A valid Firebase ID token is required" } } };

  if (request.action === "portal") {
    const snap = await db.collection(CUSTOMERS).doc(caller.uid).get();
    const customerId = snap.exists ? snap.get("stripeCustomerId") : null;
    if (!customerId) return { status: 404, body: { error: { code: "no_customer", message: "No web subscription on this account" } } };
    const session = await stripe.request(secret, "POST", "/billing_portal/sessions", { customer: customerId, return_url: `${WEB_ORIGIN}${APP_PATH}/account` }, { fetchImpl });
    return { status: 200, body: { url: session.url } };
  }

  // checkout
  if (!enabled) return { status: 403, body: { error: { code: "disabled", message: "Web checkout is switched off" } } };
  const plan = await findPlan(secret, request.priceId, fetchImpl);
  if (!plan) return { status: 404, body: { error: { code: "unknown_price", message: "Not a plan on sale" } } };

  // The check and the "checkout started" marker in one transaction: two
  // tabs clicking at once used to both pass and open two sessions.
  const nowMs = Date.now();
  const expiresAtMs = checkoutExpiresAtMs(nowMs);
  const customerRef = db.collection(CUSTOMERS).doc(caller.uid);
  const gate = await db.runTransaction(async (tx) => {
    const [entSnap, custSnap] = await Promise.all([
      tx.get(db.collection("entitlements").doc(caller.uid)),
      tx.get(customerRef),
    ]);
    const cust = custSnap.exists ? custSnap.data() : null;
    const reason = checkoutBlock(entSnap.exists ? entSnap.data() : null, cust, nowMs);
    // A pending checkout whose session id is known (the buyer pressed Back,
    // or closed the tab) is replaced: that session is expired before a new
    // one opens. Claiming it here (the id is cleared in the same write) means
    // two tabs racing for the replacement get one session between them.
    const previous = reason === "checkout_pending" && cust && typeof cust.checkoutSessionId === "string" && cust.checkoutSessionId ? cust.checkoutSessionId : null;
    if (reason && !previous) return { reason, customerId: custSnap.exists ? custSnap.get("stripeCustomerId") : null };
    tx.set(customerRef, { checkoutPendingUntil: admin.firestore.Timestamp.fromMillis(expiresAtMs), checkoutSessionId: admin.firestore.FieldValue.delete() }, { merge: true });
    return { reason: null, previous };
  });
  const reason = gate.reason;
  if (reason === "already_subscribed") {
    const session = await stripe.request(secret, "POST", "/billing_portal/sessions", { customer: gate.customerId, return_url: `${WEB_ORIGIN}${APP_PATH}/account` }, { fetchImpl });
    return { status: 409, body: { error: { code: reason, message: "Already subscribed on the web" }, portal: session.url } };
  }
  const pendingBody = { error: { code: "checkout_pending", message: "A checkout was just started for this account; finish it or try again later" } };
  if (reason === "checkout_pending") return { status: 409, body: pendingBody };
  if (reason) return { status: 409, body: { error: { code: reason, message: reason } } };
  if (gate.previous && !(await expireSession(secret, gate.previous, fetchImpl))) {
    // The earlier session was paid (or is being paid, or Stripe could not
    // be asked): no second one. The marker stays, so the webhook's verdict
    // arrives before another try; the session id goes back (the gate
    // cleared it) so that try asks Stripe again rather than being refused
    // until the marker runs out.
    await customerRef.set({ checkoutSessionId: gate.previous }, { merge: true }).catch(() => {});
    return { status: 409, body: pendingBody };
  }

  let session;
  let customer;
  let firstTime;
  let sessionRequested = false;
  try {
    customer = await customerFor(db, secret, caller, request.lang, fetchImpl);
    firstTime = !(customer.data && customer.data.everSubscribed === true);
    const key = checkoutIdempotencyKey(caller.uid, plan.priceId, nowMs) + (gate.previous ? `_after_${gate.previous}` : "");
    sessionRequested = true;
    session = await stripe.request(secret, "POST", "/checkout/sessions", checkoutParams({ uid: caller.uid, customerId: customer.id, plan, firstTime, lang: request.lang, expiresAtMs }), { idempotencyKey: key, fetchImpl });
  } catch (err) {
    // Nothing was opened: the account may try again at once.
    if (pendingClearable(err, sessionRequested)) {
      await customerRef.set({ checkoutPendingUntil: admin.firestore.FieldValue.delete() }, { merge: true }).catch(() => {});
    }
    throw err;
  }
  await customerRef.set({ checkoutSessionId: session.id }, { merge: true }).catch(() => {});
  logger.info("web checkout session created", { uid: caller.uid, plan: plan.lookupKey, firstTime, session: session.id });
  return { status: 200, body: { url: session.url, sessionId: session.id } };
}

exports.internals = { parseRequest, pendingClearable, planFromPrice, tierOf, eligibility, checkoutBlock, checkoutIdempotencyKey, checkoutExpiresAtMs, CHECKOUT_PENDING_MS, checkoutParams, listPlans, handle, expireSession, FLAG, LOOKUP_PREFIX, CUSTOMERS, WEB_ORIGIN, APP_PATH, ORIGINS, _resetCache: () => { planCache = { at: 0, plans: null }; } };
