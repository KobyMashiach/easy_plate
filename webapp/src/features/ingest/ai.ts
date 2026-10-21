// The recipe-ingestion model calls, field for field as the app sends them
// (lib/features/recipe_ingestion/data/datasources/recipe_ai_datasource.dart,
// GeminiRecipeAiDataSource). Key order matches the Dart maps on purpose: the
// proxy keys its shared URL cache on a hash of the request body, so a link
// the phone already extracted is answered from the cache here too.
import { ApiError } from "../../lib/api";
import { callFunction, interactions, quotaOf } from "../../lib/functions";
import { newId } from "../../lib/cloud";
import { ALLERGENS, DIETARY, MEASUREMENT_UNITS, type Allergen, type DietaryPreference, type IngestionChannel, type Ingredient, type MeasurementUnit, type Nutrition, type Recipe } from "../../models/recipe";
import { GENERATE_SYSTEM_PROMPT, SYSTEM_PROMPT } from "./prompts";

// ApiConfig defaults (lib/core/constants/api_config.dart).
export const MODEL = "gemini-3.8-flash";
export const SEARCH_MODEL = "gemini-3.5-flash-lite";
const THINKING_LEVEL = "low";
const SEARCH_THINKING_LEVEL = "minimal";

const servingsSchema = {
  type: "integer",
  minimum: 1,
  description: "How many servings the recipe yields. Use the stated yield; otherwise estimate from the ingredient amounts",
};

const nutritionSchema = {
  type: "object",
  description:
    "Estimated nutrition for ONE serving, derived from the ingredient amounts divided by servings. Estimate from typical values when amounts are missing",
  properties: {
    calories: { type: "integer", description: "kcal per serving" },
    protein_g: { type: "number", description: "grams of protein per serving" },
    carbs_g: { type: "number", description: "grams of carbohydrate per serving" },
    fat_g: { type: "number", description: "grams of fat per serving" },
  },
  required: ["calories", "protein_g", "carbs_g", "fat_g"],
};

const allergenNames = ["gluten", "milk", "eggs", "fish", "shellfish", "peanuts", "treeNuts", "sesame", "soy"];

export const RECIPE_SCHEMA = {
  type: "object",
  properties: {
    title: { type: "string", description: "Dish title as written in the source" },
    prep_time_minutes: { type: "integer", description: "Preparation time in minutes. Omit if the source does not state it" },
    cook_time_minutes: { type: "integer", description: "Cook time in minutes. Omit if the source does not state it" },
    ingredients: {
      type: "array",
      items: {
        type: "object",
        properties: {
          name: { type: "string" },
          amount: { type: "number", description: "Numeric amount. Omit if the source omits it" },
          unit: {
            type: "string",
            enum: ["gram", "kilogram", "milliliter", "liter", "teaspoon", "tablespoon", "cup", "unit", "pinch", "unspecified"],
          },
        },
        required: ["name", "unit"],
      },
    },
    steps: { type: "array", items: { type: "string" }, description: "Ordered preparation steps, without numbering prefixes" },
    dietary_tags: {
      type: "array",
      items: { type: "string", enum: ["meat", "dairy", "vegetarian", "vegan", "kosher", "glutenFree", "allergy"] },
      description: "Dietary tags decided from the ingredient list alone. Empty when none clearly applies",
    },
    allergens: { type: "array", items: { type: "string", enum: allergenNames }, description: "Allergens actually present in the ingredient list" },
    may_contain: {
      type: "array",
      items: { type: "string", enum: allergenNames },
      description: "Allergens the source explicitly warns may be present as traces. Empty unless stated",
    },
    servings: servingsSchema,
    nutrition: nutritionSchema,
  },
  required: ["title", "ingredients", "steps", "dietary_tags", "allergens", "may_contain", "servings", "nutrition"],
};

const SEARCH_RESULTS_SCHEMA = {
  type: "object",
  properties: {
    results: {
      type: "array",
      items: {
        type: "object",
        properties: { title: { type: "string" }, url: { type: "string" }, snippet: { type: "string" } },
        required: ["title", "url", "snippet"],
      },
    },
  },
  required: ["results"],
};

/** `_body` in the datasource: the same keys, in the same order. */
function body({
  input,
  schema,
  systemInstruction = SYSTEM_PROMPT,
  tools = [],
  model = MODEL,
  thinkingLevel = THINKING_LEVEL,
}: {
  input: unknown;
  schema: object;
  systemInstruction?: string;
  tools?: object[];
  model?: string;
  thinkingLevel?: string;
}): Record<string, unknown> {
  const out: Record<string, unknown> = { model, system_instruction: systemInstruction, input };
  if (tools.length) out.tools = tools;
  if (thinkingLevel) out.generation_config = { thinking_level: thinkingLevel };
  out.response_format = { type: "text", mime_type: "application/json", schema };
  return out;
}

/** `_dietaryHint`: only the social, generate and search prompts carry it. */
function dietaryHint(prefs: DietaryPreference[]): string {
  if (!prefs.length) return "";
  return `\nהעדפות תזונתיות של המשתמש: ${prefs.join(", ")}.`;
}

// ---------------------------------------------------------------------------
// Errors, typed the way the app's bloc tells them apart.

export type IngestErrorKind = "quota" | "unreadable" | "network" | "timeout" | "cancelled" | "parsing" | "refused" | "failed";

export class IngestError extends Error {
  kind: IngestErrorKind;
  constructor(kind: IngestErrorKind, message: string = kind) {
    super(message);
    this.kind = kind;
  }
}

export function classify(err: unknown, signal?: AbortSignal): IngestError {
  if (err instanceof IngestError) return err;
  if (signal?.aborted) return new IngestError(signal.reason === "timeout" ? "timeout" : "cancelled");
  if (err instanceof DOMException && err.name === "AbortError") return new IngestError("cancelled");
  if (quotaOf(err)) return new IngestError("quota");
  if (err instanceof ApiError) {
    const status = (err.extra as { error?: { status?: unknown } }).error?.status;
    if (err.status === 422 && (status === "SOCIAL_UNREADABLE" || status === "SOCIAL_EMPTY")) return new IngestError("unreadable");
    // About the account, not the request: the message carries the code (err.<code>).
    if (err.status === 403 && (err.code === "phone_required" || err.code === "account_disabled")) return new IngestError("refused", err.code);
    return new IngestError("failed", err.message);
  }
  if (err instanceof TypeError) return new IngestError("network");
  return new IngestError("failed", String(err));
}

/** HttpCalls.errorTypeFor's `overloaded`: worth the identical request again. */
function isCapacity(err: unknown): boolean {
  return err instanceof ApiError && !quotaOf(err) && [429, 500, 502, 503, 504, 529].includes(err.status);
}

function sleep(ms: number, signal?: AbortSignal): Promise<void> {
  return new Promise((resolve, reject) => {
    const id = window.setTimeout(resolve, ms);
    signal?.addEventListener("abort", () => {
      window.clearTimeout(id);
      reject(new DOMException("aborted", "AbortError"));
    }, { once: true });
  });
}

/** `_callRaw`: two sub-second retries on a capacity error, nothing else. */
async function callRaw(
  req: Record<string, unknown>,
  opts: { feature: string; sourceUrl?: string; sourceKind?: string; signal?: AbortSignal },
): Promise<Record<string, unknown>> {
  for (let attempt = 0; ; attempt++) {
    try {
      const data = await interactions<Record<string, unknown> | null>(req, opts);
      if (!data || typeof data !== "object") throw new IngestError("parsing");
      return data;
    } catch (e) {
      if (!isCapacity(e) || attempt >= 2 || opts.signal?.aborted) throw e;
      await sleep(600 << attempt, opts.signal);
    }
  }
}

/** `_extractText` + `_decodeRecipe`: every text block, then the outer JSON object. */
export function decodeJson(data: Record<string, unknown>): Record<string, unknown> {
  let text = "";
  for (const step of Array.isArray(data.steps) ? data.steps : []) {
    if (!step || typeof step !== "object") continue;
    const content = (step as { content?: unknown }).content;
    for (const block of Array.isArray(content) ? content : []) {
      if (block && typeof block === "object" && typeof (block as { text?: unknown }).text === "string") text += (block as { text: string }).text;
    }
  }
  const start = text.indexOf("{");
  const end = text.lastIndexOf("}");
  if (start === -1 || end <= start) throw new IngestError("parsing", "No recipe returned by the model");
  try {
    const parsed = JSON.parse(text.slice(start, end + 1));
    if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) throw new Error("not an object");
    return parsed as Record<string, unknown>;
  } catch (_) {
    throw new IngestError("parsing");
  }
}

// ---------------------------------------------------------------------------
// The model's answer → a Recipe (`_toEntity`, shape-tolerant like the app).

const numOrNull = (v: unknown): number | null => (typeof v === "number" && Number.isFinite(v) ? v : null);

function namesFrom<T extends string>(raw: unknown, all: readonly T[]): T[] {
  if (!Array.isArray(raw)) return [];
  const set = new Set(raw.filter((x): x is string => typeof x === "string"));
  return all.filter((v) => set.has(v));
}

export function nutritionFromModel(raw: unknown): Nutrition | null {
  if (!raw || typeof raw !== "object") return null;
  const r = raw as Record<string, unknown>;
  const cal = numOrNull(r.calories);
  if (cal === null) return null;
  const grams = (k: string) => Math.max(0, numOrNull(r[k]) ?? 0);
  return { calories: Math.max(0, Math.trunc(cal)), proteinGrams: grams("protein_g"), carbsGrams: grams("carbs_g"), fatGrams: grams("fat_g") };
}

export function toRecipe(input: Record<string, unknown>, channel: IngestionChannel, sourceUrl: string | null = null): Recipe {
  const ingredients: Ingredient[] = [];
  for (const raw of Array.isArray(input.ingredients) ? input.ingredients : []) {
    if (!raw || typeof raw !== "object") continue;
    const r = raw as Record<string, unknown>;
    if (typeof r.name !== "string" || !r.name.trim()) continue;
    const unit = (MEASUREMENT_UNITS as readonly string[]).includes(r.unit as string) ? (r.unit as MeasurementUnit) : "unspecified";
    ingredients.push({ name: r.name.trim(), amount: numOrNull(r.amount), unit });
  }
  const title = input.title;
  if (typeof title !== "string" || !title.trim()) throw new IngestError("parsing", "No recipe title returned by the model");
  const allergens = namesFrom<Allergen>(input.allergens, ALLERGENS);
  // Allergen.fromNames keeps the list order of the enum; dietaryTagsFromModel too.
  let tags = namesFrom<DietaryPreference>(input.dietary_tags, DIETARY);
  if (allergens.length && !tags.includes("allergy")) tags = [...tags, "allergy"];
  const int = (v: unknown) => (numOrNull(v) === null ? null : Math.trunc(v as number));
  const servings = int(input.servings);
  return {
    id: newId(),
    title: title.trim(),
    prepTimeMinutes: int(input.prep_time_minutes),
    cookTimeMinutes: int(input.cook_time_minutes),
    ingredients,
    steps: (Array.isArray(input.steps) ? input.steps : []).filter((s): s is string => typeof s === "string"),
    dietaryTags: tags,
    sourceChannel: channel,
    sourceUrl,
    createdAt: new Date().toISOString(),
    imageFileName: null,
    savedFromSharedId: null,
    pendingAnalysis: false,
    collabId: null,
    collabRole: null,
    imageStoragePath: null,
    allergens,
    mayContain: namesFrom<Allergen>(input.may_contain, ALLERGENS),
    servings: servings === null || servings < 1 ? null : servings,
    nutrition: nutritionFromModel(input.nutrition),
    sharedRecipeId: null,
    contentLang: null,
    contentVersion: 0,
  };
}

/** `buildTemplateRecipe`: the unanalysed text, every line a step, flagged for later. */
export function templateRecipe(text: string, channel: IngestionChannel, untitled: string, sourceUrl: string | null = null): Recipe {
  const lines = text.split("\n").map((l) => l.trim()).filter(Boolean);
  const first = lines.length ? lines[0] : untitled;
  const title = first.length > 80 ? `${first.slice(0, 77)}…` : first;
  return { ...blank(channel), title, steps: lines, sourceUrl, pendingAnalysis: true };
}

export function blank(channel: IngestionChannel): Recipe {
  return {
    id: newId(),
    title: "",
    prepTimeMinutes: null,
    cookTimeMinutes: null,
    ingredients: [],
    steps: [],
    dietaryTags: [],
    sourceChannel: channel,
    sourceUrl: null,
    createdAt: new Date().toISOString(),
    imageFileName: null,
    savedFromSharedId: null,
    pendingAnalysis: false,
    collabId: null,
    collabRole: null,
    imageStoragePath: null,
    allergens: [],
    mayContain: [],
    servings: null,
    nutrition: null,
    sharedRecipeId: null,
    contentLang: null,
    contentVersion: 0,
  };
}

// ---------------------------------------------------------------------------
// The calls.

export interface InlineFile {
  name: string;
  mimeType: string;
  size: number;
  /** base64, no data: prefix. */
  data: string;
}

export const isPdf = (f: { mimeType: string }) => f.mimeType === "application/pdf";
export const isAudio = (f: { mimeType: string }) => f.mimeType.startsWith("audio/");

type Signal = { signal?: AbortSignal };

export async function parseRawText(text: string, { signal }: Signal = {}): Promise<Recipe> {
  const data = await callRaw(body({ input: `נתח את המתכון הבא לפורמט מובנה:\n\n${text}`, schema: RECIPE_SCHEMA }), { feature: "text", signal });
  return toRecipe(decodeJson(data), "rawText");
}

export async function parseFromUrl(url: string, { signal }: Signal = {}): Promise<Recipe> {
  const data = await callRaw(
    body({
      input: `שלוף את המתכון מהכתובת הבאה והחזר אותו בפורמט מובנה. התעלם מפרסומות ותוכן שאינו חלק מהמתכון.\n${url}`,
      schema: RECIPE_SCHEMA,
      tools: [{ type: "url_context" }],
    }),
    { feature: "url", sourceUrl: url, sourceKind: "url", signal },
  );
  return toRecipe(decodeJson(data), "urlScrape", url);
}

/** The video path through the socialRecipe function (the app behind the proxy). */
export async function parseFromSocialVideo(url: string, prefs: DietaryPreference[], { signal }: Signal = {}): Promise<Recipe> {
  const data = await callFunction<Record<string, unknown> | null>(
    "socialRecipe",
    {
      url,
      model: MODEL,
      system_instruction: SYSTEM_PROMPT,
      prompt:
        "שלוף את המתכון מהסרטון הבא: מהטקסט שמופיע על המסך, ממה שנאמר, ממה שנעשה, ומהכיתוב. " +
        "אם הכמויות לא נאמרות אך נראות, הערך אותן. אם אין מתכון בסרטון, החזר רשימות ריקות." +
        dietaryHint(prefs),
      schema: RECIPE_SCHEMA,
    },
    { signal },
  );
  if (!data || typeof data !== "object") throw new IngestError("parsing");
  return toRecipe(decodeJson(data), "socialVideo", url);
}

export async function parseFromFiles(files: InlineFile[], { signal }: Signal = {}): Promise<Recipe> {
  if (!files.length) throw new IngestError("parsing");
  const hasAudio = files.some(isAudio);
  const hasPdf = files.some(isPdf);
  const what = hasAudio && hasPdf ? "ההקלטות והמסמכים המצורפים" : hasAudio ? "ההקלטות המצורפות" : "המסמכים המצורפים";
  const prompt =
    files.length === 1
      ? isPdf(files[0])
        ? "קרא את המסמך המצורף וחלץ ממנו את המתכון לפורמט מובנה. אם יש בו כמה מתכונים, חלץ את הראשון."
        : "ההקלטה המצורפת היא מתכון שמישהו מקריא או מספר. תמלל אותה לעצמך, וחלץ ממנה את המתכון לפורמט מובנה — שם, מצרכים עם כמויות, ושלבי הכנה בסדר שנאמרו."
      : `${what} (${files.length}) הם חלקים של מתכון אחד, לפי הסדר שבו הם מופיעים — למשל הודעה קולית שנשלחה בכמה קטעים. התייחס אליהם כהקלטה אחת רצופה: תמלל לעצמך את כולם ברצף, וחלץ מתכון אחד לפורמט מובנה — שם, מצרכים עם כמויות, ושלבי הכנה בסדר שנאמרו. אל תחזיר כמה מתכונים.`;
  const input = [
    ...files.map((f) => ({ type: isPdf(f) ? "document" : "audio", mime_type: f.mimeType, data: f.data })),
    { type: "text", text: prompt },
  ];
  const data = await callRaw(body({ input, schema: RECIPE_SCHEMA }), { feature: "file", signal });
  return toRecipe(decodeJson(data), "file");
}

export async function generateRecipe(request: string, prefs: DietaryPreference[], { signal }: Signal = {}): Promise<Recipe> {
  const data = await callRaw(
    body({ input: `כתוב מתכון מלא לפי הבקשה הבאה:\n\n${request}${dietaryHint(prefs)}`, schema: RECIPE_SCHEMA, systemInstruction: GENERATE_SYSTEM_PROMPT }),
    { feature: "generate", signal },
  );
  return toRecipe(decodeJson(data), "aiRequest");
}

export interface SearchResult {
  title: string;
  url: string;
  snippet: string;
}

export async function searchWeb(query: string, prefs: DietaryPreference[], { signal }: Signal = {}): Promise<SearchResult[]> {
  const data = decodeJson(
    await callRaw(
      body({
        input: `חפש 3 עד 5 מתכונים באינטרנט עבור: ${query}.${dietaryHint(prefs)}`,
        schema: SEARCH_RESULTS_SCHEMA,
        tools: [{ type: "google_search" }],
        model: SEARCH_MODEL,
        thinkingLevel: SEARCH_THINKING_LEVEL,
      }),
      { feature: "search", signal },
    ),
  );
  const out: SearchResult[] = [];
  for (const r of Array.isArray(data.results) ? data.results : []) {
    // Links come from the model's answer: only real web pages (http/https)
    // ever reach a link or the extractor; anything else is dropped here.
    if (r && typeof r === "object" && typeof r.title === "string" && typeof r.url === "string" && /^https?:\/\/[^\s]+$/i.test(r.url) && r.url.length <= 2048) {
      out.push({ title: r.title.slice(0, 200), url: r.url, snippet: typeof r.snippet === "string" ? r.snippet.slice(0, 500) : "" });
    }
  }
  return out;
}
