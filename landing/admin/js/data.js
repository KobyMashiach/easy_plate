// Reads the views share: personas, public profiles, the price table and
// the cost of a token tally — all straight from Firestore under the rules
// that open these collections to the administrator.
import { db, collection, doc, getDoc, getDocs, query, where, documentId, PERSONA_PREFIX } from "./firebase.js";
import { chunks } from "./api.js";
import { t } from "./i18n.js";

// How long after its last beat an account still counts as online: twice
// the app's heartbeat (60 s) plus a little, the same rule PresenceService
// documents on the app side.
export const ONLINE_WINDOW_MS = 150 * 1000;

export function isOnline(userDoc, now = Date.now()) {
  if (!userDoc || userDoc.online !== true) return false;
  const seen = userDoc.lastSeenAt && typeof userDoc.lastSeenAt.toMillis === "function" ? userDoc.lastSeenAt.toMillis() : 0;
  return now - seen <= ONLINE_WINDOW_MS;
}

export function isPersona(uid) {
  return typeof uid === "string" && uid.startsWith(PERSONA_PREFIX);
}

export function premiumActive(ent, now = Date.now()) {
  if (!ent || ent.premium !== true) return false;
  const from = ent.premiumFrom && ent.premiumFrom.toMillis ? ent.premiumFrom.toMillis() : null;
  if (from !== null && from > now) return false;
  const until = ent.premiumUntil && ent.premiumUntil.toMillis ? ent.premiumUntil.toMillis() : null;
  return until === null || until > now;
}

let personaCache = null;
export async function personas({ fresh = false } = {}) {
  if (personaCache && !fresh) return personaCache;
  const snap = await getDocs(collection(db, "seed_personas"));
  personaCache = snap.docs.map((d) => ({ uid: d.id, ...d.data() })).sort((a, b) => String(a.name).localeCompare(String(b.name)));
  return personaCache;
}

export function invalidatePersonas() {
  personaCache = null;
}

// [value, label] pairs for an "as" picker: the administrator first, then
// every persona.
export async function authorOptions() {
  const list = await personas();
  return [["me", t("common.me")], ...list.map((p) => [p.uid, p.name])];
}

export async function profiles(uids) {
  const ids = [...new Set(uids.filter(Boolean))];
  const out = {};
  await Promise.all(chunks(ids).map(async (chunk) => {
    const snap = await getDocs(query(collection(db, "public_profiles"), where(documentId(), "in", chunk)));
    for (const d of snap.docs) out[d.id] = d.data();
  }));
  return out;
}

export async function userDoc(uid) {
  const snap = await getDoc(doc(db, "users", uid));
  return snap.exists() ? { uid, ...snap.data() } : null;
}

// ---- pricing ----
const DEFAULT_PRICING = {
  models: { "gemini-3_8-flash": { input: 0.75, output: 3.75, cached: 0.075 } },
  usdToIls: 3.7,
  searchPerThousand: 14,
  source: "defaults",
};

export async function pricing() {
  try {
    const snap = await getDoc(doc(db, "admin_config", "pricing"));
    if (!snap.exists()) return DEFAULT_PRICING;
    const data = snap.data();
    return { ...DEFAULT_PRICING, ...data, models: data.models && Object.keys(data.models).length ? data.models : DEFAULT_PRICING.models };
  } catch (_) {
    return DEFAULT_PRICING;
  }
}

export function modelKey(model) {
  return String(model || "").replace(/\./g, "_");
}

export function modelName(key) {
  return String(key || "").replace(/_/g, ".");
}

export const ZERO = { calls: 0, cacheHits: 0, errors: 0, input: 0, output: 0, thoughts: 0, cached: 0, total: 0, imageOutput: 0, searches: 0 };

export function tally(map) {
  const n = (k) => Number((map && map[k]) || 0);
  return { calls: n("calls"), cacheHits: n("cacheHits"), errors: n("errors"), input: n("input"), output: n("output"), thoughts: n("thoughts"), cached: n("cached"), total: n("total"), imageOutput: n("imageOutput"), searches: n("searches") };
}

export function addTally(a, b) {
  const out = { ...ZERO };
  for (const k of Object.keys(ZERO)) out[k] = (a[k] || 0) + (b[k] || 0);
  return out;
}

// USD for one model's tally, the dashboard's formula: (input − cached)·in +
// cached·cachedIn + text output·out + image output·imageOut + searches.
export function costUsd(tallyFor, key, prices) {
  const price = prices.models[key] || prices.models["gemini-3_8-flash"] || { input: 0, output: 0, cached: 0 };
  const image = Math.min(tallyFor.imageOutput || 0, tallyFor.output || 0);
  const text = (tallyFor.output || 0) - image + (tallyFor.thoughts || 0);
  const inputPaid = Math.max(0, (tallyFor.input || 0) - (tallyFor.cached || 0));
  const usd = (inputPaid * (price.input || 0) + (tallyFor.cached || 0) * (price.cached || 0) + text * (price.output || 0) + image * (price.imageOutput || price.output || 0)) / 1e6
    + ((tallyFor.searches || 0) / 1000) * (prices.searchPerThousand || 0);
  return usd;
}

export function costIls(byModel, prices) {
  let usd = 0;
  for (const [key, map] of Object.entries(byModel || {})) usd += costUsd(tally(map), key, prices);
  return usd * (prices.usdToIls || 3.7);
}

export function platformLabel(p) {
  switch (String(p || "").toLowerCase()) {
    case "ios": return "iOS";
    case "android": return "Android";
    case "": return "—";
    default: return p;
  }
}
