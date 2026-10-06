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

// Pure rule: a free account gets no push while the gate is on.
function pushAllowed({ premiumOnly, premium }) {
  return !premiumOnly || premium === true;
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
    premiumOnly: boolFrom(p, "notifications_premium_only", true),
    premium: isPremium(userSnap),
  });
}

module.exports = { pushAllowed, boolFrom, flatten, isPremium, pushAllowedFor, params };
