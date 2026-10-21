// A thin Paddle Billing REST client (developer.paddle.com). Paddle is the
// merchant of record for web Premium bought outside Israel. Since 2026-10-18
// the checkout, the notifications and the entitlement go through RevenueCat
// (its Paddle Billing integration — revenueCatClient.js, revenueCatWebhook.js);
// we call Paddle directly for one thing only: cancelling a subscription when
// its account is deleted (RevenueCat's cancel endpoint covers RevenueCat
// Billing, not Paddle). verifySignature / sign serve the retired
// paddleWebhook.js, kept for reference and no longer exported.
//
//   API         https://api.paddle.com  (sandbox: https://sandbox-api.paddle.com)
//               Authorization: Bearer <API key>; the key itself says which
//               environment it belongs to (pdl_sdbx_… / pdl_live_…).
//   Webhooks    header Paddle-Signature: ts=<unix>;h1=<hex>
//               h1 = HMAC-SHA256(endpoint secret, `${ts}:${rawBody}`)
const crypto = require("node:crypto");

const BASES = { production: "https://api.paddle.com", sandbox: "https://sandbox-api.paddle.com" };

class PaddleError extends Error {
  constructor(status, body, code) {
    const err = (body && body.error) || {};
    super(err.detail || err.code || `Paddle ${status}`);
    this.status = status;
    this.code = code || err.code || "paddle_error";
  }
}

const isSet = (v) => typeof v === "string" && v.trim() !== "" && v.trim() !== "-";

function environmentOf(apiKey) {
  return /_sdbx_/.test(String(apiKey || "")) ? "sandbox" : "production";
}

async function request(apiKey, method, path, body, { fetchImpl = fetch } = {}) {
  if (!isSet(apiKey)) throw new PaddleError(503, null, "not_configured");
  const res = await fetchImpl(`${BASES[environmentOf(apiKey)]}${path}`, {
    method,
    headers: { Authorization: `Bearer ${apiKey.trim()}`, "Content-Type": "application/json", "Paddle-Version": "1" },
    body: method === "GET" ? undefined : JSON.stringify(body || {}),
  });
  const text = await res.text();
  let json = null;
  try {
    json = text ? JSON.parse(text) : null;
  } catch (_) {
    json = { error: { detail: text.slice(0, 200) } };
  }
  if (!res.ok) throw new PaddleError(res.status, json);
  return json;
}

// Why a webhook is refused, or null when it is genuine. Several h1 values
// may arrive during a secret rotation; any match passes. `toleranceSec`
// bounds replays of a captured request (Paddle signs each delivery afresh).
function verifySignature(header, rawBody, secret, { nowMs = Date.now(), toleranceSec = 300 } = {}) {
  if (!isSet(secret)) return "not_configured";
  if (typeof header !== "string" || !header) return "missing";
  let ts = null;
  const sigs = [];
  for (const piece of header.split(";")) {
    const i = piece.indexOf("=");
    if (i < 0) continue;
    const k = piece.slice(0, i).trim();
    const v = piece.slice(i + 1).trim();
    if (k === "ts") ts = v;
    else if (k === "h1") sigs.push(v);
  }
  if (!ts || !/^\d+$/.test(ts) || sigs.length === 0) return "malformed";
  if (Math.abs(nowMs / 1000 - Number(ts)) > toleranceSec) return "stale";
  const payload = Buffer.isBuffer(rawBody) ? rawBody : Buffer.from(String(rawBody ?? ""), "utf8");
  const expected = Buffer.from(crypto.createHmac("sha256", secret.trim()).update(Buffer.concat([Buffer.from(`${ts}:`), payload])).digest("hex"));
  const ok = sigs.some((sig) => {
    const given = Buffer.from(sig);
    return given.length === expected.length && crypto.timingSafeEqual(given, expected);
  });
  return ok ? null : "mismatch";
}

// For tests: the header Paddle would send.
function sign(rawBody, secret, tsSec) {
  const h1 = crypto.createHmac("sha256", secret).update(`${tsSec}:${rawBody}`).digest("hex");
  return `ts=${tsSec};h1=${h1}`;
}

// Cancels a subscription (POST /subscriptions/{id}/cancel). Already
// cancelled / gone counts as done-by-someone-else: false, not an error.
async function cancelSubscription(apiKey, subscriptionId, when = "immediately", fetchImpl) {
  if (!subscriptionId) return false;
  try {
    await request(apiKey, "POST", `/subscriptions/${encodeURIComponent(subscriptionId)}/cancel`, { effective_from: when }, { fetchImpl });
  } catch (err) {
    if (err instanceof PaddleError && (err.code === "subscription_locked_pending_changes" || err.code === "subscription_update_when_canceled" || err.status === 404)) return false;
    throw err;
  }
  return true;
}

module.exports = { BASES, PaddleError, isSet, environmentOf, request, verifySignature, sign, cancelSubscription };
