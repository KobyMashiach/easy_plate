// Plan gates the console controls through Remote Config, read server-side
// so a push is withheld for the same accounts the app keeps out. The
// template is cached per instance: a push must not cost a config fetch.
const admin = require("firebase-admin");
const { logger } = require("firebase-functions");

const CACHE_MS = 5 * 60 * 1000;
// A failed read is retried soon, not after the full cache window.
const RETRY_MS = 30 * 1000;
let cache = { at: 0, params: null };
// The read in flight, shared: a cold instance taking a burst of requests
// used to fire one getTemplate per request until the first one landed.
let inflight = null;
// How long one template read may take. Every paid endpoint and every push
// waits on it (shared, above), so a hung read used to hold them all until
// their own function timeouts; past this the last good read (or the
// fallbacks) applies and the read is retried after RETRY_MS.
const READ_TIMEOUT_MS = 5000;

function withTimeout(promise, ms) {
  let timer;
  const deadline = new Promise((_resolve, reject) => {
    timer = setTimeout(() => reject(new Error(`remote config read timed out after ${ms} ms`)), ms);
  });
  return Promise.race([promise, deadline]).finally(() => clearTimeout(timer));
}

async function params(now = Date.now(), getTemplate = () => admin.remoteConfig().getTemplate(), timeoutMs = READ_TIMEOUT_MS) {
  const ttl = cache.params === null ? RETRY_MS : CACHE_MS;
  if (now - cache.at < ttl) return cache.params || {};
  if (!inflight) {
    inflight = (async () => {
      try {
        const template = await withTimeout(Promise.resolve().then(getTemplate), timeoutMs);
        cache = { at: now, params: flatten(template) };
      } catch (error) {
        // The last good read stays in force; with none, the in-code defaults
        // apply (gated), and the outage is an error, not a whisper.
        logger.error("remote config template unavailable; in-code defaults apply (pushes gated, quotas at their fallbacks)", { reason: String(error?.message || error) });
        cache = { at: now, params: cache.params };
      } finally {
        inflight = null;
      }
    })();
  }
  await inflight;
  return cache.params || {};
}

function resetForTest() {
  cache = { at: 0, params: null };
  inflight = null;
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
// group): 0 hidden, 1 coming soon, 2 on for everyone, 3 Premium only,
// 4 under maintenance.
function intFrom(parameters, name, fallback) {
  const raw = parameters?.[name]?.defaultValue?.value;
  if (raw === undefined || raw === null || String(raw).trim() === "") return fallback;
  const parsed = parseInt(String(raw).trim(), 10);
  return Number.isInteger(parsed) ? parsed : fallback;
}

// Whether a feature flag's value lets the feature run at all: 2 (everyone)
// or 3 (Premium). 0 hidden, 1 coming soon and 4 maintenance are closed; a
// plain `>= 2` would open maintenance.
function isOpen(flag) {
  return flag === 2 || flag === 3;
}

// Pure rule: a push goes out when the feature is on for everyone, or on
// for Premium and this account pays. Hidden, coming soon or maintenance
// sends nothing.
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

// What the notifications flag reads as when Remote Config gave nothing (no
// template read yet, or the parameter missing): gated. It used to be 2 —
// everyone — so an outage at cold start opened pushes the console had
// limited to Premium. The template always carries the flag, so a good read
// never falls back.
const NOTIFICATIONS_FALLBACK = 0;

async function pushAllowedFor(userSnap) {
  const p = await params();
  return pushAllowed({
    flag: intFrom(p, NOTIFICATIONS_FLAG, NOTIFICATIONS_FALLBACK),
    premium: isPremium(userSnap),
  });
}

const NOTIFICATIONS_FLAG = "ff_notifications";

module.exports = { READ_TIMEOUT_MS, resetForTest, isOpen, pushAllowed, boolFrom, intFrom, flatten, isPremium, pushAllowedFor, params, NOTIFICATIONS_FLAG, NOTIFICATIONS_FALLBACK };
