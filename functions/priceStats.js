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

const COLLECTION = "price_stats";
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

function keyFor(normalized) {
  return crypto.createHash("sha256").update(normalized).digest("hex");
}

function median(values) {
  const sorted = [...values].sort((a, b) => a - b);
  const mid = Math.floor(sorted.length / 2);
  return sorted.length % 2 ? sorted[mid] : (sorted[mid - 1] + sorted[mid]) / 2;
}

// Pure: what the document becomes after one more price.
function fold(existing, price, now) {
  const recent = [...((existing && existing.recent) || []), price].slice(-RECENT_KEEP);
  const count = ((existing && existing.count) || 0) + 1;
  const sum = ((existing && existing.sum) || 0) + price;
  return {
    count,
    sum,
    avg: Math.round((sum / count) * 100) / 100,
    median: Math.round(median(recent) * 100) / 100,
    recent,
    updatedAt: now,
  };
}

function validRecord(r) {
  if (!r || typeof r !== "object") return null;
  const normalized = normalizeName(r.name);
  const price = Number(r.price);
  if (!normalized || !Number.isFinite(price) || price <= 0 || price > MAX_PRICE) return null;
  return { name: String(r.name).trim().slice(0, 120), normalized, price };
}

exports.priceStats = onRequest(
  { region: "europe-west1", minInstances: 0, maxInstances: 5, timeoutSeconds: 60, cors: false },
  async (req, res) => {
    if (req.method !== "POST") return res.status(405).json({ error: { message: "POST only" } });
    const caller = await proxy.verifyCaller(req);
    if (!caller) return res.status(401).json({ error: { message: "A valid Firebase ID token is required" } });

    const records = Array.isArray(req.body && req.body.records) ? req.body.records : [];
    const valid = records.map(validRecord).filter(Boolean).slice(0, MAX_RECORDS);
    if (valid.length === 0) return res.status(400).json({ error: { message: "no valid records" } });

    const db = admin.firestore();
    let written = 0;
    for (const record of valid) {
      const ref = db.collection(COLLECTION).doc(keyFor(record.normalized));
      try {
        await db.runTransaction(async (tx) => {
          const snap = await tx.get(ref);
          const next = fold(snap.exists ? snap.data() : null, record.price, Date.now());
          tx.set(ref, { name: record.name, normalized: record.normalized, ...next }, { merge: true });
        });
        written++;
      } catch (err) {
        logger.warn("price stat write failed", { key: record.normalized, reason: err.message });
      }
    }
    logger.info("prices shared", { uid: caller.uid, received: records.length, written });
    return res.status(200).json({ ok: true, written });
  },
);

exports.internals = { normalizeName, keyFor, fold, median, validRecord, COLLECTION };
