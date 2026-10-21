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
const budget = require("./dailyBudget");
// The website (aieasyplate.app/app) calls this from the browser too.
const { ORIGINS } = require("./origins");

const geminiApiKey = defineSecret("GEMINI_API_KEY");

const CACHE_COLLECTION = "translation_cache";
const MODEL = "gemini-3.8-flash";

// Lines per model call. Large enough that the instruction is amortised,
// small enough that one bad answer does not cost a whole library — and a
// character ceiling too: a line may be up to MAX_TEXT long, so sixty of the
// longest were ~120k characters in one call, past what one answer returns
// before the call times out.
const BATCH = 60;
const BATCH_CHARS = 12000;
// What the day's budget counts: one unit per started UNIT_CHARS of a line.
// An ingredient or a short step is one unit, as before (the clients count
// one per line and stay right for ordinary text); a 2000-character line is
// seven, since that is roughly what it costs. Counting plain lines made the
// daily allowance worth up to 6M characters.
const UNIT_CHARS = 300;
// A Firestore getAll takes a few hundred at a time; a library of a thousand
// recipes is read in a handful of round trips.
const LOOKUP_CHUNK = 250;
const MAX_ITEMS = 2000;
const MAX_TEXT = 2000;
// Checked before anything is read or spent: no recipe has two hundred
// lines, and one request's distinct lines may not exceed a day's default
// budget (quota_translate_lines_daily). The app sends 120 items at a time.
const MAX_LINES_PER_ITEM = 200;
const MAX_LINES_PER_REQUEST = 3000;

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

// Own keys only: a type of "constructor" or "__proto__" is not a shape.
function shapeOf(type) {
  return typeof type === "string" && Object.hasOwn(SHAPES, type) ? SHAPES[type] : null;
}

// Concurrent model calls per request, and how long one may take. A
// thousand-line library used to be up to fifty calls in a row with no
// limit on any of them, and only written to the cache at the very end — so
// the function's 540 s timeout threw away every batch already paid for.
const PARALLEL = 3;
const CALL_TIMEOUT_MS = 60000;

/// Pure: the budget units one (trimmed) line costs.
function unitsOf(text) {
  return Math.max(1, Math.ceil(text.length / UNIT_CHARS));
}

/// Pure: [strings] cut into model calls of at most [BATCH] lines and
/// [BATCH_CHARS] characters (a single longer line goes alone).
function batchesOf(strings, maxLines = BATCH, maxChars = BATCH_CHARS) {
  const out = [];
  let current = [];
  let chars = 0;
  for (const text of strings) {
    if (current.length > 0 && (current.length >= maxLines || chars + text.length > maxChars)) {
      out.push(current);
      current = [];
      chars = 0;
    }
    current.push(text);
    chars += text.length;
  }
  if (current.length > 0) out.push(current);
  return out;
}

function cacheKey(lang, text) {
  return crypto.createHash("sha256").update(`${lang}\n${text}`).digest("hex");
}

/// Every distinct string in the request, in the order first seen. Blank and
/// over-long values are left alone rather than sent anywhere.
function collectStrings(items) {
  const seen = new Set();
  const out = [];
  for (const item of items) {
    const shape = shapeOf(item.type);
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
    const shape = shapeOf(item.type);
    if (!shape) continue;
    const fields = {};
    for (const [field, kind] of Object.entries(shape)) {
      const value = item.fields ? item.fields[field] : undefined;
      if (kind === "list") {
        fields[field] = (Array.isArray(value) ? value : []).map((text) =>
          typeof text === "string" ? lookup(table, text.trim()) || text : text,
        );
      } else if (typeof value === "string") {
        fields[field] = lookup(table, value.trim()) || value;
      }
    }
    out[item.id] = { type: item.type, fields };
  }
  return out;
}

// A translated line from [table], or undefined: own string values only, so
// a line reading "__proto__" or "constructor" is never answered with an
// object from the prototype chain.
function lookup(table, key) {
  if (!Object.hasOwn(table, key)) return undefined;
  const value = table[key];
  return typeof value === "string" ? value : undefined;
}

async function readCache(lang, strings) {
  const db = admin.firestore();
  const table = Object.create(null);
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

// A call that timed out reached Google, which most likely billed it: it is
// marked `answered`, so its lines are not given back. Refunding timeouts
// made a request built to be slow (long lines) free.
async function callModel(body, fetchImpl = fetch, timeoutMs = CALL_TIMEOUT_MS) {
  try {
    return await fetchImpl(`${proxy.GOOGLE_ORIGIN}/v1beta/models/${MODEL}:generateContent`, {
      method: "POST",
      headers: { "Content-Type": "application/json", "x-goog-api-key": geminiApiKey.value() },
      body: JSON.stringify(body),
      signal: AbortSignal.timeout(timeoutMs),
    });
  } catch (err) {
    if (err && (err.name === "TimeoutError" || err.name === "AbortError")) err.answered = true;
    throw err;
  }
}

/// Runs [run] over [batches], [parallel] at a time. After the first failure
/// no new batch starts, the ones in flight are let finish (they are being
/// paid for, and [run] keeps what they bring), and that failure is thrown.
async function runBatches(batches, run, parallel = PARALLEL) {
  let next = 0;
  let failure = null;
  const worker = async () => {
    while (failure === null && next < batches.length) {
      const batch = batches[next++];
      try {
        await run(batch);
      } catch (err) {
        if (failure === null) failure = err;
      }
    }
  };
  await Promise.all(Array.from({ length: Math.min(parallel, batches.length) }, worker));
  if (failure) throw failure;
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
  // From here on the model answered and the lines were paid for: a failure
  // says so (`answered`), and the handler does not give them back.
  const answered = (message) => Object.assign(new Error(message), { answered: true });
  let data;
  try {
    data = JSON.parse(raw);
  } catch (_) {
    throw answered("gemini answered with no JSON envelope");
  }
  const answer = ((((data.candidates || [])[0] || {}).content || {}).parts || [])
    .map((p) => p.text || "")
    .join("");
  let list;
  try {
    list = JSON.parse(answer);
  } catch (err) {
    throw answered("gemini did not answer with JSON");
  }
  if (!Array.isArray(list) || list.length !== strings.length) {
    throw answered(`gemini returned ${Array.isArray(list) ? list.length : "?"} of ${strings.length} lines`);
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

/// Pure: the entries of [translations] whose record holds a line in
/// [fresh] (translated by the model in this call).
function withFreshLines(items, translations, fresh) {
  const out = {};
  for (const item of items) {
    if (!Object.hasOwn(translations, item.id)) continue;
    const touched = collectStrings([item]).some((text) => Object.hasOwn(fresh, text));
    if (touched) out[item.id] = translations[item.id];
  }
  return out;
}

// Pure: the lines one item carries, blanks included — what the per-item cap
// counts.
function linesIn(item) {
  const shape = shapeOf(item.type) || {};
  let n = 0;
  for (const [field, kind] of Object.entries(shape)) {
    const value = item.fields ? item.fields[field] : undefined;
    n += kind === "list" ? (Array.isArray(value) ? value.length : 0) : typeof value === "string" ? 1 : 0;
  }
  return n;
}

// Pure: a document id Firestore takes as one segment (the variants are
// stored under it): no slash, not "." or "..", not `__…__`.
function validId(id) {
  return typeof id === "string" && /^[^/]{1,128}$/.test(id) && id !== "." && id !== ".." && !/^__.*__$/.test(id);
}

function parseRequest(body) {
  const lang = typeof body?.targetLang === "string" ? body.targetLang.trim() : "";
  if (!LANGUAGE_NAMES[lang]) return { error: "targetLang must be one of " + Object.keys(LANGUAGE_NAMES).join(", ") };
  const items = Array.isArray(body.items) ? body.items : [];
  if (items.length === 0) return { error: "items is required" };
  if (items.length > MAX_ITEMS) return { error: `at most ${MAX_ITEMS} items per call` };
  // The id becomes a document id under the account's i18n folder: a slash
  // would make it a path, and a blank or a very long one is nothing Hive
  // ever handed out.
  const clean = items.filter((i) => i && validId(i.id) && shapeOf(i.type));
  if (clean.length === 0) return { error: "no items of a known type" };
  const heavy = clean.find((i) => linesIn(i) > MAX_LINES_PER_ITEM);
  if (heavy) return { error: `item ${heavy.id} has more than ${MAX_LINES_PER_ITEM} lines`, code: "too_many_lines_in_item" };
  if (collectStrings(clean).length > MAX_LINES_PER_REQUEST) {
    return { error: `at most ${MAX_LINES_PER_REQUEST} distinct lines per call; send fewer items`, code: "too_many_lines" };
  }
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
    cors: ORIGINS,
  },
  async (req, res) => {
    if (req.method !== "POST") return res.status(405).json({ error: { message: "POST only" } });
    const { caller, refusal } = await proxy.verifyPaidCaller(req);
    if (!caller) {
      return res.status(refusal.status).json({ error: { code: refusal.code, message: refusal.message } });
    }

    const request = parseRequest(req.body);
    if (request.error) return res.status(400).json({ error: { code: request.code || "invalid", message: request.error } });
    const { lang, items } = request;
    const uid = caller.uid;
    const started = Date.now();
    // Lines this call charged to the day's budget, to give back if the
    // model fails before they were translated.
    let claimed = 0;
    // Lines of batches the model answered: paid for, so never refunded.
    let paid = 0;
    const fresh = Object.create(null);

    try {
      const strings = collectStrings(items);
      // The lookups themselves are this account's reads (one per distinct
      // line), on a day's budget of their own — separate from the translate
      // units, so a library the cache already holds still comes back for
      // free, and a loop of all-cached requests no longer runs unbounded.
      // The refusal carries `quota.requested`, so the clients cut the
      // request to what is left, as they do for translate units.
      if (strings.length) {
        const lookups = await budget.spend({ uid, kind: "translateCache", amount: strings.length });
        if (!lookups.allowed) {
          logger.info("translate cache-read budget exhausted", { uid, lang, lines: strings.length, used: lookups.used, limit: lookups.limit });
          return res.status(429).json(budget.refusalBody(lookups, "translateCache"));
        }
      }
      const table = await readCache(lang, strings);
      const missing = strings.filter((s) => !table[s]);

      // Only the lines the cache did not have cost anything, so only those
      // count: a reinstall that finds everything cached spends nothing.
      // Counted in units (unitsOf), so a long line costs what it costs.
      const missingUnits = missing.reduce((n, text) => n + unitsOf(text), 0);
      const units = new Map(missing.map((text) => [text, unitsOf(text)]));
      if (missing.length) {
        const decision = await budget.spend({ uid, kind: "translate", amount: missingUnits });
        if (!decision.allowed) {
          logger.info("translate budget exhausted", { uid, lang, lines: missing.length, used: decision.used, limit: decision.limit });
          return res.status(429).json(budget.refusalBody(decision, "translate"));
        }
        claimed = missingUnits;
      }

      let usage = null;
      const batches = batchesOf(missing);
      const unitsIn = (slice) => slice.reduce((n, text) => n + (units.get(text) || 1), 0);
      await runBatches(batches, async (slice) => {
        let answer;
        try {
          answer = await translateBatch(lang, slice);
        } catch (err) {
          if (err.answered) paid += unitsIn(slice);
          throw err;
        }
        paid += unitsIn(slice);
        const pairs = Object.create(null);
        slice.forEach((source, index) => {
          const text = answer.lines[index];
          if (text) {
            pairs[source] = text;
            fresh[source] = text;
            table[source] = text;
          }
        });
        // Each batch is cached as it lands, so a timeout or a later failure
        // never throws away lines already paid for.
        if (Object.keys(pairs).length) {
          await writeCache(lang, pairs).catch((e) => logger.warn("translate cache write failed", { reason: e.message }));
        }
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
      });

      const translations = applyTranslations(items, table);
      // The version the caller says this text is at. A translation is good
      // for as long as the record still stands at it, which is what stops the
      // same recipe being paid for twice.
      const versions = Object.fromEntries(
        items.map((item) => [item.id, Number.isInteger(item.version) ? item.version : 0]),
      );
      // Only records with at least one line the model just translated: one
      // made wholly of shared-cache lines costs nothing to rebuild (the next
      // device asks and gets cache reads), and storing it anyway let a loop
      // of cached requests write up to MAX_ITEMS documents a call for free.
      await storeVariants(uid, lang, withFreshLines(items, translations, fresh), versions);

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
      // The batches that came back before the failure are kept (cached as
      // each landed, so a retry does not pay for them again) and stay charged; only the lines
      // the model never answered go back. Refunding the whole call made a
      // request whose last batch fails on purpose free, however many
      // batches before it were translated.
      const refund = Math.max(0, claimed - paid);
      if (refund) await budget.refund(admin.firestore(), { uid, kind: "translate", amount: refund });
      void aiUsage.recordCall({
        uid, fn: "translateContent", model: MODEL, kind: "translate",
        status: err.status === 429 ? 429 : 502, ms: Date.now() - started, usage: null,
      });
      // Gemini's own text stays in the log above.
      const busy = err.status === 429;
      return res.status(busy ? 429 : 502).json({ error: { code: busy ? "upstream_busy" : "upstream", message: busy ? "The translator is busy, try again shortly" : "Translation failed" } });
    }
  },
);

exports.internals = { callModel, unitsOf, batchesOf, withFreshLines, UNIT_CHARS, BATCH, BATCH_CHARS, translateBatch, runBatches, shapeOf, lookup, collectStrings, applyTranslations, parseRequest, cacheKey, linesIn, validId, SHAPES, MAX_LINES_PER_ITEM, MAX_LINES_PER_REQUEST };
