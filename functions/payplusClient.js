// A thin PayPlus REST client (docs.payplus.co.il). PayPlus is the Israeli
// processor behind web Premium for Israeli accounts: a hosted payment page
// (cards, Apple Pay, Google Pay, bit where the page allows it) that sets up a
// recurring charge ("הוראת קבע", charge_method 3), and an HTTPS callback per
// successful charge or refund. No SDK: JSON over fetch, like stripeClient.js.
//
//   Production  https://restapi.payplus.co.il/api/v1.0/
//   Staging     https://restapidev.payplus.co.il/api/v1.0/
//   Auth        headers `api-key` and `secret-key` (server-side only)
//   Callbacks   header `hash` = base64(HMAC-SHA256(secret-key, JSON body)),
//               header `user-agent: PayPlus`
//               (docs: "Validate Requests Received from PayPlus")
const crypto = require("node:crypto");

const BASES = {
  production: "https://restapi.payplus.co.il/api/v1.0",
  staging: "https://restapidev.payplus.co.il/api/v1.0",
};

class PayPlusError extends Error {
  constructor(status, body, code) {
    const results = (body && (body.results || body.result)) || {};
    super(results.description || (typeof body === "string" ? body : "") || `PayPlus ${status}`);
    this.status = status;
    this.code = code || results.code || "payplus_error";
  }
}

// "-" is the placeholder stored until the real value exists (see
// stripeClient.js): every function bound to the secret still deploys.
const isSet = (v) => typeof v === "string" && v.trim() !== "" && v.trim() !== "-";

// keys = { apiKey, secretKey, terminalUid, pageUid, env }
function configured(keys) {
  return !!keys && isSet(keys.apiKey) && isSet(keys.secretKey) && isSet(keys.terminalUid) && isSet(keys.pageUid);
}

function baseFor(env) {
  return env === "staging" ? BASES.staging : BASES.production;
}

async function request(keys, method, path, body, { fetchImpl = fetch, query } = {}) {
  if (!configured(keys)) throw new PayPlusError(503, null, "not_configured");
  const qs = query ? `?${new URLSearchParams(Object.entries(query).filter(([, v]) => v !== undefined && v !== null)).toString()}` : "";
  const res = await fetchImpl(`${baseFor(keys.env)}${path}${qs}`, {
    method,
    headers: { "Content-Type": "application/json", "api-key": keys.apiKey.trim(), "secret-key": keys.secretKey.trim() },
    body: method === "GET" ? undefined : JSON.stringify(body || {}),
  });
  const text = await res.text();
  let json = null;
  try {
    json = text ? JSON.parse(text) : null;
  } catch (_) {
    json = text.slice(0, 200);
  }
  if (!res.ok) throw new PayPlusError(res.status, json);
  // PayPlus answers 200 with results.status "error" for a refused request.
  const results = json && typeof json === "object" ? json.results || json.result : null;
  if (results && typeof results.status === "string" && results.status.toLowerCase() !== "success") {
    throw new PayPlusError(422, json);
  }
  return json;
}

function hmac(secret, payload) {
  return crypto.createHmac("sha256", secret).update(payload).digest("base64");
}

function sameString(a, b) {
  const x = Buffer.from(String(a));
  const y = Buffer.from(String(b));
  return x.length === y.length && crypto.timingSafeEqual(x, y);
}

// Why a callback is refused, or null when it is genuine. PayPlus signs
// JSON.stringify(body); the raw body is that string unless something
// re-serialised it, so the raw bytes are tried first and the re-serialised
// parse second (both constant-time). Pure, so the one security decision has
// a unit test.
function verifyCallback(headers, rawBody, secret) {
  if (!isSet(secret)) return "not_configured";
  const get = (name) => {
    if (!headers) return undefined;
    if (typeof headers.get === "function") return headers.get(name);
    return headers[name] ?? headers[name.toLowerCase()];
  };
  const ua = String(get("user-agent") || "");
  if (!/^PayPlus\b/.test(ua)) return "user_agent";
  const given = get("hash");
  if (typeof given !== "string" || !given) return "missing";
  const raw = Buffer.isBuffer(rawBody) ? rawBody.toString("utf8") : String(rawBody ?? "");
  if (!raw) return "missing";
  if (sameString(hmac(secret.trim(), raw), given)) return null;
  try {
    const reserialised = JSON.stringify(JSON.parse(raw));
    if (reserialised !== raw && sameString(hmac(secret.trim(), reserialised), given)) return null;
  } catch (_) {
    return "malformed";
  }
  return "mismatch";
}

// For tests: the headers PayPlus would send for a body.
function sign(rawBody, secret) {
  return { "user-agent": "PayPlus", hash: hmac(secret, String(rawBody)) };
}

// "2026-10-18 12:32:52" is Israel local time (the callback's
// transaction.date): → epoch ms, or null.
function israelMs(text) {
  const m = /^(\d{4})-(\d{2})-(\d{2})[ T](\d{2}):(\d{2})(?::(\d{2}))?/.exec(String(text || ""));
  if (!m) return null;
  const [y, mo, d, h, mi, s] = m.slice(1).map((v) => Number(v || 0));
  const asUtc = Date.UTC(y, mo - 1, d, h, mi, s);
  // The zone's offset at that instant (IST +2 / IDT +3).
  const parts = new Intl.DateTimeFormat("en-US", { timeZone: "Asia/Jerusalem", hourCycle: "h23", year: "numeric", month: "2-digit", day: "2-digit", hour: "2-digit", minute: "2-digit", second: "2-digit" }).formatToParts(new Date(asUtc));
  const get = (t) => Number(parts.find((p) => p.type === t).value);
  const shown = Date.UTC(get("year"), get("month") - 1, get("day"), get("hour"), get("minute"), get("second"));
  return asUtc - (shown - asUtc);
}

module.exports = { BASES, PayPlusError, configured, isSet, baseFor, request, verifyCallback, sign, israelMs };
