// A thin Stripe REST client. Node 20 ships `fetch`, and the three calls the
// web checkout needs (customers, checkout sessions, billing portal, prices)
// are plain form-encoded POST/GET requests — so there is no SDK dependency
// to keep in step with the API version. Webhook signatures are verified in
// stripeWebhook.js with the same HMAC scheme the SDK uses.
const crypto = require("node:crypto");

const API = "https://api.stripe.com/v1";
// Pinned on purpose: the shapes read in stripeWebhook.js (subscription
// items carrying the period, `current_period_end`) are those of this version.
const API_VERSION = "2025-08-27.basil";

class StripeError extends Error {
  constructor(status, body) {
    const err = (body && body.error) || {};
    super(err.message || `Stripe ${status}`);
    this.status = status;
    this.code = err.code || err.type || "stripe_error";
    this.param = err.param;
  }
}

// Stripe's nested form encoding: {a: {b: 1}, c: [x, y]} → a[b]=1&c[0]=x&c[1]=y.
// Null/undefined values are dropped, which is what lets a caller build the
// body with optional fields and not think about it.
function encode(params, prefix = "") {
  const parts = [];
  const push = (key, value) => parts.push(`${encodeURIComponent(key)}=${encodeURIComponent(String(value))}`);
  const walk = (value, key) => {
    if (value === null || value === undefined) return;
    if (Array.isArray(value)) {
      value.forEach((v, i) => walk(v, `${key}[${i}]`));
    } else if (typeof value === "object" && !(value instanceof Date)) {
      for (const [k, v] of Object.entries(value)) walk(v, key ? `${key}[${k}]` : k);
    } else if (typeof value === "boolean") {
      push(key, value ? "true" : "false");
    } else {
      push(key, value);
    }
  };
  walk(params, prefix);
  return parts.join("&");
}

// One call. GET carries its params in the query string, everything else in
// the form body. An idempotency key makes a retried checkout-session create
// return the same session instead of a second one.
async function request(secret, method, path, params = {}, { idempotencyKey, fetchImpl = fetch } = {}) {
  // "-" is the placeholder stored until the real key exists, so every
  // function bound to the secret can still deploy: treat it as unset.
  if (!secret || secret.trim() === "-") throw new StripeError(500, { error: { code: "not_configured", message: "STRIPE_SECRET_KEY is not set" } });
  const query = method === "GET" ? encode(params) : "";
  const url = `${API}${path}${query ? `?${query}` : ""}`;
  const headers = {
    Authorization: `Bearer ${secret}`,
    "Stripe-Version": API_VERSION,
    "Content-Type": "application/x-www-form-urlencoded",
  };
  if (idempotencyKey) headers["Idempotency-Key"] = idempotencyKey;
  const res = await fetchImpl(url, { method, headers, body: method === "GET" ? undefined : encode(params) });
  const text = await res.text();
  let body = null;
  try {
    body = text ? JSON.parse(text) : null;
  } catch (_) {
    body = { error: { message: text.slice(0, 200) } };
  }
  if (!res.ok) throw new StripeError(res.status, body);
  return body;
}

// `Stripe-Signature: t=<unix>,v1=<hex>[,v1=<hex>]` over `${t}.${rawBody}`.
// Pure, so the webhook's one security decision has a unit test. Returns the
// reason a header is refused, or null when it is good.
function verifySignature(header, rawBody, secret, { nowMs = Date.now(), toleranceSec = 300 } = {}) {
  if (typeof header !== "string" || !secret || secret.trim() === "-") return "missing";
  const parts = Object.create(null);
  for (const piece of header.split(",")) {
    const [k, v] = piece.split("=", 2);
    if (!k || v === undefined) continue;
    (parts[k.trim()] ||= []).push(v.trim());
  }
  const t = parts.t && parts.t[0];
  const sigs = parts.v1 || [];
  if (!t || sigs.length === 0 || !/^\d+$/.test(t)) return "malformed";
  if (Math.abs(nowMs / 1000 - Number(t)) > toleranceSec) return "stale";
  const payload = Buffer.isBuffer(rawBody) ? rawBody : Buffer.from(String(rawBody), "utf8");
  const expected = crypto.createHmac("sha256", secret).update(Buffer.concat([Buffer.from(`${t}.`), payload])).digest("hex");
  const expectedBuf = Buffer.from(expected);
  const ok = sigs.some((sig) => {
    const given = Buffer.from(sig);
    return given.length === expectedBuf.length && crypto.timingSafeEqual(given, expectedBuf);
  });
  return ok ? null : "mismatch";
}

// For tests: produce the header Stripe would send for a body.
function sign(rawBody, secret, tSec) {
  const payload = Buffer.isBuffer(rawBody) ? rawBody : Buffer.from(String(rawBody), "utf8");
  const v1 = crypto.createHmac("sha256", secret).update(Buffer.concat([Buffer.from(`${tSec}.`), payload])).digest("hex");
  return `t=${tSec},v1=${v1}`;
}

module.exports = { API, API_VERSION, StripeError, encode, request, verifySignature, sign };
