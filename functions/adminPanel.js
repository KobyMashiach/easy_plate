// The web console at aieasyplate.app/admin talks to this one endpoint.
//
// The caller is the administrator alone — the email on the Firebase ID
// token, the same check adminUsers and the Firestore rules make — and the
// browser origin has to be one of ours (CORS). Reads the console makes
// straight from Firestore are governed by the rules; everything that needs
// the Admin SDK, or that should leave an audit row, comes through here as
// one `action` with its fields:
//
//   accounts   user.disable / user.enable / user.delete / user.kick (free
//              the device session + revoke tokens) / user.notify /
//              user.notifyAll / user.auth (the Auth record) /
//              user.entitlement / user.profile / user.content.set /
//              user.content.delete
//   community  forum.post.create|update|delete, forum.reply.create|update|
//              delete, community.like, community.seedLikes,
//              recipe.create|update|delete, recipe.generate, text.generate,
//              image.search
//   personas   persona.create|update|delete|suggest — invented members
//              (seed_… uids, no Auth user) that posts and recipes can be
//              written as, so the community is not empty on launch day
//   households household.removeMember / household.dissolve
//   console    config.get / config.set / config.add / config.delete /
//              pricing.sync
//   stores     stores.stats / stores.status / stores.config / stores.sync —
//              the exact install counts behind the listings' "500+" tags
//
// Every call writes one admin_audit row: who, what, with which fields
// (pictures and long texts cut down), and whether it worked.
const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");
const crypto = require("node:crypto");

const proxy = require("./aiProxy").internals;
const accounts = require("./adminUsers").internals;
const remoteConfig = require("./adminRemoteConfig").internals;
const imageSearch = require("./imageSearch").internals;
const aiUsage = require("./aiUsage");
const households = require("./households").internals;
const { syncPricing, syncRate } = require("./pricingCatalog");
const storeStats = require("./storeStats");

const geminiApiKey = defineSecret("GEMINI_API_KEY");
const serperApiKey = defineSecret("SERPER_API_KEY");

// Where the console is served from. A page anywhere else cannot call this,
// even with a stolen token in hand — the browser refuses before the request
// leaves.
const ORIGINS = [
  "https://aieasyplate.app",
  "https://www.aieasyplate.app",
  "https://easy-plate.web.app",
  "https://easy-plate.firebaseapp.com",
  "http://localhost:5000",
  "http://localhost:8765",
];

const MODEL = "gemini-3.8-flash";
const PERSONA_PREFIX = "seed_";
const AUDIT_COLLECTION = "admin_audit";
const PERSONAS_COLLECTION = "seed_personas";
const MAX_IMAGE_BYTES = 8 * 1024 * 1024;
const YEAR_MS = 365 * 24 * 60 * 60 * 1000;
const CONTENT_COLLECTIONS = new Set(["recipes", "books", "meal_plans", "grocery_lists", "preferences", "price_records", "receipts", "product_pricing"]);
const CONTENT_ROOTS = new Set(["users", "households"]);
const UNITS = new Set(["gram", "kilogram", "milliliter", "liter", "teaspoon", "tablespoon", "cup", "unit", "pinch", "unspecified"]);
const DIETS = new Set(["meat", "dairy", "vegetarian", "vegan", "kosher", "glutenFree", "allergy"]);
const ALLERGENS = new Set(["gluten", "milk", "eggs", "fish", "shellfish", "peanuts", "treeNuts", "sesame", "soy"]);
const LANG_NAMES = { he: "Hebrew", en: "English", ar: "Arabic", fr: "French", ru: "Russian" };
const RC_TYPES = new Set(["STRING", "NUMBER", "BOOLEAN", "JSON"]);

// ---------------------------------------------------------------------------
// Pure: request shapes. Each action names the fields it takes; anything
// else on the body is dropped, and a missing required field is refused
// before any work starts.
// ---------------------------------------------------------------------------

const str = (max, required = false) => ({ kind: "string", max, required });
const num = (required = false) => ({ kind: "number", required });
const bool = () => ({ kind: "boolean" });
const obj = (required = false) => ({ kind: "object", required });
const anyOf = (values, required = false) => ({ kind: "enum", values, required });

const ACTIONS = {
  "ping": {},
  "user.disable": { uid: str(128, true), message: str(1000) },
  "user.enable": { uid: str(128, true) },
  "user.delete": { uid: str(128, true) },
  "user.kick": { uid: str(128, true) },
  "user.notify": { uid: str(128, true), title: str(80), body: str(1000, true) },
  "user.notifyAll": { title: str(80), body: str(1000, true) },
  "user.auth": { uid: str(128, true) },
  "user.entitlement": { uid: str(128, true), premium: bool(), premiumUntil: num(), adminLock: bool() },
  "user.profile": { uid: str(128, true), fullName: str(80), photoUrl: str(2000) },
  "user.content.set": { root: anyOf([...CONTENT_ROOTS], true), rootId: str(128, true), collection: anyOf([...CONTENT_COLLECTIONS], true), id: str(128, true), data: obj(true) },
  "user.content.delete": { root: anyOf([...CONTENT_ROOTS], true), rootId: str(128, true), collection: anyOf([...CONTENT_COLLECTIONS], true), id: str(128, true) },
  "forum.post.create": { as: str(128, true), title: str(200, true), body: str(8000, true), createdAt: num() },
  "forum.post.update": { postId: str(128, true), title: str(200), body: str(8000) },
  "forum.post.delete": { postId: str(128, true) },
  "forum.reply.create": { as: str(128, true), postId: str(128, true), body: str(8000, true), sharedRecipeId: str(128), sharedRecipeTitle: str(200), createdAt: num() },
  "forum.reply.update": { postId: str(128, true), replyId: str(128, true), body: str(8000, true) },
  "forum.reply.delete": { postId: str(128, true), replyId: str(128, true) },
  "community.like": { as: str(128, true), kind: anyOf(["post", "reply", "recipe"], true), postId: str(128), replyId: str(128), recipeId: str(128), on: bool() },
  "community.seedLikes": { kind: anyOf(["post", "reply", "recipe"], true), postId: str(128), replyId: str(128), recipeId: str(128), count: num(true) },
  "recipe.create": { as: str(128, true), recipe: obj(true), image: obj(), createdAt: num() },
  "recipe.update": { id: str(128, true), recipe: obj(true), image: obj() },
  "recipe.delete": { id: str(128, true) },
  "recipe.generate": { title: str(200, true), lang: str(5), hints: str(1000) },
  "dish.suggest": { count: num(), lang: str(5), theme: str(300) },
  "recipe.seedOne": { title: str(200, true), lang: str(5), as: str(128), createdAt: num(), imageQuery: str(120), hints: str(1000), likes: num() },
  "text.generate": { kind: anyOf(["thread", "reply", "comment"], true), lang: str(5), topic: str(500), context: str(4000), persona: str(80) },
  "image.search": { query: str(120, true), start: num(), lang: str(5) },
  "persona.create": { name: str(80, true), gender: anyOf(["male", "female"]), photoUrl: str(2000), photoDataUrl: str(12 * 1024 * 1024), bio: str(300) },
  "persona.update": { uid: str(128, true), name: str(80), gender: anyOf(["male", "female"]), photoUrl: str(2000), photoDataUrl: str(12 * 1024 * 1024), bio: str(300) },
  "persona.delete": { uid: str(128, true), withContent: bool() },
  "persona.suggest": { count: num(), lang: str(5) },
  "forum.seedThread": { lang: str(5), topic: str(300), replies: num(), days: num(), likes: num() },
  "household.removeMember": { hid: str(128, true), uid: str(128, true) },
  "household.dissolve": { hid: str(128, true) },
  "config.get": {},
  "config.set": { name: str(120, true), value: str(20000) },
  "config.add": { name: str(120, true), valueType: anyOf([...RC_TYPES], true), value: str(20000), description: str(1000), group: str(120) },
  "config.delete": { name: str(120, true) },
  "pricing.sync": {},
  "stores.stats": {},
  "stores.status": {},
  "stores.config": { playBucket: str(200), playPackage: str(200), appleVendor: str(40), appleIssuerId: str(80), appleKeyId: str(40), appleAppId: str(40), iosSince: str(10), applePrivateKey: str(8000) },
  "stores.sync": { platform: anyOf(["all", "android", "ios"]), backfill: bool() },
};

function parseRequest(body) {
  const action = typeof (body && body.action) === "string" ? body.action.trim() : "";
  const spec = ACTIONS[action];
  if (!spec) return { error: "unknown action" };
  const out = { action };
  for (const [field, rule] of Object.entries(spec)) {
    const raw = body[field];
    const missing = raw === undefined || raw === null || (rule.kind === "string" && String(raw).trim() === "");
    if (missing) {
      if (rule.required) return { error: `${field} is required` };
      continue;
    }
    switch (rule.kind) {
      case "string": {
        if (typeof raw !== "string") return { error: `${field} must be a string` };
        out[field] = raw.trim().slice(0, rule.max);
        break;
      }
      case "number": {
        const n = typeof raw === "number" ? raw : Number(raw);
        if (!Number.isFinite(n)) return { error: `${field} must be a number` };
        out[field] = n;
        break;
      }
      case "boolean":
        out[field] = raw === true || raw === "true";
        break;
      case "object":
        if (typeof raw !== "object" || Array.isArray(raw)) return { error: `${field} must be an object` };
        out[field] = raw;
        break;
      case "enum":
        if (!rule.values.includes(raw)) return { error: `${field} is not one of ${rule.values.join(", ")}` };
        out[field] = raw;
        break;
      default:
        break;
    }
  }
  return out;
}

// ---------------------------------------------------------------------------
// Pure: content shapes.
// ---------------------------------------------------------------------------

function isPersona(uid) {
  return typeof uid === "string" && uid.startsWith(PERSONA_PREFIX);
}

function personaUid(random = crypto.randomBytes(15)) {
  return PERSONA_PREFIX + random.toString("base64url").replace(/[^A-Za-z0-9]/g, "").slice(0, 20);
}

// A date the console asked for, held within the last year and never in
// the future: a thread "from" next month would sit on top of the feed
// forever.
function backdated(ms, now = Date.now()) {
  if (typeof ms !== "number" || !Number.isFinite(ms)) return now;
  return Math.min(now, Math.max(now - YEAR_MS, Math.round(ms)));
}

function cleanInt(value, { min = 0, max = 100000 } = {}) {
  const n = typeof value === "number" ? value : Number(value);
  if (!Number.isFinite(n)) return null;
  return Math.min(max, Math.max(min, Math.round(n)));
}

function cleanNumber(value, { min = 0, max = 1e6 } = {}) {
  const n = typeof value === "number" ? value : Number(value);
  if (!Number.isFinite(n)) return null;
  return Math.min(max, Math.max(min, Math.round(n * 100) / 100));
}

function cleanList(raw, allowed, max = 20) {
  if (!Array.isArray(raw)) return [];
  const out = [];
  for (const item of raw) {
    if (typeof item === "string" && allowed.has(item) && !out.includes(item)) out.push(item);
    if (out.length >= max) break;
  }
  return out;
}

// The shared_recipes document body the app reads (SharedRecipesFirestoreDataSource):
// every field it looks for, in the shape it expects, with nothing the console
// may have sent beyond that.
function normalizeRecipe(raw) {
  if (!raw || typeof raw !== "object") return { error: "recipe is required" };
  const title = typeof raw.title === "string" ? raw.title.trim().slice(0, 200) : "";
  if (!title) return { error: "recipe.title is required" };
  const ingredients = [];
  for (const item of Array.isArray(raw.ingredients) ? raw.ingredients.slice(0, 60) : []) {
    const name = item && typeof item.name === "string" ? item.name.trim().slice(0, 120) : "";
    if (!name) continue;
    const amount = item.amount === null || item.amount === undefined || item.amount === "" ? null : cleanNumber(item.amount, { min: 0, max: 100000 });
    const unit = typeof item.unit === "string" && UNITS.has(item.unit) ? item.unit : "unspecified";
    ingredients.push({ name, amount, unit });
  }
  const steps = (Array.isArray(raw.steps) ? raw.steps : [])
    .filter((s) => typeof s === "string" && s.trim())
    .map((s) => s.trim().slice(0, 2000))
    .slice(0, 60);
  if (ingredients.length === 0 && steps.length === 0) return { error: "recipe needs ingredients or steps" };
  let nutrition = null;
  if (raw.nutrition && typeof raw.nutrition === "object") {
    const calories = cleanInt(raw.nutrition.calories, { min: 0, max: 20000 });
    if (calories !== null) {
      nutrition = {
        calories,
        proteinGrams: cleanNumber(raw.nutrition.proteinGrams, { min: 0, max: 5000 }) ?? 0,
        carbsGrams: cleanNumber(raw.nutrition.carbsGrams, { min: 0, max: 5000 }) ?? 0,
        fatGrams: cleanNumber(raw.nutrition.fatGrams, { min: 0, max: 5000 }) ?? 0,
      };
    }
  }
  return {
    recipe: {
      title,
      prepTimeMinutes: cleanInt(raw.prepTimeMinutes, { min: 0, max: 100000 }),
      cookTimeMinutes: cleanInt(raw.cookTimeMinutes, { min: 0, max: 100000 }),
      ingredients,
      steps,
      dietaryTags: cleanList(raw.dietaryTags, DIETS),
      allergens: cleanList(raw.allergens, ALLERGENS),
      mayContain: cleanList(raw.mayContain, ALLERGENS),
      servings: cleanInt(raw.servings, { min: 1, max: 1000 }),
      nutrition,
    },
  };
}

// randomuser.me keeps a hundred portraits per gender; a persona gets one
// by number so two personas rarely share a face.
function portraitUrl(gender, index) {
  const n = Math.abs(Math.round(Number(index) || 0)) % 100;
  return `https://randomuser.me/api/portraits/${gender === "male" ? "men" : "women"}/${n}.jpg`;
}

// What the audit row keeps of a request: ids and short texts, never a
// picture or a whole recipe.
function summarize(request) {
  const out = {};
  for (const [key, value] of Object.entries(request)) {
    if (key === "action") continue;
    if (key === "photoDataUrl" || key === "data") {
      out[key] = typeof value === "string" ? `<${value.length} chars>` : "<object>";
    } else if (key === "applePrivateKey") {
      out[key] = "<secret>";
    } else if (key === "image" && value && typeof value === "object") {
      out[key] = value.storagePath ? { storagePath: value.storagePath } : value.url ? { url: String(value.url).slice(0, 300) } : value.dataUrl ? { dataUrl: `<${String(value.dataUrl).length} chars>` } : {};
    } else if (key === "recipe" && value && typeof value === "object") {
      out[key] = { title: typeof value.title === "string" ? value.title.slice(0, 200) : "" };
    } else if (typeof value === "string") {
      out[key] = value.length > 300 ? `${value.slice(0, 300)}…` : value;
    } else {
      out[key] = value;
    }
  }
  return out;
}

// A data: URL's bytes and type, or null when it is not an image.
function decodeDataUrl(dataUrl) {
  const match = /^data:(image\/[a-z0-9.+-]+);base64,([A-Za-z0-9+/=\s]+)$/i.exec(dataUrl || "");
  if (!match) return null;
  return { contentType: match[1].toLowerCase(), bytes: Buffer.from(match[2].replace(/\s/g, ""), "base64") };
}

function extensionFor(contentType) {
  switch (contentType) {
    case "image/png": return "png";
    case "image/webp": return "webp";
    case "image/gif": return "gif";
    default: return "jpg";
  }
}

// The schema Gemini is held to for a recipe: the app's own shape, so the
// answer can go into the editor as it is.
const RECIPE_SCHEMA = {
  type: "object",
  properties: {
    title: { type: "string" },
    prepTimeMinutes: { type: "integer" },
    cookTimeMinutes: { type: "integer" },
    servings: { type: "integer" },
    ingredients: {
      type: "array",
      items: {
        type: "object",
        properties: { name: { type: "string" }, amount: { type: "number" }, unit: { type: "string", enum: [...UNITS] } },
        required: ["name", "unit"],
      },
    },
    steps: { type: "array", items: { type: "string" } },
    dietaryTags: { type: "array", items: { type: "string", enum: [...DIETS] } },
    allergens: { type: "array", items: { type: "string", enum: [...ALLERGENS] } },
    mayContain: { type: "array", items: { type: "string", enum: [...ALLERGENS] } },
    nutrition: {
      type: "object",
      properties: { calories: { type: "integer" }, proteinGrams: { type: "number" }, carbsGrams: { type: "number" }, fatGrams: { type: "number" } },
      required: ["calories", "proteinGrams", "carbsGrams", "fatGrams"],
    },
    imageQuery: { type: "string" },
  },
  required: ["title", "ingredients", "steps", "servings", "nutrition", "imageQuery"],
};

const TEXT_SCHEMA = {
  type: "object",
  properties: { title: { type: "string" }, body: { type: "string" } },
  required: ["body"],
};

const DISHES_SCHEMA = {
  type: "object",
  properties: {
    dishes: {
      type: "array",
      items: { type: "object", properties: { title: { type: "string" }, imageQuery: { type: "string" } }, required: ["title", "imageQuery"] },
    },
  },
  required: ["dishes"],
};

const THREAD_SCHEMA = {
  type: "object",
  properties: {
    title: { type: "string" },
    body: { type: "string" },
    replies: { type: "array", items: { type: "object", properties: { body: { type: "string" } }, required: ["body"] } },
  },
  required: ["title", "body", "replies"],
};

const PEOPLE_SCHEMA = {
  type: "object",
  properties: {
    people: {
      type: "array",
      items: { type: "object", properties: { name: { type: "string" }, gender: { type: "string", enum: ["male", "female"] } }, required: ["name", "gender"] },
    },
  },
  required: ["people"],
};

function langName(lang) {
  return LANG_NAMES[String(lang || "").toLowerCase()] || "Hebrew";
}

function recipePrompt({ title, lang, hints }) {
  return [
    `Write a complete, realistic home-cook recipe for "${title}" in ${langName(lang)}.`,
    "Every text field (title, ingredient names, steps) must be in that language, written the way a home cook would share it with friends — natural, not encyclopedic.",
    "Use metric units where they fit. `amount` is a number or omitted. Keep 6-16 ingredients and 4-12 steps.",
    "`nutrition` is per serving, estimated. `imageQuery` is a short English search phrase for a photo of the finished dish.",
    "`dietaryTags`: only the tags that truly apply (kosher only if the recipe is kosher as written; allergy only if allergens are set).",
    hints ? `Extra wishes from the author: ${hints}` : "",
  ].filter(Boolean).join("\n");
}

function textPrompt({ kind, lang, topic, context, persona }) {
  const who = persona ? `You are ${persona}, a home cook writing in a recipe app's community forum.` : "You are a home cook writing in a recipe app's community forum.";
  const language = `Write in ${langName(lang)}, casually, like a real person on a phone — short, warm, no marketing tone, no emoji walls (one at most), no hashtags.`;
  switch (kind) {
    case "thread":
      return [who, language, "Write a new forum thread: a question, a tip, or a story about cooking at home. Return `title` (under 80 characters) and `body` (2-6 sentences).", topic ? `Subject: ${topic}` : "Pick a believable everyday subject (weeknight dinners, kids, leftovers, holidays, a dish that went wrong, substitutions)."].join("\n");
    case "reply":
      return [who, language, "Write one reply in a thread (1-4 sentences) that reacts to what was written, adds something useful or personal, and does not repeat the question. Return `body` only.", context ? `The thread so far:\n${context}` : "", topic ? `Angle: ${topic}` : ""].filter(Boolean).join("\n");
    default:
      return [who, language, "Write one short comment (1-3 sentences) about this recipe, the kind people leave under a shared recipe. Return `body` only.", context ? `The recipe:\n${context}` : "", topic ? `Angle: ${topic}` : ""].filter(Boolean).join("\n");
  }
}

function dishesPrompt({ count, lang, theme }) {
  return [
    `Suggest ${count} different dishes that home cooks would share in a recipe app community, as titles in ${langName(lang)} (the way a person would name their own recipe, e.g. "Grandma's lemon chicken", not an encyclopedia entry).`,
    "Vary them: weeknight dinners, salads, soups, baking, desserts, breakfast, holiday food, a few classics and a few less common ones. No duplicates, no near-duplicates.",
    theme ? `Theme or constraint: ${theme}` : "",
    "`imageQuery` is a short English search phrase for a photo of the finished dish.",
  ].filter(Boolean).join("\n");
}

function threadPrompt({ lang, topic, replies, names }) {
  return [
    `Write one realistic forum thread for a home-cooking app's community, in ${langName(lang)}, plus ${replies} replies to it.`,
    `The thread is by ${names[0]}; the replies are, in order, by: ${names.slice(1).join(", ")}. Each person writes casually on a phone — short sentences, warm, specific, no marketing tone, at most one emoji per message, no hashtags, no sign-offs with names.`,
    "The thread is a question, a tip, or a short story about cooking at home (weeknight dinners, kids, leftovers, holidays, substitutions, a dish that went wrong, a win). `title` under 80 characters, `body` 2-6 sentences.",
    "Replies react to the thread and to each other (the second reply may answer the first), add something useful or personal, 1-4 sentences each, and never repeat the question.",
    topic ? `Subject or angle: ${topic}` : "Pick a believable everyday subject.",
  ].join("\n");
}

function peoplePrompt({ count, lang }) {
  return [
    `Invent ${count} realistic full names (first and last) of people who live where ${langName(lang)} is spoken and cook at home, as they would write their own name in a profile.`,
    `Write every name in the ${langName(lang)} script itself (${langName(lang) === "Hebrew" ? "Hebrew letters, e.g. דנה לוי" : langName(lang) === "Arabic" ? "Arabic letters" : langName(lang) === "Russian" ? "Cyrillic letters" : "Latin letters"}), never transliterated into another alphabet.`,
    "Mix genders and ages, include common and less common names, no celebrities, no duplicates, no titles.",
    "Return `people`, each with `name` and `gender`.",
  ].join("\n");
}

// ---------------------------------------------------------------------------
// Side effects.
// ---------------------------------------------------------------------------

async function gemini({ key, prompt, schema, uid, kind, fetchImpl = fetch }) {
  const started = Date.now();
  const response = await fetchImpl(`${proxy.GOOGLE_ORIGIN}/v1beta/models/${MODEL}:generateContent`, {
    method: "POST",
    headers: { "Content-Type": "application/json", "x-goog-api-key": key },
    body: JSON.stringify({
      contents: [{ role: "user", parts: [{ text: prompt }] }],
      generationConfig: { responseMimeType: "application/json", responseSchema: schema, temperature: 0.9 },
    }),
    signal: AbortSignal.timeout(90000),
  });
  const text = await response.text();
  let json;
  try {
    json = JSON.parse(text);
  } catch (_) {
    json = null;
  }
  // The bill, like every other model call: the recorder takes the parsed
  // token counts, never the raw answer, and must not take the answer down
  // with it if a shape it does not know slips through.
  try {
    void aiUsage.recordCall({ uid, fn: "adminPanel", model: MODEL, kind, status: response.status, ms: Date.now() - started, usage: json ? aiUsage.extractUsage(json) : null });
  } catch (err) {
    logger.warn("admin panel usage record failed", { reason: err.message });
  }
  if (!response.ok) {
    const reason = json && json.error && json.error.message ? json.error.message : `HTTP ${response.status}`;
    const error = new Error(reason);
    error.status = 502;
    error.code = "upstream";
    throw error;
  }
  const part = json && json.candidates && json.candidates[0] && json.candidates[0].content && json.candidates[0].content.parts && json.candidates[0].content.parts[0];
  const answer = part && typeof part.text === "string" ? part.text : "";
  try {
    return JSON.parse(answer);
  } catch (_) {
    const error = new Error("the model did not answer with JSON");
    error.status = 502;
    error.code = "upstream";
    throw error;
  }
}

async function fetchImage(url, fetchImpl = fetch) {
  if (!/^https?:\/\//i.test(url)) throw refused("image url must be http(s)", "invalid_image");
  const response = await fetchImpl(url, {
    headers: { "User-Agent": "Mozilla/5.0 (compatible; EasyPlateAdmin/1.0)", Accept: "image/*,*/*;q=0.5" },
    redirect: "follow",
    signal: AbortSignal.timeout(20000),
  });
  if (!response.ok) throw refused(`image fetch failed (${response.status})`, "image_fetch");
  const contentType = String(response.headers.get("content-type") || "").split(";")[0].trim().toLowerCase();
  const bytes = Buffer.from(await response.arrayBuffer());
  if (!contentType.startsWith("image/")) {
    // Some hosts lie about the type; the magic bytes decide.
    const sniffed = sniffImage(bytes);
    if (!sniffed) throw refused("the url did not return an image", "invalid_image");
    return { contentType: sniffed, bytes };
  }
  return { contentType, bytes };
}

function sniffImage(bytes) {
  if (bytes.length < 12) return null;
  if (bytes[0] === 0xff && bytes[1] === 0xd8) return "image/jpeg";
  if (bytes[0] === 0x89 && bytes[1] === 0x50 && bytes[2] === 0x4e && bytes[3] === 0x47) return "image/png";
  if (bytes.slice(0, 4).toString() === "RIFF" && bytes.slice(8, 12).toString() === "WEBP") return "image/webp";
  if (bytes.slice(0, 3).toString() === "GIF") return "image/gif";
  return null;
}

// Puts a picture in the bucket at `path` (its extension taken from the
// type) with a download token, the way the app's own uploads are read.
async function storeImage({ bucket, path, source, fetchImpl = fetch }) {
  let image;
  if (source.dataUrl) {
    image = decodeDataUrl(source.dataUrl);
    if (!image) throw refused("photoDataUrl is not an image", "invalid_image");
  } else if (source.url) {
    image = await fetchImage(source.url, fetchImpl);
  } else {
    throw refused("an image needs url or dataUrl", "invalid_image");
  }
  if (image.bytes.length > MAX_IMAGE_BYTES) throw refused("image is larger than 8 MB", "image_too_large");
  const fullPath = path.endsWith(".jpg") ? path : `${path}.${extensionFor(image.contentType)}`;
  const token = crypto.randomUUID();
  await bucket.file(fullPath).save(image.bytes, {
    contentType: image.contentType,
    resumable: false,
    metadata: { metadata: { firebaseStorageDownloadTokens: token } },
  });
  const url = `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/${encodeURIComponent(fullPath)}?alt=media&token=${token}`;
  return { path: fullPath, url, contentType: image.contentType };
}

function refused(message, code = "invalid", status = 400) {
  const error = new Error(message);
  error.status = status;
  error.code = code;
  return error;
}

// Who a post is written as: the administrator ("me") or one of the
// personas. Name and picture are read where the app reads them, so what
// the console shows is what the feed will.
async function authorFor(db, callerUid, as) {
  if (as === "me") {
    const pub = await db.doc(`public_profiles/${callerUid}`).get();
    const priv = pub.exists ? null : await db.doc(`users/${callerUid}`).get();
    const data = (pub.exists ? pub.data() : priv && priv.data()) || {};
    return { uid: callerUid, name: String(data.fullName || "EasyPlate"), photoUrl: data.photoUrl || null };
  }
  if (!isPersona(as)) throw refused("as must be 'me' or a persona uid", "invalid_author");
  const persona = await db.doc(`${PERSONAS_COLLECTION}/${as}`).get();
  if (!persona.exists) throw refused("no such persona", "not_found", 404);
  const data = persona.data();
  return { uid: as, name: String(data.name || ""), photoUrl: data.photoUrl || null };
}

function ts(ms) {
  return admin.firestore.Timestamp.fromMillis(ms);
}

function likeTarget(db, request) {
  switch (request.kind) {
    case "post":
      if (!request.postId) throw refused("postId is required");
      return db.doc(`forum_posts/${request.postId}`);
    case "reply":
      if (!request.postId || !request.replyId) throw refused("postId and replyId are required");
      return db.doc(`forum_posts/${request.postId}/replies/${request.replyId}`);
    default:
      if (!request.recipeId) throw refused("recipeId is required");
      return db.doc(`shared_recipes/${request.recipeId}`);
  }
}

// Sets or clears one account's like on a thread, a reply or a recipe, and
// moves the counter with it — the same transaction the app runs.
async function setLike(db, target, uid, on) {
  const like = target.collection("likes").doc(uid);
  return db.runTransaction(async (tx) => {
    const [targetSnap, likeSnap] = await Promise.all([tx.get(target), tx.get(like)]);
    if (!targetSnap.exists) throw refused("target no longer exists", "not_found", 404);
    if (on && !likeSnap.exists) {
      tx.set(like, { createdAt: admin.firestore.Timestamp.now() });
      tx.update(target, { likeCount: admin.firestore.FieldValue.increment(1) });
      return true;
    }
    if (!on && likeSnap.exists) {
      tx.delete(like);
      tx.update(target, { likeCount: admin.firestore.FieldValue.increment(-1) });
      return true;
    }
    return false;
  });
}

async function personaList(db) {
  const snap = await db.collection(PERSONAS_COLLECTION).get();
  return snap.docs.map((d) => ({ uid: d.id, ...d.data() }));
}

// ---------------------------------------------------------------------------
// Actions.
// ---------------------------------------------------------------------------

async function run(request, { caller, db, bucket, keys, fetchImpl = fetch }) {
  const now = Date.now();
  switch (request.action) {
    case "ping":
      return { uid: caller.uid, email: caller.email, now };

    // --- accounts ---------------------------------------------------------
    case "user.disable":
      await accounts.disable(request.uid, request.message || "");
      return {};
    case "user.enable":
      await accounts.enable(request.uid);
      return {};
    case "user.delete":
      await accounts.remove(request.uid);
      return {};
    case "user.kick":
      await accounts.releaseSession(request.uid);
      return {};
    case "user.notify":
      await accounts.notifyOne({ fromUid: caller.uid, uid: request.uid, title: request.title || "", message: request.body });
      return {};
    case "user.notifyAll":
      return accounts.notifyAll({ fromUid: caller.uid, title: request.title || "", message: request.body });
    case "user.auth": {
      try {
        const user = await admin.auth().getUser(request.uid);
        return {
          auth: {
            uid: user.uid,
            email: user.email || null,
            phoneNumber: user.phoneNumber || null,
            displayName: user.displayName || null,
            disabled: !!user.disabled,
            providers: (user.providerData || []).map((p) => p.providerId),
            createdAt: user.metadata.creationTime || null,
            lastSignInAt: user.metadata.lastSignInTime || null,
            lastRefreshAt: user.metadata.lastRefreshTime || null,
            tokensValidAfter: user.tokensValidAfterTime || null,
          },
        };
      } catch (err) {
        if (err.code === "auth/user-not-found") return { auth: null };
        throw err;
      }
    }
    case "user.entitlement": {
      const data = { source: "admin", adminLock: request.adminLock !== false, updatedAt: admin.firestore.FieldValue.serverTimestamp() };
      if (request.premium !== undefined) data.premium = request.premium;
      data.premiumUntil = request.premiumUntil ? ts(request.premiumUntil) : null;
      data.premiumFrom = request.premium ? admin.firestore.Timestamp.now() : null;
      await db.doc(`entitlements/${request.uid}`).set(data, { merge: true });
      return {};
    }
    case "user.profile": {
      const patch = { updatedAt: admin.firestore.FieldValue.serverTimestamp() };
      if (request.fullName !== undefined) patch.fullName = request.fullName;
      if (request.photoUrl !== undefined) patch.photoUrl = request.photoUrl || null;
      const batch = db.batch();
      batch.set(db.doc(`users/${request.uid}`), patch, { merge: true });
      batch.set(db.doc(`public_profiles/${request.uid}`), patch, { merge: true });
      await batch.commit();
      return {};
    }
    case "user.content.set": {
      const ref = db.doc(`${request.root}/${request.rootId}/${request.collection}/${request.id}`);
      const data = { ...request.data };
      if (data.id !== undefined && data.id !== request.id) data.id = request.id;
      await ref.set(data);
      return {};
    }
    case "user.content.delete":
      await db.doc(`${request.root}/${request.rootId}/${request.collection}/${request.id}`).delete();
      return {};

    // --- forum ------------------------------------------------------------
    case "forum.post.create": {
      const author = await authorFor(db, caller.uid, request.as);
      const ref = db.collection("forum_posts").doc(crypto.randomUUID());
      await ref.set({
        title: request.title,
        body: request.body,
        authorUid: author.uid,
        authorName: author.name,
        authorPhotoUrl: author.photoUrl,
        replyCount: 0,
        likeCount: 0,
        createdAt: ts(backdated(request.createdAt, now)),
      });
      return { postId: ref.id };
    }
    case "forum.post.update": {
      const patch = { editedAt: admin.firestore.FieldValue.serverTimestamp() };
      if (request.title !== undefined) patch.title = request.title;
      if (request.body !== undefined) patch.body = request.body;
      await db.doc(`forum_posts/${request.postId}`).update(patch);
      return {};
    }
    case "forum.post.delete":
      await db.recursiveDelete(db.doc(`forum_posts/${request.postId}`));
      return {};
    case "forum.reply.create": {
      const author = await authorFor(db, caller.uid, request.as);
      const post = db.doc(`forum_posts/${request.postId}`);
      if (!(await post.get()).exists) throw refused("no such thread", "not_found", 404);
      const reply = post.collection("replies").doc(crypto.randomUUID());
      const batch = db.batch();
      batch.set(reply, {
        body: request.body,
        authorUid: author.uid,
        authorName: author.name,
        authorPhotoUrl: author.photoUrl,
        sharedRecipeId: request.sharedRecipeId || null,
        sharedRecipeTitle: request.sharedRecipeTitle || null,
        likeCount: 0,
        createdAt: ts(backdated(request.createdAt, now)),
      });
      batch.update(post, { replyCount: admin.firestore.FieldValue.increment(1) });
      await batch.commit();
      return { replyId: reply.id };
    }
    case "forum.reply.update":
      await db.doc(`forum_posts/${request.postId}/replies/${request.replyId}`).update({ body: request.body, editedAt: admin.firestore.FieldValue.serverTimestamp() });
      return {};
    case "forum.reply.delete": {
      const reply = db.doc(`forum_posts/${request.postId}/replies/${request.replyId}`);
      if (!(await reply.get()).exists) return { gone: true };
      await db.recursiveDelete(reply);
      await db.doc(`forum_posts/${request.postId}`).update({ replyCount: admin.firestore.FieldValue.increment(-1) }).catch(() => {});
      return {};
    }
    case "community.like": {
      const author = await authorFor(db, caller.uid, request.as);
      const changed = await setLike(db, likeTarget(db, request), author.uid, request.on !== false);
      return { changed };
    }
    case "community.seedLikes": {
      const target = likeTarget(db, request);
      const personas = await personaList(db);
      if (personas.length === 0) throw refused("no personas to like with", "no_personas");
      const wanted = Math.min(cleanInt(request.count, { min: 0, max: 500 }) || 0, personas.length);
      // Random personas, each at most once.
      const shuffled = personas.sort(() => Math.random() - 0.5).slice(0, wanted);
      let added = 0;
      for (const persona of shuffled) {
        if (await setLike(db, target, persona.uid, true)) added++;
      }
      return { added, personas: personas.length };
    }

    // --- shared recipes ---------------------------------------------------
    case "recipe.create": {
      const author = await authorFor(db, caller.uid, request.as);
      const normalized = normalizeRecipe(request.recipe);
      if (normalized.error) throw refused(normalized.error);
      const id = crypto.randomUUID();
      const image = await recipeImage({ bucket, authorUid: author.uid, image: request.image, fetchImpl });
      await db.doc(`shared_recipes/${id}`).set({
        sourceRecipeId: crypto.randomUUID(),
        ...normalized.recipe,
        imageFileName: image.fileName,
        imageStoragePath: image.path,
        authorUid: author.uid,
        authorName: author.name,
        authorPhotoUrl: author.photoUrl,
        likeCount: 0,
        createdAt: ts(backdated(request.createdAt, now)),
      });
      return { id };
    }
    case "recipe.update": {
      const ref = db.doc(`shared_recipes/${request.id}`);
      const snap = await ref.get();
      if (!snap.exists) throw refused("no such recipe", "not_found", 404);
      const normalized = normalizeRecipe(request.recipe);
      if (normalized.error) throw refused(normalized.error);
      const patch = { ...normalized.recipe, updatedAt: admin.firestore.FieldValue.serverTimestamp() };
      if (request.image) {
        const image = await recipeImage({ bucket, authorUid: snap.get("authorUid") || "admin", image: request.image, fetchImpl });
        patch.imageFileName = image.fileName;
        patch.imageStoragePath = image.path;
      }
      await ref.update(patch);
      return {};
    }
    case "recipe.delete": {
      const ref = db.doc(`shared_recipes/${request.id}`);
      const snap = await ref.get();
      if (snap.exists) {
        const path = snap.get("imageStoragePath");
        await db.recursiveDelete(ref);
        // A persona's picture has no other home; a member's lives with
        // their own recipe too and is left alone.
        if (typeof path === "string" && path.startsWith(`recipe_images/${PERSONA_PREFIX}`)) {
          await bucket.file(path).delete().catch(() => {});
        }
      }
      return {};
    }
    case "recipe.generate": {
      const answer = await gemini({ key: keys.gemini, prompt: recipePrompt(request), schema: RECIPE_SCHEMA, uid: caller.uid, kind: "generate", fetchImpl });
      const normalized = normalizeRecipe(answer);
      if (normalized.error) throw refused(`the model's recipe was unusable: ${normalized.error}`, "upstream", 502);
      return { recipe: normalized.recipe, imageQuery: typeof answer.imageQuery === "string" ? answer.imageQuery.slice(0, 120) : normalized.recipe.title };
    }
    case "dish.suggest": {
      const count = cleanInt(request.count, { min: 1, max: 40 }) || 10;
      const answer = await gemini({ key: keys.gemini, prompt: dishesPrompt({ count, lang: request.lang, theme: request.theme }), schema: DISHES_SCHEMA, uid: caller.uid, kind: "text", fetchImpl });
      const seen = new Set();
      const dishes = [];
      for (const d of answer.dishes || []) {
        const title = d && typeof d.title === "string" ? d.title.trim().slice(0, 200) : "";
        if (!title || seen.has(title.toLowerCase())) continue;
        seen.add(title.toLowerCase());
        dishes.push({ title, imageQuery: typeof d.imageQuery === "string" ? d.imageQuery.trim().slice(0, 120) : title });
        if (dishes.length >= count) break;
      }
      return { dishes };
    }
    // One seeded recipe, end to end: the model writes it, Google Images
    // gives it a picture, a persona (random unless named) publishes it on
    // a day in the past, and a few other personas like it. Driven one at a
    // time by the console so each call stays short and the progress shows.
    case "recipe.seedOne": {
      const personas = await personaList(db);
      let as = request.as && request.as !== "random" ? request.as : null;
      if (!as) {
        if (personas.length === 0) throw refused("no personas to publish as", "no_personas");
        as = personas[crypto.randomInt(personas.length)].uid;
      }
      const author = await authorFor(db, caller.uid, as);
      const answer = await gemini({ key: keys.gemini, prompt: recipePrompt({ title: request.title, lang: request.lang, hints: request.hints }), schema: RECIPE_SCHEMA, uid: caller.uid, kind: "generate", fetchImpl });
      const normalized = normalizeRecipe(answer);
      if (normalized.error) throw refused(`the model's recipe was unusable: ${normalized.error}`, "upstream", 502);
      // The first picture that can actually be fetched, out of the first page.
      let image = { path: null, fileName: null };
      if (imageSearch.configured(keys.serper)) {
        const query = request.imageQuery || (typeof answer.imageQuery === "string" && answer.imageQuery) || request.title;
        try {
          const page = await imageSearch.search(imageSearch.parseRequest({ query, start: 1, lang: "en" }), { key: keys.serper, fetchImpl, db, now });
          for (const item of (page.items || []).slice(0, 5)) {
            try {
              image = await recipeImage({ bucket, authorUid: author.uid, image: { url: item.url }, fetchImpl });
              break;
            } catch (err) {
              logger.info("seed picture skipped", { url: item.url, reason: err.message });
            }
          }
        } catch (err) {
          logger.warn("seed picture search failed", { reason: err.message });
        }
      }
      const id = crypto.randomUUID();
      const ref = db.doc(`shared_recipes/${id}`);
      await ref.set({
        sourceRecipeId: crypto.randomUUID(),
        ...normalized.recipe,
        imageFileName: image.fileName,
        imageStoragePath: image.path,
        authorUid: author.uid,
        authorName: author.name,
        authorPhotoUrl: author.photoUrl,
        likeCount: 0,
        createdAt: ts(backdated(request.createdAt, now)),
      });
      let liked = 0;
      const wanted = Math.min(cleanInt(request.likes, { min: 0, max: 200 }) || 0, personas.length);
      if (wanted > 0) {
        const others = personas.filter((p) => p.uid !== author.uid).sort(() => Math.random() - 0.5).slice(0, wanted);
        for (const p of others) if (await setLike(db, ref, p.uid, true)) liked++;
      }
      return { id, title: normalized.recipe.title, as: author.uid, authorName: author.name, image: !!image.path, liked };
    }
    case "text.generate": {
      const answer = await gemini({ key: keys.gemini, prompt: textPrompt(request), schema: TEXT_SCHEMA, uid: caller.uid, kind: "text", fetchImpl });
      return { title: typeof answer.title === "string" ? answer.title.trim().slice(0, 200) : "", body: typeof answer.body === "string" ? answer.body.trim().slice(0, 8000) : "" };
    }
    case "image.search": {
      if (!imageSearch.configured(keys.serper)) throw refused("image search is not configured", "not_configured", 503);
      const parsed = imageSearch.parseRequest({ query: request.query, start: request.start || 1, lang: request.lang || "" });
      if (parsed.error === "end_of_results") return { items: [], nextStart: null, start: imageSearch.MAX_START };
      if (parsed.error) throw refused(parsed.error);
      return imageSearch.search(parsed, { key: keys.serper, fetchImpl, db, now });
    }

    // --- personas ---------------------------------------------------------
    case "persona.create": {
      const uid = personaUid();
      const gender = request.gender || (Math.random() < 0.5 ? "female" : "male");
      const source = request.photoDataUrl ? { dataUrl: request.photoDataUrl } : { url: request.photoUrl || portraitUrl(gender, crypto.randomInt(100)) };
      let photo = null;
      try {
        photo = await storeImage({ bucket, path: `profile_photos/${uid}.jpg`, source, fetchImpl });
      } catch (err) {
        // A missing portrait is not a reason to lose the persona.
        logger.warn("persona photo failed", { uid, reason: err.message });
      }
      const data = { name: request.name, gender, bio: request.bio || "", photoUrl: photo ? photo.url : null, createdAt: admin.firestore.FieldValue.serverTimestamp(), createdBy: caller.uid };
      const batch = db.batch();
      batch.set(db.doc(`${PERSONAS_COLLECTION}/${uid}`), data);
      batch.set(db.doc(`public_profiles/${uid}`), { fullName: request.name, photoUrl: data.photoUrl, updatedAt: admin.firestore.FieldValue.serverTimestamp() });
      await batch.commit();
      return { uid, photoUrl: data.photoUrl };
    }
    case "persona.update": {
      if (!isPersona(request.uid)) throw refused("not a persona", "invalid_author");
      const ref = db.doc(`${PERSONAS_COLLECTION}/${request.uid}`);
      if (!(await ref.get()).exists) throw refused("no such persona", "not_found", 404);
      const patch = {};
      if (request.name !== undefined) patch.name = request.name;
      if (request.gender !== undefined) patch.gender = request.gender;
      if (request.bio !== undefined) patch.bio = request.bio;
      if (request.photoDataUrl || request.photoUrl) {
        const photo = await storeImage({ bucket, path: `profile_photos/${request.uid}.jpg`, source: request.photoDataUrl ? { dataUrl: request.photoDataUrl } : { url: request.photoUrl }, fetchImpl });
        patch.photoUrl = photo.url;
      }
      const batch = db.batch();
      batch.set(ref, patch, { merge: true });
      const pub = { updatedAt: admin.firestore.FieldValue.serverTimestamp() };
      if (patch.name !== undefined) pub.fullName = patch.name;
      if (patch.photoUrl !== undefined) pub.photoUrl = patch.photoUrl;
      batch.set(db.doc(`public_profiles/${request.uid}`), pub, { merge: true });
      // The name and picture are also copied onto every post, the way the
      // app does it; the feed reads the live profile, but a stale copy is
      // what an old client would show.
      await batch.commit();
      if (patch.name !== undefined || patch.photoUrl !== undefined) await restampAuthor(db, request.uid, patch);
      return { photoUrl: patch.photoUrl };
    }
    case "persona.delete": {
      if (!isPersona(request.uid)) throw refused("not a persona", "invalid_author");
      const removed = request.withContent ? await removeAuthored(db, bucket, request.uid) : {};
      const batch = db.batch();
      batch.delete(db.doc(`${PERSONAS_COLLECTION}/${request.uid}`));
      batch.delete(db.doc(`public_profiles/${request.uid}`));
      await batch.commit();
      await bucket.file(`profile_photos/${request.uid}.jpg`).delete().catch(() => {});
      return removed;
    }
    case "persona.suggest": {
      const count = cleanInt(request.count, { min: 1, max: 30 }) || 8;
      let people = [];
      try {
        const answer = await gemini({ key: keys.gemini, prompt: peoplePrompt({ count, lang: request.lang }), schema: PEOPLE_SCHEMA, uid: caller.uid, kind: "text", fetchImpl });
        people = (answer.people || []).filter((p) => p && typeof p.name === "string" && p.name.trim()).slice(0, count);
      } catch (err) {
        logger.warn("persona suggestion failed", { reason: err.message });
      }
      return {
        people: people.map((p) => {
          const gender = p.gender === "male" ? "male" : "female";
          return { name: p.name.trim().slice(0, 80), gender, photoUrl: portraitUrl(gender, crypto.randomInt(100)) };
        }),
      };
    }

    // One whole conversation: a thread by one persona and a few replies by
    // others, written together so they answer each other, dated over the
    // chosen span, liked by a few more. Driven one at a time by the page.
    case "forum.seedThread": {
      const personas = await personaList(db);
      if (personas.length < 2) throw refused("need at least two personas", "no_personas");
      const wantedReplies = cleanInt(request.replies, { min: 0, max: 12 }) ?? 3;
      const shuffled = personas.sort(() => Math.random() - 0.5);
      const cast = [shuffled[0]];
      for (let i = 0; i < wantedReplies; i++) cast.push(shuffled[1 + (i % (shuffled.length - 1))]);
      const answer = await gemini({ key: keys.gemini, prompt: threadPrompt({ lang: request.lang, topic: request.topic, replies: wantedReplies, names: cast.map((p) => p.name) }), schema: THREAD_SCHEMA, uid: caller.uid, kind: "text", fetchImpl });
      const title = typeof answer.title === "string" ? answer.title.trim().slice(0, 200) : "";
      const body = typeof answer.body === "string" ? answer.body.trim().slice(0, 8000) : "";
      if (!title || !body) throw refused("the model's thread was unusable", "upstream", 502);
      const replies = (answer.replies || []).map((r) => (r && typeof r.body === "string" ? r.body.trim().slice(0, 8000) : "")).filter(Boolean).slice(0, wantedReplies);
      const spanMs = Math.max(0, cleanInt(request.days, { min: 0, max: 365 }) ?? 30) * 24 * 3600 * 1000;
      // The thread somewhere in the span, leaving room for the replies; each
      // reply minutes to a day after the one before, never past now.
      const postAt = now - Math.floor(Math.random() * spanMs * 0.85) - 3600 * 1000;
      const postRef = db.collection("forum_posts").doc(crypto.randomUUID());
      const batch = db.batch();
      const author = cast[0];
      batch.set(postRef, { title, body, authorUid: author.uid, authorName: author.name, authorPhotoUrl: author.photoUrl || null, replyCount: replies.length, likeCount: 0, createdAt: ts(backdated(postAt, now)) });
      let at = postAt;
      replies.forEach((text, i) => {
        const who = cast[i + 1];
        at = Math.min(now, at + 5 * 60 * 1000 + Math.floor(Math.random() * 20 * 3600 * 1000));
        batch.set(postRef.collection("replies").doc(crypto.randomUUID()), { body: text, authorUid: who.uid, authorName: who.name, authorPhotoUrl: who.photoUrl || null, sharedRecipeId: null, sharedRecipeTitle: null, likeCount: 0, createdAt: ts(at) });
      });
      await batch.commit();
      let liked = 0;
      const wantedLikes = Math.min(cleanInt(request.likes, { min: 0, max: 200 }) || 0, personas.length);
      for (const p of personas.filter((x) => x.uid !== author.uid).sort(() => Math.random() - 0.5).slice(0, wantedLikes)) {
        if (await setLike(db, postRef, p.uid, true)) liked++;
      }
      return { postId: postRef.id, title, replies: replies.length, authorName: author.name, liked };
    }

    // --- households -------------------------------------------------------
    case "household.removeMember": {
      const snap = await db.doc(`households/${request.hid}`).get();
      if (!snap.exists) throw refused("no such household", "not_found", 404);
      const result = await households.remove(db, snap.get("ownerUid"), request.uid);
      if (result.error) throw refused(result.error, result.error, 409);
      return {};
    }
    case "household.dissolve": {
      const snap = await db.doc(`households/${request.hid}`).get();
      if (!snap.exists) throw refused("no such household", "not_found", 404);
      const result = await households.dissolve(db, snap.get("ownerUid"));
      if (result.error) throw refused(result.error, result.error, 409);
      return {};
    }

    // --- console ----------------------------------------------------------
    case "config.get": {
      const template = await admin.remoteConfig().getTemplate();
      return { version: template.version && template.version.versionNumber, parameters: remoteConfig.flattenTemplate(template) };
    }
    case "config.set": {
      const template = await admin.remoteConfig().getTemplate();
      const error = remoteConfig.applyValue(template, request.name, request.value === undefined ? "" : request.value);
      if (error) throw refused(error, error, error === "not_found" ? 404 : 400);
      const published = await remoteConfig.publish(template);
      return { version: published.version && published.version.versionNumber, parameters: remoteConfig.flattenTemplate(published) };
    }
    case "config.add": {
      if (!/^[A-Za-z_][A-Za-z0-9_]{0,119}$/.test(request.name)) throw refused("name must be letters, digits and underscores", "invalid_name");
      const template = await admin.remoteConfig().getTemplate();
      if (remoteConfig.findParam(template, request.name)) throw refused("parameter exists", "exists", 409);
      const param = { defaultValue: { value: "" }, description: request.description || "", valueType: request.valueType };
      if (request.group) {
        template.parameterGroups = template.parameterGroups || {};
        template.parameterGroups[request.group] = template.parameterGroups[request.group] || { parameters: {} };
        template.parameterGroups[request.group].parameters[request.name] = param;
      } else {
        template.parameters[request.name] = param;
      }
      const error = remoteConfig.applyValue(template, request.name, request.value === undefined ? "" : request.value);
      if (error) throw refused(error, error);
      const published = await remoteConfig.publish(template);
      return { version: published.version && published.version.versionNumber, parameters: remoteConfig.flattenTemplate(published) };
    }
    case "config.delete": {
      const template = await admin.remoteConfig().getTemplate();
      let found = false;
      if (template.parameters && template.parameters[request.name]) {
        delete template.parameters[request.name];
        found = true;
      }
      for (const group of Object.values(template.parameterGroups || {})) {
        if (group.parameters && group.parameters[request.name]) {
          delete group.parameters[request.name];
          found = true;
        }
      }
      if (!found) throw refused("not_found", "not_found", 404);
      const published = await remoteConfig.publish(template);
      return { version: published.version && published.version.versionNumber, parameters: remoteConfig.flattenTemplate(published) };
    }
    case "pricing.sync":
      return { ...(await aiUsage.repairUsage()), ...(await syncRate()), ...(await syncPricing()) };

    // --- store downloads --------------------------------------------------
    case "stores.stats":
      return storeStats.stats(db, fetchImpl);
    case "stores.status":
      return storeStats.status(db, fetchImpl);
    case "stores.config": {
      const { action, ...patch } = request;
      const saved = await storeStats.saveConfig(db, patch);
      return { config: saved.config, keyPresent: saved.keyPresent };
    }
    case "stores.sync":
      return storeStats.sync({ db, platform: request.platform || "all", backfill: request.backfill === true, fetchImpl });

    default:
      throw refused("unknown action");
  }
}

// The picture for a shared recipe, stored under the author like the app's
// own uploads. `storagePath` keeps one already in the bucket; `url` and
// `dataUrl` bring a new one in.
async function recipeImage({ bucket, authorUid, image, fetchImpl }) {
  if (!image || typeof image !== "object") return { path: null, fileName: null };
  if (typeof image.storagePath === "string" && image.storagePath) {
    return { path: image.storagePath, fileName: image.storagePath.split("/").pop() };
  }
  if (!image.url && !image.dataUrl) return { path: null, fileName: null };
  const stored = await storeImage({ bucket, path: `recipe_images/${authorUid}/${crypto.randomUUID()}`, source: image, fetchImpl });
  return { path: stored.path, fileName: stored.path.split("/").pop() };
}

// Rewrites the author's name and picture on every thread, reply and
// recipe the persona wrote.
async function restampAuthor(db, uid, patch) {
  const stamp = {};
  if (patch.name !== undefined) stamp.authorName = patch.name;
  if (patch.photoUrl !== undefined) stamp.authorPhotoUrl = patch.photoUrl;
  const queries = [
    db.collection("forum_posts").where("authorUid", "==", uid),
    db.collectionGroup("replies").where("authorUid", "==", uid),
    db.collection("shared_recipes").where("authorUid", "==", uid),
  ];
  for (const query of queries) {
    const snap = await query.get();
    for (let i = 0; i < snap.docs.length; i += 400) {
      const batch = db.batch();
      for (const doc of snap.docs.slice(i, i + 400)) batch.update(doc.ref, stamp);
      await batch.commit();
    }
  }
}

// Everything a persona wrote, gone: threads with their replies and likes,
// its replies on other threads (and the counters they moved), its recipes
// and their pictures. Likes it gave stay, as a departed member's would.
async function removeAuthored(db, bucket, uid) {
  const result = { posts: 0, replies: 0, recipes: 0 };
  const posts = await db.collection("forum_posts").where("authorUid", "==", uid).get();
  for (const doc of posts.docs) {
    await db.recursiveDelete(doc.ref);
    result.posts++;
  }
  const replies = await db.collectionGroup("replies").where("authorUid", "==", uid).get();
  for (const doc of replies.docs) {
    const post = doc.ref.parent.parent;
    await db.recursiveDelete(doc.ref);
    if (post) await post.update({ replyCount: admin.firestore.FieldValue.increment(-1) }).catch(() => {});
    result.replies++;
  }
  const recipes = await db.collection("shared_recipes").where("authorUid", "==", uid).get();
  for (const doc of recipes.docs) {
    const path = doc.get("imageStoragePath");
    await db.recursiveDelete(doc.ref);
    if (typeof path === "string" && path) await bucket.file(path).delete().catch(() => {});
    result.recipes++;
  }
  return result;
}

async function audit(db, { caller, request, ok, error, ms }) {
  try {
    await db.collection(AUDIT_COLLECTION).add({
      action: request.action || "?",
      by: caller.uid,
      email: caller.email || "",
      params: summarize(request),
      ok,
      error: error || null,
      ms,
      at: admin.firestore.FieldValue.serverTimestamp(),
    });
  } catch (err) {
    logger.warn("audit write failed", { reason: err.message });
  }
}

exports.adminPanel = onRequest(
  { region: "europe-west1", cors: ORIGINS, maxInstances: 3, timeoutSeconds: 300, memory: "512MiB", secrets: [geminiApiKey, serperApiKey] },
  async (req, res) => {
    if (req.method !== "POST") return res.status(405).json({ error: { message: "POST only" } });
    const caller = await proxy.verifyCaller(req);
    if (!caller) return res.status(401).json({ error: { message: "A valid Firebase ID token is required" } });
    if (!accounts.isAdmin(caller)) return res.status(403).json({ error: { message: "Administrator only" } });

    const request = parseRequest(req.body || {});
    if (request.error) return res.status(400).json({ error: { code: "invalid", message: request.error } });
    if (request.uid === caller.uid && /^user\.(disable|delete|kick)$/.test(request.action)) {
      return res.status(400).json({ error: { code: "self", message: "Not on your own account" } });
    }

    const db = admin.firestore();
    const started = Date.now();
    try {
      const result = await run(request, { caller, db, bucket: admin.storage().bucket(), keys: { gemini: geminiApiKey.value(), serper: serperApiKey.value() } });
      await audit(db, { caller, request, ok: true, ms: Date.now() - started });
      logger.info("admin panel action", { action: request.action, by: caller.uid });
      return res.status(200).json({ ok: true, ...result });
    } catch (err) {
      await audit(db, { caller, request, ok: false, error: err.message, ms: Date.now() - started });
      const status = err.status || 500;
      if (status >= 500) logger.error("admin panel action failed", { action: request.action, reason: err.message });
      return res.status(status).json({ error: { code: err.code || "failed", message: err.message } });
    }
  },
);

exports.internals = {
  ACTIONS,
  parseRequest,
  isPersona,
  personaUid,
  backdated,
  normalizeRecipe,
  portraitUrl,
  summarize,
  decodeDataUrl,
  sniffImage,
  recipePrompt,
  textPrompt,
  dishesPrompt,
  threadPrompt,
  peoplePrompt,
  run,
  ORIGINS,
  PERSONA_PREFIX,
};
