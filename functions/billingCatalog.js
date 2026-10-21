// Which payment provider sells web Premium to whom, what is on sale, and
// whether it is switched on — the provider layer webBilling.js and the
// webhooks share.
//
// Two routes, chosen per account (decisions of 2026-10-18 — Stripe does not
// accept Israeli businesses; the international route goes through
// RevenueCat so every subscription shows in one RevenueCat dashboard):
//   payplus    — an Israeli processor, for Israeli accounts: the caller's
//                verified phone (`phone_number` claim) starts with +972.
//                Hosted payment page with a recurring charge (הוראת קבע) in
//                ILS. Direct: RevenueCat has no PayPlus integration.
//   revenuecat — everyone else: RevenueCat's Paddle Billing integration. The
//                checkout is a RevenueCat Web Purchase Link (pay.rev.cat)
//                with the Firebase uid as App User ID; Paddle is the billing
//                engine and merchant of record; RevenueCat's webhook
//                (store PADDLE) writes the entitlement like a store purchase.
// Stripe stays in the code (stripeClient.js / stripeWebhook.js) but no route
// chooses it; the direct Paddle path (paddleWebhook.js) is retired.
//
// Switches (Remote Config, 0 hidden / 1 coming soon / 2 on):
//   ff_web_checkout       the whole web purchase path (also the app's row)
//   ff_web_checkout_il    the PayPlus route
//   ff_web_checkout_intl  the RevenueCat (Paddle) route
// A provider sells only when both its own switch and the master one are ≥ 2.
//
// The catalogue is the Remote Config JSON parameter `web_billing_catalog`:
//   { "payplus":    { "env": "production", "plans": [ {plan}, … ] },
//     "revenuecat": { "purchaseLink": "https://pay.rev.cat/<token>",
//                     "projectId": "proj…",
//                     "plans": [ {plan, "productId": "pri_…", "packageId": "$rc_monthly"}, … ] } }
//   plan = { "id": "easy_plate_ai_pro_monthly", "interval": "month"|"year",
//            "amount": 2000 (minor units), "currency": "ILS", "order": 1 }
// The plan id is what the entitlement records as `productId`, so the
// household tier words (duo / family) must be in it, as with the stores. A
// RevenueCat plan's `productId` is RevenueCat's product identifier (for
// Paddle: the imported price id, pri_…) — the webhook maps it back to the
// plan id; `packageId` pre-selects the package on the purchase link.
const remoteFlags = require("./remoteFlags");

const PROVIDERS = ["payplus", "revenuecat"];
const FLAG = "ff_web_checkout";
const PROVIDER_FLAGS = { payplus: "ff_web_checkout_il", revenuecat: "ff_web_checkout_intl" };
const CATALOG_PARAM = "web_billing_catalog";
const PLAN_ID = /^easy_plate_[a-z0-9_]{3,60}$/;
const RC_PRODUCT = /^[A-Za-z0-9_.:-]{1,100}$/;
const RC_PACKAGE = /^[A-Za-z0-9_.$-]{1,100}$/;
// A RevenueCat Web Purchase Link as the dashboard shares it (Production or
// Sandbox): https://pay.rev.cat/<token>[/…], no query, no trailing slash.
const PURCHASE_LINK = /^https:\/\/pay\.rev\.cat(\/[A-Za-z0-9_-]+)+$/;
const RC_PROJECT = /^[A-Za-z0-9_-]{4,64}$/;
// The stores RevenueCat reports for a purchase made on the web.
const RC_WEB_STORES = new Set(["PADDLE", "RC_BILLING", "STRIPE"]);

// The household tier a plan id grants (HouseholdTier.fromProductId).
function tierOf(planId) {
  const key = String(planId || "").toLowerCase();
  if (key.includes("family")) return "family";
  if (key.includes("duo")) return "duo";
  return "pro";
}
const SEATS = { pro: 1, duo: 2, family: 6 };

function normalizePlan(raw, provider) {
  if (!raw || typeof raw !== "object") return null;
  const id = String(raw.id || "");
  if (!PLAN_ID.test(id)) return null;
  const interval = raw.interval === "year" ? "year" : raw.interval === "month" ? "month" : null;
  if (!interval) return null;
  const amount = Number(raw.amount);
  if (!Number.isInteger(amount) || amount <= 0) return null;
  const currency = String(raw.currency || (provider === "payplus" ? "ILS" : "USD")).toUpperCase();
  if (!/^[A-Z]{3}$/.test(currency)) return null;
  if (provider === "payplus" && currency !== "ILS") return null;
  const plan = {
    planId: id,
    provider,
    tier: tierOf(id),
    seats: SEATS[tierOf(id)],
    interval,
    intervalCount: 1,
    amount,
    currency: currency.toLowerCase(),
    name: typeof raw.name === "string" && raw.name ? raw.name.slice(0, 80) : null,
    description: typeof raw.description === "string" && raw.description ? raw.description.slice(0, 200) : null,
    introAmount: null,
    order: Number(raw.order) || 0,
  };
  if (provider === "revenuecat") {
    const productId = String(raw.productId || "");
    if (!RC_PRODUCT.test(productId)) return null;
    plan.productId = productId;
    const packageId = String(raw.packageId || "");
    plan.packageId = RC_PACKAGE.test(packageId) ? packageId : null;
  }
  return plan;
}

// Pure: the Remote Config value (a JSON string or object) → the catalogue.
// Anything malformed is dropped rather than offered.
function parseCatalog(value) {
  let raw = value;
  if (typeof raw === "string") {
    try {
      raw = JSON.parse(raw);
    } catch (_) {
      raw = null;
    }
  }
  raw = raw && typeof raw === "object" ? raw : {};
  const out = {};
  for (const provider of PROVIDERS) {
    const section = raw[provider] && typeof raw[provider] === "object" ? raw[provider] : {};
    const seen = new Set();
    const plans = (Array.isArray(section.plans) ? section.plans : [])
      .map((p) => normalizePlan(p, provider))
      .filter((p) => p && !seen.has(p.planId) && seen.add(p.planId))
      .sort((a, b) => a.order - b.order || a.amount - b.amount);
    out[provider] = { plans };
    if (provider === "payplus") out.payplus.env = section.env === "staging" ? "staging" : "production";
    if (provider === "revenuecat") {
      const link = typeof section.purchaseLink === "string" ? section.purchaseLink.trim().replace(/\/+$/, "") : "";
      out.revenuecat.purchaseLink = PURCHASE_LINK.test(link) ? link : null;
      const project = typeof section.projectId === "string" ? section.projectId.trim() : "";
      out.revenuecat.projectId = RC_PROJECT.test(project) ? project : null;
    }
  }
  return out;
}

// Pure: the provider for a caller. Israeli phone → payplus, otherwise revenuecat;
// a visitor with no account is guessed from the page language (only for the
// prices shown — checkout always needs an account). An administrator may
// force one, to test the other route.
function providerFor(caller, { override = null, isAdmin = false, lang = "en" } = {}) {
  if (override && isAdmin && PROVIDERS.includes(override)) return override;
  const phone = caller && typeof caller.phone_number === "string" ? caller.phone_number : "";
  if (phone) return phone.startsWith("+972") ? "payplus" : "revenuecat";
  if (caller) return "revenuecat";
  return lang === "he" ? "payplus" : "revenuecat";
}

// Pure: the switches as read from Remote Config parameters. No read → closed
// (money must not start flowing because Remote Config was unreachable).
function switches(params) {
  const master = remoteFlags.intFrom(params, FLAG, 0);
  const out = { master };
  for (const p of PROVIDERS) out[p] = remoteFlags.intFrom(params, PROVIDER_FLAGS[p], 0);
  return out;
}

// Whether a provider sells: its switch and the master one at ≥ 2. An
// administrator passes the switches (to test a route before launch).
function providerOpen(sw, provider, isAdmin = false) {
  if (isAdmin) return true;
  return sw.master >= 2 && (sw[provider] || 0) >= 2;
}

async function load() {
  const params = await remoteFlags.params();
  const value = params?.[CATALOG_PARAM]?.defaultValue?.value;
  return { catalog: parseCatalog(value), switches: switches(params) };
}

function findPlan(catalog, provider, planId) {
  return ((catalog[provider] && catalog[provider].plans) || []).find((p) => p.planId === planId) || null;
}

// The plan behind a RevenueCat product id (a Paddle price imported into
// RevenueCat), or null.
function planByStoreProduct(catalog, productId) {
  if (!productId) return null;
  return ((catalog && catalog.revenuecat && catalog.revenuecat.plans) || []).find((p) => p.productId === productId) || null;
}

// The retired direct-Paddle webhook's lookup; nothing is on sale that way.
function planByPaddlePrice(catalog, priceId) {
  return ((catalog && catalog.paddle && catalog.paddle.plans) || []).find((p) => p.priceId === priceId) || null;
}

// The Web Purchase Link for one account and plan: the App User ID is the
// URL-encoded Firebase uid as a path segment (RevenueCat: "You must append
// the URL-encoded App User ID of the customer to the link"); package_id
// skips the package choice, email pre-fills the checkout.
function purchaseUrl(link, uid, { packageId = null, email = null } = {}) {
  const q = new URLSearchParams();
  if (packageId) q.set("package_id", packageId);
  if (email) q.set("email", email);
  const qs = q.toString();
  return `${link}/${encodeURIComponent(uid)}${qs ? `?${qs}` : ""}`;
}

// The end of the period a charge at `fromMs` pays for (calendar months, UTC).
function addInterval(fromMs, interval) {
  const d = new Date(fromMs);
  const months = interval === "year" ? 12 : 1;
  const day = d.getUTCDate();
  d.setUTCDate(1);
  d.setUTCMonth(d.getUTCMonth() + months);
  const last = new Date(Date.UTC(d.getUTCFullYear(), d.getUTCMonth() + 1, 0)).getUTCDate();
  d.setUTCDate(Math.min(day, last));
  return d.getTime();
}

module.exports = { PROVIDERS, FLAG, PROVIDER_FLAGS, CATALOG_PARAM, PLAN_ID, PURCHASE_LINK, RC_WEB_STORES, tierOf, SEATS, normalizePlan, parseCatalog, providerFor, switches, providerOpen, load, findPlan, planByStoreProduct, planByPaddlePrice, purchaseUrl, addInterval };
