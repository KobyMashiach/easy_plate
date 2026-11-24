// An account's subscription story, read from its purchase_events rows:
// when it joined Premium, renewed, cancelled, ended — the store webhooks
// (RevenueCat), the web providers (PayPlus, Paddle, Stripe) and the
// administrator's own grants and revokes. Pure: no Firestore, no DOM, so
// node can test it.

const millisOf = (v) => {
  if (v === null || v === undefined) return null;
  if (typeof v === "number") return Number.isFinite(v) ? v : null;
  if (v instanceof Date) return Number.isNaN(v.getTime()) ? null : v.getTime();
  if (typeof v.toMillis === "function") return v.toMillis();
  if (typeof v.seconds === "number") return v.seconds * 1000 + Math.floor((v.nanoseconds || 0) / 1e6);
  if (typeof v === "string") { const d = Date.parse(v); return Number.isNaN(d) ? null : d; }
  return null;
};

const STORE_STEPS = {
  ADMIN_GRANT: "adminGrant",
  ADMIN_REVOKE: "adminRevoke",
  RENEWAL: "renewed",
  CANCELLATION: "cancelled",
  UNCANCELLATION: "uncancelled",
  EXPIRATION: "ended",
  BILLING_ISSUE: "billingIssue",
  PRODUCT_CHANGE: "changedPlan",
  NON_RENEWING_PURCHASE: "oneTime",
  SUBSCRIPTION_PAUSED: "paused",
  TRANSFER: "transferred",
};

// Steps after which the account holds Premium, and the ones that take it away.
const OPENS = new Set(["joined", "trial", "renewed", "adminGrant", "uncancelled", "oneTime", "changedPlan"]);
const CLOSES = new Set(["ended", "adminRevoke", "refunded"]);

// One event → its step. `active` = Premium held at this point of the walk,
// which decides whether a web provider's granting event is a join or a renewal.
export function stepOf(event, active = false) {
  const type = String((event && event.type) || "");
  if (type === "INITIAL_PURCHASE") return String(event.periodType || "").toUpperCase() === "TRIAL" ? "trial" : "joined";
  if (STORE_STEPS[type]) return STORE_STEPS[type];
  const lower = type.toLowerCase();
  if (lower.includes("refund")) return "refunded";
  if (lower.includes("cancel")) return "cancelled";
  if (lower.includes("fail") || lower.includes("past_due")) return "billingIssue";
  if (lower.includes("expire") || lower.includes("ended") || lower.includes("deleted")) return "ended";
  if (event && event.grantsPremium === true) return active ? "renewed" : "joined";
  return "other";
}

const PAID = new Set(["joined", "renewed", "oneTime", "changedPlan", "uncancelled"]);

export function subscriptionHistory(events, now = Date.now()) {
  const sorted = (events || [])
    .filter(Boolean)
    .map((e, i) => ({ e, i, at: millisOf(e.eventAt) }))
    .sort((a, b) => (a.at ?? 0) - (b.at ?? 0) || a.i - b.i);
  const steps = [];
  let active = false;
  let joinedAt = null, lastCancelledAt = null, lastEndedAt = null, firstPaidAt = null, lastPaidAt = null, lastPaid = null, renewals = 0;
  for (const { e, at } of sorted) {
    const step = stepOf(e, active);
    const until = millisOf(e.expiresAt);
    const price = typeof e.price === "number" && Number.isFinite(e.price) ? e.price : null;
    const sandbox = String(e.environment || "").toUpperCase() === "SANDBOX";
    steps.push({
      at, step, type: String(e.type || ""), productId: e.productId || "", store: e.store || "",
      until, untilPassed: until !== null && until <= now,
      price, currency: String(e.currency || "").toUpperCase(), sandbox, by: e.by || "",
    });
    if (OPENS.has(step)) active = true;
    if (CLOSES.has(step)) active = false;
    if (joinedAt === null && (step === "joined" || step === "trial" || step === "adminGrant")) joinedAt = at;
    if (step === "cancelled") lastCancelledAt = at;
    if (CLOSES.has(step)) lastEndedAt = at;
    if (step === "renewed") renewals++;
    // A payment: a store purchase or renewal (not a gift, not a trial). A
    // missing price still counts — some providers leave it out — but a
    // free one (price 0) does not.
    if (PAID.has(step) && price !== 0) {
      if (firstPaidAt === null) firstPaidAt = at;
      lastPaidAt = at;
      lastPaid = { at, price, currency: String(e.currency || "").toUpperCase(), sandbox, productId: e.productId || "" };
    }
  }
  return { steps, joinedAt, lastCancelledAt, lastEndedAt, renewals, firstPaidAt, lastPaidAt, lastPaid };
}
