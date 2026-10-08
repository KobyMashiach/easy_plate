// Plan gates the console controls through Remote Config, read server-side
// so a push is withheld for the same accounts the app keeps out. The
// template is cached per instance: a push must not cost a config fetch.
const admin = require("firebase-admin");
const { logger } = require("firebase-functions");

const CACHE_MS = 5 * 60 * 1000;
// A failed read is retried soon, not after the full cache window.
const RETRY_MS = 30 * 1000;
let cache = { at: 0, params: null };

async function params(now = Date.now()) {
  const ttl = cache.params === null ? RETRY_MS : CACHE_MS;
  if (now - cache.at < ttl) return cache.params || {};
  try {
    const template = await admin.remoteConfig().getTemplate();
    cache = { at: now, params: flatten(template) };
  } catch (error) {
    // The last good read stays in force; with none, the in-code defaults
    // apply (gated), and the outage is an error, not a whisper.
    logger.error("remote config template unavailable; pushes gated by default", { reason: String(error?.message || error) });
    cache = { at: now, params: cache.params };
  }
  return cache.params || {};
}

// A parameter may sit in a parameter group in the console; groups are
// folded into one flat map before lookup.
function flatten(template) {
  const flat = { ...(template?.parameters || {}) };
  for (const group of Object.values(template?.parameterGroups || {})) {
    Object.assign(flat, group?.parameters || {});
  }
  return flat;
}

function boolFrom(parameters, name, fallback) {
  const raw = parameters?.[name]?.defaultValue?.value;
  if (raw === undefined || raw === null || String(raw).trim() === "") return fallback;
  return String(raw).trim().toLowerCase() === "true";
}

// The notifications feature flag (`ff_notifications`, in the featureFlags
// group): 0 hidden, 1 coming soon, 2 on for everyone, 3 Premium only.
function intFrom(parameters, name, fallback) {
  const raw = parameters?.[name]?.defaultValue?.value;
  if (raw === undefined || raw === null || String(raw).trim() === "") return fallback;
  const parsed = parseInt(String(raw).trim(), 10);
  return Number.isInteger(parsed) ? parsed : fallback;
}

// Pure rule: a push goes out when the feature is on for everyone, or on
// for Premium and this account pays. Hidden or coming soon sends nothing.
function pushAllowed({ flag, premium }) {
  if (flag === 2) return true;
  if (flag === 3) return premium === true;
  return false;
}

function toMillis(value) {
  if (!value) return null;
  if (typeof value.toMillis === "function") return value.toMillis();
  if (value instanceof Date) return value.getTime();
  return null;
}

// The same verdict the app reaches (EntitlementService.resolvePremium): the
// flag, honoured only inside its [premiumFrom, premiumUntil) window.
function isPremium(userSnapOrData, nowMs = Date.now()) {
  const get = (field) =>
    userSnapOrData?.get ? userSnapOrData.get(field) : userSnapOrData?.[field];
  if (get("premium") !== true) return false;
  const from = toMillis(get("premiumFrom"));
  if (from !== null && from > nowMs) return false;
  const until = toMillis(get("premiumUntil"));
  if (until !== null) return until > nowMs;
  return true;
}

async function pushAllowedFor(userSnap) {
  const p = await params();
  return pushAllowed({
    flag: intFrom(p, NOTIFICATIONS_FLAG, 2),
    premium: isPremium(userSnap),
  });
}

const NOTIFICATIONS_FLAG = "ff_notifications";

module.exports = { pushAllowed, boolFrom, intFrom, flatten, isPremium, pushAllowedFor, params, NOTIFICATIONS_FLAG };
