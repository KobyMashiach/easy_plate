// A thin RevenueCat REST API v2 client — the server side of web Premium sold
// outside Israel (decision of 2026-10-18): Paddle is the billing engine and
// merchant of record, RevenueCat presents the checkout (a Web Purchase Link
// on pay.rev.cat), owns the Paddle notifications, and reports every
// subscription — App Store, Google Play and Paddle — in one dashboard and one
// webhook (revenueCatWebhook.js).
//
//   API   https://api.revenuecat.com/v2, Authorization: Bearer <secret v2 key>
//         (REVENUECAT_SECRET_KEY; "-" = not configured). Permissions the key
//         needs: customer_information:subscriptions:read.
//   Used  GET  /projects/{project_id}/customers/{customer_id}/subscriptions
//         GET  /projects/{project_id}/subscriptions/{id}/authenticated_management_url
//              (for Paddle: "a short-lived authenticated Paddle Customer
//              Portal URL", or null)
// RevenueCat's own cancel / refund endpoints are for RevenueCat Billing
// subscriptions only, not Paddle ones — cancelling a Paddle subscription
// (account deletion) still goes to Paddle's API (paddleClient.js).
const BASE = "https://api.revenuecat.com/v2";

class RevenueCatError extends Error {
  constructor(status, body, code) {
    super((body && (body.message || (body.error && body.error.message))) || `RevenueCat ${status}`);
    this.status = status;
    this.code = code || (body && (body.type || body.code)) || "revenuecat_error";
  }
}

const isSet = (v) => typeof v === "string" && v.trim() !== "" && v.trim() !== "-";

async function request(secretKey, method, path, body, { fetchImpl = fetch } = {}) {
  if (!isSet(secretKey)) throw new RevenueCatError(503, null, "not_configured");
  const res = await fetchImpl(`${BASE}${path}`, {
    method,
    headers: { Authorization: `Bearer ${secretKey.trim()}`, "Content-Type": "application/json" },
    body: method === "GET" ? undefined : JSON.stringify(body || {}),
  });
  const text = await res.text();
  let json = null;
  try {
    json = text ? JSON.parse(text) : null;
  } catch (_) {
    json = { message: text.slice(0, 200) };
  }
  if (!res.ok) throw new RevenueCatError(res.status, json);
  return json;
}

const enc = encodeURIComponent;

// The customer's subscriptions (every store), or [] for a customer
// RevenueCat has never seen.
async function subscriptions(secretKey, projectId, uid, { fetchImpl } = {}) {
  try {
    const res = await request(secretKey, "GET", `/projects/${enc(projectId)}/customers/${enc(uid)}/subscriptions?limit=50`, null, { fetchImpl });
    return Array.isArray(res && res.items) ? res.items : [];
  } catch (err) {
    if (err instanceof RevenueCatError && err.status === 404) return [];
    throw err;
  }
}

// Pure: the Paddle subscription that matters — the one giving access, else
// the latest one. null when there is none.
function paddleSubscription(items) {
  const paddle = (items || []).filter((s) => s && String(s.store || "").toLowerCase() === "paddle");
  if (!paddle.length) return null;
  const end = (s) => Number(s.current_period_ends_at) || 0;
  const live = paddle.filter((s) => s.gives_access === true).sort((a, b) => end(b) - end(a));
  return live[0] || paddle.sort((a, b) => end(b) - end(a))[0];
}

// Pure: whether a Paddle subscription may still charge the customer (the
// one account deletion must stop).
function stillCharges(sub) {
  if (!sub) return false;
  const status = String(sub.status || "");
  if (status === "expired") return false;
  return String(sub.auto_renewal_status || "") !== "will_not_renew";
}

async function managementUrl(secretKey, projectId, sub, { fetchImpl } = {}) {
  try {
    const res = await request(secretKey, "GET", `/projects/${enc(projectId)}/subscriptions/${enc(sub.id)}/authenticated_management_url`, null, { fetchImpl });
    const url = res && (res.management_url || res.url);
    if (typeof url === "string" && url) return url;
  } catch (err) {
    if (!(err instanceof RevenueCatError) || err.status >= 500) throw err;
  }
  return typeof sub.management_url === "string" && sub.management_url ? sub.management_url : null;
}

module.exports = { BASE, RevenueCatError, isSet, request, subscriptions, paddleSubscription, stillCharges, managementUrl };
