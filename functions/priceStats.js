// Community price averages. A user who scanned a receipt may share what
// they paid; this keeps one running aggregate per product name so anyone
// can ask "what does this usually cost?" without ever seeing another
// person's receipt. Written only here (rules refuse client writes), read by
// any signed-in user.
//
// Names are normalised the same way the app does (lower-case, punctuation
// and niqqud stripped, spaces collapsed) so "חלב 3%" and "חלב 3% " land on
// the same document. The document id is the hash of that key.
const crypto = require("node:crypto");
const { onRequest } = require("firebase-functions/v2/https");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");
const proxy = require("./aiProxy").internals;
const budget = require("./dailyBudget");
// The website (aieasyplate.app/app) calls this from the browser too.
const { ORIGINS } = require("./origins");

const COLLECTION = "price_stats";
const WINDOW_COLLECTION = "price_stats_window";
const MAX_RECORDS = 200;
const MAX_PRICE = 10000;
// The last N prices are kept so the median can be re-derived; the mean
// alone is dragged by one mistyped 1,000 instead of 10.
const RECENT_KEEP = 25;

function normalizeName(raw) {
  return String(raw || "")
    .toLowerCase()
    .replace(/[֑-ׇ]/g, "")
    .replace(/[^\p{L}\p{N}%\s]/gu, " ")
    .replace(/\s+/g, " ")
    .trim();
}

// What a price is per (price_unit.dart / PRICE_UNITS on the web) and the
// currency it was paid in. Optional on a request: a client that sends
// neither feeds — and reads — the legacy per-name document, as before.
const UNITS = new Set(["unit", "kg", "liter"]);
const DEFAULT_CURRENCY = "ILS";

// The document id. Without a unit and in shekels: sha256 of the name, the
// key every existing client computes (that aggregate mixes per-kg and
// per-package prices — it is what old clients keep using). With a unit, or
// in another currency: sha256 of "name|unit|currency" ("|" never survives
// normalizeName, so no name can collide with a keyed one).
function keyFor(normalized, unit = null, currency = DEFAULT_CURRENCY) {
  const legacy = !unit && currency === DEFAULT_CURRENCY;
  const source = legacy ? normalized : `${normalized}|${unit || ""}|${currency}`;
  return crypto.createHash("sha256").update(source).digest("hex");
}

function median(values) {
  const sorted = [...values].sort((a, b) => a - b);
  const mid = Math.floor(sorted.length / 2);
  return sorted.length % 2 ? sorted[mid] : (sorted[mid - 1] + sorted[mid]) / 2;
}

// A short tag for who gave a price in the window: enough to tell two
// accounts apart. Kept server-side only (WINDOW_COLLECTION).
function contributorTag(uid) {
  return uid ? crypto.createHash("sha256").update(`price:${uid}`).digest("hex").slice(0, 16) : null;
}

// Pure: what the document becomes after one more price. The window keeps
// one price per account (`recentBy`, parallel to `recent`): a new price
// from an account already in it replaces that account's earlier one. The
// window used to take any number from one account, so 25 records of a
// made-up price — one request, or a few — set the median for everyone.
function fold(existing, price, now, contributor = null) {
  const prevRecent = (existing && Array.isArray(existing.recent)) ? existing.recent : [];
  const prevBy = existing && Array.isArray(existing.recentBy) && existing.recentBy.length === prevRecent.length
    ? existing.recentBy
    : prevRecent.map(() => null);
  let recent = [...prevRecent];
  let recentBy = [...prevBy];
  const mine = contributor ? recentBy.indexOf(contributor) : -1;
  if (mine >= 0) {
    recent.splice(mine, 1);
    recentBy.splice(mine, 1);
  }
  recent = [...recent, price].slice(-RECENT_KEEP);
  recentBy = [...recentBy, contributor].slice(-RECENT_KEEP);
  const count = ((existing && existing.count) || 0) + 1;
  const sum = ((existing && existing.sum) || 0) + price;
  return {
    count,
    sum,
    avg: Math.round((sum / count) * 100) / 100,
    median: Math.round(median(recent) * 100) / 100,
    recent,
    recentBy,
    updatedAt: now,
  };
}

// An unknown unit or a malformed currency refuses the record rather than
// falling back: folding it into the wrong aggregate is what the unit is for.
function validRecord(r) {
  if (!r || typeof r !== "object") return null;
  const normalized = normalizeName(String(r.name || "").slice(0, 120));
  const price = Number(r.price);
  if (!normalized || !Number.isFinite(price) || price <= 0 || price > MAX_PRICE) return null;
  let unit = null;
  if (r.unit !== undefined && r.unit !== null) {
    if (typeof r.unit !== "string" || !UNITS.has(r.unit)) return null;
    unit = r.unit;
  }
  let currency = DEFAULT_CURRENCY;
  if (r.currency !== undefined && r.currency !== null) {
    if (typeof r.currency !== "string" || !/^[A-Za-z]{3}$/.test(r.currency)) return null;
    currency = r.currency.toUpperCase();
  }
  return { name: String(r.name).trim().slice(0, 120), normalized, price, unit, currency, key: keyFor(normalized, unit, currency) };
}

// One request: the valid records, counted against the caller's day before
// anything is folded in (the aggregates are everyone's, so one account must
// not be able to feed them without limit), then one transaction per product.
// Returns the status and body to send. `spend` is dailyBudget.spend unless a
// test passes its own.
async function share(db, uid, records, { spend = budget.spend, now = Date.now } = {}) {
  const received = Array.isArray(records) ? records : [];
  // Bounded before any work is done on it, and one price per product per
  // request (a receipt with the same item twice counts it once).
  const seen = new Set();
  const valid = received.slice(0, MAX_RECORDS).map(validRecord).filter((r) => {
    if (!r || seen.has(r.key)) return false;
    seen.add(r.key);
    return true;
  });
  if (valid.length === 0) return { status: 400, body: { error: { message: "no valid records" } } };

  const decision = await spend({ uid, kind: "priceRecords", amount: valid.length, db });
  if (!decision.allowed) {
    logger.info("price records budget exhausted", { uid, used: decision.used, limit: decision.limit });
    return { status: 429, body: budget.refusalBody(decision, "priceRecords") };
  }

  let written = 0;
  for (const record of valid) {
    const ref = db.collection(COLLECTION).doc(record.key);
    try {
      await db.runTransaction(async (tx) => {
        // Who gave each price in the window lives in a document no client
        // can read (the catch-all rule closes it): beside the public
        // aggregate it would have linked a forum author's uid to what they
        // buy.
        const windowRef = db.collection(WINDOW_COLLECTION).doc(ref.id);
        const [snap, windowSnap] = await Promise.all([tx.get(ref), tx.get(windowRef)]);
        const existing = snap.exists ? { ...snap.data(), recentBy: windowSnap.exists ? windowSnap.get("recentBy") : null } : null;
        const { recentBy, ...next } = fold(existing, record.price, now(), contributorTag(uid));
        // unit/currency only on the keyed documents: the legacy one stays
        // the shape old clients read.
        const labels = record.unit || record.currency !== DEFAULT_CURRENCY ? { unit: record.unit, currency: record.currency } : {};
        tx.set(ref, { name: record.name, normalized: record.normalized, ...labels, ...next }, { merge: true });
        tx.set(windowRef, { recentBy });
      });
      written++;
    } catch (err) {
      logger.warn("price stat write failed", { key: record.normalized, unit: record.unit, currency: record.currency, reason: err.message });
    }
  }
  logger.info("prices shared", { uid, received: received.length, written });
  return { status: 200, body: { ok: true, written } };
}

exports.priceStats = onRequest(
  { region: "europe-west1", minInstances: 0, maxInstances: 5, timeoutSeconds: 60, cors: ORIGINS },
  async (req, res) => {
    if (req.method !== "POST") return res.status(405).json({ error: { message: "POST only" } });
    const caller = await proxy.verifyCaller(req);
    if (!caller) return res.status(401).json({ error: { message: "A valid Firebase ID token is required" } });
    // Switched off from the console (the `disabled` claim, adminUsers.disable).
    if (caller.disabled === true) return res.status(403).json({ error: { code: "account_disabled", message: "This account is disabled" } });
    try {
      const out = await share(admin.firestore(), caller.uid, req.body && req.body.records);
      return res.status(out.status).json(out.body);
    } catch (err) {
      // The day's budget could not be read or claimed (contention, Firestore
      // unavailable): a refusal to retry, not an unhandled rejection.
      logger.error("price share failed", { uid: caller.uid, reason: err.message });
      return res.status(503).json({ error: { message: "Try again shortly" } });
    }
  },
);

exports.internals = { UNITS, DEFAULT_CURRENCY, contributorTag, normalizeName, keyFor, fold, median, validRecord, share, COLLECTION, WINDOW_COLLECTION, MAX_RECORDS };
