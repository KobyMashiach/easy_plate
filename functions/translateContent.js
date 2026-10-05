// Translating the account's own content — recipe titles, ingredient lines,
// steps, book and plan names, shopping items — so the app can be read end to
// end in whichever language was picked.
//
// Two caches sit in front of the model, because tokens are the only part of
// this that costs real money:
//
//   translation_cache/{sha256(lang|text)}   every line anyone ever translated
//   users/{uid}/i18n/{lang}/{type}/{id}     this account's finished variants
//
// The first means a line like "2 כוסות קמח" is translated once for everybody;
// the second means a reinstall or a second phone downloads the work instead
// of paying for it again. The source text is never overwritten: going back to
// the language a recipe was written in needs no model at all.
const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");
const crypto = require("node:crypto");

const proxy = require("./aiProxy").internals;
const aiUsage = require("./aiUsage");

const geminiApiKey = defineSecret("GEMINI_API_KEY");

const CACHE_COLLECTION = "translation_cache";
const MODEL = "gemini-3.8-flash";

// Lines per model call. Large enough that the instruction is amortised,
// small enough that one bad answer does not cost a whole library.
const BATCH = 60;
// A Firestore getAll takes a few hundred at a time; a library of a thousand
// recipes is read in a handful of round trips.
const LOOKUP_CHUNK = 250;
const MAX_ITEMS = 2000;
const MAX_TEXT = 2000;

const LANGUAGE_NAMES = {
  he: "Hebrew",
  en: "English",
  ar: "Arabic",
  fr: "French",
  ru: "Russian",
};

/// The fields each kind of record carries, and whether each is one string or
/// a list of them. Anything not named here — ids, numbers, units, enums,
/// image paths — is never sent to the model.
const SHAPES = {
  recipe: { title: "text", ingredients: "list", steps: "list" },
  book: { title: "text" },
  mealPlan: { name: "text", meals: "list", items: "list" },
  groceryList: { name: "text", items: "list" },
};

function cacheKey(lang, text) {
  return crypto.createHash("sha256").update(`${lang}\n${text}`).digest("hex");
}

/// Every distinct string in the request, in the order first seen. Blank and
/// over-long values are left alone rather than sent anywhere.
function collectStrings(items) {
  const seen = new Set();
  const out = [];
  for (const item of items) {
    const shape = SHAPES[item.type];
    if (!shape) continue;
    for (const [field, kind] of Object.entries(shape)) {
      const value = item.fields ? item.fields[field] : undefined;
      const values = kind === "list" ? (Array.isArray(value) ? value : []) : [value];
      for (const text of values) {
        if (typeof text !== "string") continue;
        const trimmed = text.trim();
        if (!trimmed || trimmed.length > MAX_TEXT || seen.has(trimmed)) continue;
        seen.add(trimmed);
        out.push(trimmed);
      }
    }
  }
  return out;
}

/// Rebuilds each record with its strings swapped for the translated ones.
/// A line the model did not return keeps its original, so a partial answer
/// degrades to mixed language rather than to holes.
function applyTranslations(items, table) {
  const out = {};
  for (const item of items) {
    const shape = SHAPES[item.type];
    if (!shape) continue;
    const fields = {};
    for (const [field, kind] of Object.entries(shape)) {
      const value = item.fields ? item.fields[field] : undefined;
      if (kind === "list") {
        fields[field] = (Array.isArray(value) ? value : []).map((text) =>
          typeof text === "string" ? table[text.trim()] || text : text,
        );
      } else if (typeof value === "string") {
        fields[field] = table[value.trim()] || value;
      }
    }
    out[item.id] = { type: item.type, fields };
  }
  return out;
}

async function readCache(lang, strings) {
  const db = admin.firestore();
  const table = {};
  for (let i = 0; i < strings.length; i += LOOKUP_CHUNK) {
    const slice = strings.slice(i, i + LOOKUP_CHUNK);
    const refs = slice.map((text) => db.collection(CACHE_COLLECTION).doc(cacheKey(lang, text)));
    const snaps = await db.getAll(...refs);
    snaps.forEach((snap, index) => {
      const value = snap.exists ? snap.get("text") : null;
      if (typeof value === "string" && value) table[slice[index]] = value;
    });
  }
  return table;
}

async function writeCache(lang, pairs) {
  const db = admin.firestore();
  const entries = Object.entries(pairs);
  for (let i = 0; i < entries.length; i += 400) {
    const batch = db.batch();
    for (const [source, text] of entries.slice(i, i + 400)) {
      batch.set(db.collection(CACHE_COLLECTION).doc(cacheKey(lang, source)), {
        lang,
        text,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }
}

function instructionFor(lang) {
  const name = LANGUAGE_NAMES[lang] || lang;
  return [
    `You translate short cooking texts into ${name}.`,
    "The input is a JSON array of strings: recipe titles, ingredient lines,",
    "preparation steps, and the names of recipe books, meal plans and shopping",
    "lists. Return a JSON array of the same length, in the same order, each",
    `entry the ${name} of the entry at that position.`,
    "Keep numbers, quantities and units exactly as they are; translate only",
    "the words around them. Keep a brand or a proper name as written. Never",
    "add, drop, explain or merge entries, and never answer with anything but",
    "the array.",
  ].join(" ");
}

async function callModel(body) {
  return fetch(`${proxy.GOOGLE_ORIGIN}/v1beta/models/${MODEL}:generateContent`, {
    method: "POST",
    headers: { "Content-Type": "application/json", "x-goog-api-key": geminiApiKey.value() },
    body: JSON.stringify(body),
  });
}

/// One model call for up to [BATCH] lines. Returns the lines and the tokens
/// they cost, so the dashboard sees this like any other AI spend.
async function translateBatch(lang, strings) {
  const body = {
    contents: [{ role: "user", parts: [{ text: JSON.stringify(strings) }] }],
    system_instruction: { parts: [{ text: instructionFor(lang) }] },
    generation_config: {
      response_mime_type: "application/json",
      response_json_schema: { type: "array", items: { type: "string" } },
      thinking_config: { thinking_level: "low" },
    },
  };
  const res = await callModel(body);
  const raw = await res.text();
  if (!res.ok) {
    const err = new Error(`gemini ${res.status}: ${raw.slice(0, 300)}`);
    err.status = res.status;
    throw err;
  }
  const data = JSON.parse(raw);
  const answer = ((((data.candidates || [])[0] || {}).content || {}).parts || [])
    .map((p) => p.text || "")
    .join("");
  let list;
  try {
    list = JSON.parse(answer);
  } catch (err) {
    throw new Error("gemini did not answer with JSON");
  }
  if (!Array.isArray(list) || list.length !== strings.length) {
    throw new Error(`gemini returned ${Array.isArray(list) ? list.length : "?"} of ${strings.length} lines`);
  }
  return { lines: list.map((s) => (typeof s === "string" ? s : "")), usage: aiUsage.extractUsage(data) };
}

/// The finished variants, under the account's own language folder. The app
/// reads these on a later switch, or on a new device, without a model call.
async function storeVariants(uid, lang, translations, versions) {
  const db = admin.firestore();
  const entries = Object.entries(translations);
  for (let i = 0; i < entries.length; i += 400) {
    const batch = db.batch();
    for (const [id, record] of entries.slice(i, i + 400)) {
      const ref = db
        .collection("users").doc(uid)
        .collection("i18n").doc(lang)
        .collection(record.type).doc(id);
      batch.set(ref, {
        ...record.fields,
        version: versions[id] ?? 0,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }
}

function parseRequest(body) {
  const lang = typeof body?.targetLang === "string" ? body.targetLang.trim() : "";
  if (!LANGUAGE_NAMES[lang]) return { error: "targetLang must be one of " + Object.keys(LANGUAGE_NAMES).join(", ") };
  const items = Array.isArray(body.items) ? body.items : [];
  if (items.length === 0) return { error: "items is required" };
  if (items.length > MAX_ITEMS) return { error: `at most ${MAX_ITEMS} items per call` };
  const clean = items.filter((i) => i && typeof i.id === "string" && SHAPES[i.type]);
  if (clean.length === 0) return { error: "no items of a known type" };
  return { lang, items: clean };
}

exports.translateContent = onRequest(
  {
    secrets: [geminiApiKey],
    region: "europe-west1",
    timeoutSeconds: 540,
    memory: "512MiB",
    minInstances: 0,
    maxInstances: 5,
    cors: false,
  },
  async (req, res) => {
    if (req.method !== "POST") return res.status(405).json({ error: { message: "POST only" } });
    const caller = await proxy.verifyCaller(req);
    if (!caller) {
      return res.status(401).json({ error: { message: "A valid Firebase ID token is required" } });
    }

    const request = parseRequest(req.body);
    if (request.error) return res.status(400).json({ error: { message: request.error } });
    const { lang, items } = request;
    const uid = caller.uid;
    const started = Date.now();

    try {
      const strings = collectStrings(items);
      const table = await readCache(lang, strings);
      const missing = strings.filter((s) => !table[s]);

      let usage = null;
      const fresh = {};
      for (let i = 0; i < missing.length; i += BATCH) {
        const slice = missing.slice(i, i + BATCH);
        const answer = await translateBatch(lang, slice);
        slice.forEach((source, index) => {
          const text = answer.lines[index];
          if (text) {
            fresh[source] = text;
            table[source] = text;
          }
        });
        if (answer.usage) {
          usage = usage
            ? {
                input: usage.input + answer.usage.input,
                output: usage.output + answer.usage.output,
                thoughts: usage.thoughts + answer.usage.thoughts,
                cached: usage.cached + answer.usage.cached,
                total: usage.total + answer.usage.total,
                imageOutput: 0,
                searches: 0,
                raw: answer.usage.raw,
              }
            : answer.usage;
        }
      }

      if (Object.keys(fresh).length) await writeCache(lang, fresh);
      const translations = applyTranslations(items, table);
      // The version the caller says this text is at. A translation is good
      // for as long as the record still stands at it, which is what stops the
      // same recipe being paid for twice.
      const versions = Object.fromEntries(
        items.map((item) => [item.id, Number.isInteger(item.version) ? item.version : 0]),
      );
      await storeVariants(uid, lang, translations, versions);

      void aiUsage.recordCall({
        uid,
        fn: "translateContent",
        model: MODEL,
        kind: "translate",
        status: 200,
        ms: Date.now() - started,
        usage,
      });

      logger.info("translated", {
        uid, lang, items: items.length,
        lines: strings.length, cached: strings.length - missing.length, translated: missing.length,
      });
      return res.status(200).json({
        translations,
        stats: {
          items: items.length,
          lines: strings.length,
          fromCache: strings.length - missing.length,
          translated: missing.length,
        },
      });
    } catch (err) {
      logger.error("translate failed", { uid, lang, reason: err.message });
      void aiUsage.recordCall({
        uid, fn: "translateContent", model: MODEL, kind: "translate",
        status: err.status === 429 ? 429 : 502, ms: Date.now() - started, usage: null,
      });
      return res.status(err.status === 429 ? 429 : 502).json({ error: { message: err.message } });
    }
  },
);

exports.internals = { collectStrings, applyTranslations, parseRequest, cacheKey, SHAPES };
