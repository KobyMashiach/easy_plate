// The Gemini calls the recipe screens make, copied field for field from the
// app's RecipeAiDataSource (lib/features/recipe_ingestion/data/datasources/
// recipe_ai_datasource.dart): the same model, system prompts, JSON schemas,
// feature header and capacity retries — so the proxy's quota, cost
// accounting and caches treat a web call exactly like a phone call.
import { ApiError, refusalText } from "../../../lib/api";
import { interactions, quotaOf } from "../../../lib/functions";
import { ALLERGENS, DIETARY, MEASUREMENT_UNITS, type Allergen, type DietaryPreference, type Ingredient, type Nutrition, type Recipe } from "../../../models/recipe";

// ApiConfig defaults (lib/core/constants/api_config.dart).
const MODEL = "gemini-3.8-flash";
const IMAGE_MODEL = "gemini-3.1-flash-image";
const THINKING_LEVEL = "low";

const DIETARY_TAG_RULES = `בנוסף, קבע את התגיות התזונתיות של המתכון בשדה dietary_tags — אך ורק לפי רשימת המצרכים, לא לפי הכותרת ולא לפי ניחוש:
meat — המתכון מכיל בשר, עוף או מוצריהם.
dairy — המתכון מכיל חלב, גבינה, חמאה, שמנת, יוגורט או מוצר חלב אחר.
vegetarian — אין במתכון בשר, עוף או דגים (ביצים ומוצרי חלב מותרים).
vegan — אין במתכון שום מוצר מן החי: לא בשר, לא דגים, לא ביצים, לא חלב ולא דבש. מתכון טבעוני הוא גם צמחוני — סמן את שתי התגיות.
kosher — רק אם אין במתכון מאכלים אסורים (חזיר, פירות ים, דגים ללא סנפיר וקשקשת) וגם אין ערבוב של בשר עם חלב באותו מתכון.
glutenFree — רק אם אין במתכון קמח חיטה, לחם, פסטה, קוסקוס, סולת, בורגול, שעורה, שיפון, שיבולת שועל רגילה, רוטב סויה או כל מצרך אחר שמכיל גלוטן.
allergy — אם ורק אם שדה allergens אינו ריק.
תגית נקבעת רק כשהמצרכים מצדיקים אותה בבירור. בספק — אל תסמן.

קבע גם את שדה allergens — האלרגנים שנמצאים בפועל במצרכים, מתוך הרשימה הזו בלבד:
gluten (חיטה, קמח, לחם, פסטה, קוסקוס, סולת, בורגול, שעורה, שיפון), milk (חלב, גבינה, חמאה, שמנת, יוגורט), eggs (ביצים), fish (דגים), shellfish (פירות ים), peanuts (בוטנים), treeNuts (שקדים, אגוזי מלך, אגוזי לוז, קשיו, פיסטוק, פקאן), sesame (שומשום, טחינה), soy (סויה, רוטב סויה, טופו).
שדה may_contain — רק אלרגנים שהמקור מציין במפורש שהמתכון עלול להכיל אותם (למשל "עלול להכיל עקבות אגוזים"). בלי ציון מפורש כזה — רשימה ריקה. אל תנחש.`;

const SYSTEM_PROMPT = `אתה מנתח מתכונים. החזר אך ורק מידע שמופיע במקור.
מדיניות אפס הזיות: אסור להמציא מצרכים, כמויות, יחידות מידה או שלבים שאינם מופיעים במקור.
אם כמות, יחידה או זמן חסרים במקור — השמט את השדה לגמרי. אל תנחש.
המר כמויות ליחידות מטריות כאשר המקור מציין יחידה ברורה.
שמור על סדר השלבים כפי שהוא במקור.
${DIETARY_TAG_RULES}
יוצא מן הכלל אחד: את מספר המנות ואת הערכים התזונתיים למנה (קלוריות, חלבון, פחמימות, שומן) עליך תמיד להעריך לפי המצרכים והכמויות, גם כשהמקור לא מציין אותם. אלה הערכות סבירות, לא המצאות.
החזר JSON בלבד, ללא טקסט נלווה וללא גדרות קוד.`;

const GENERATE_SYSTEM_PROMPT = `אתה שף ומפתח מתכונים. המשתמש מתאר מנה שהוא רוצה להכין, ואתה כותב לו מתכון מלא ומעשי.
כתוב את המתכון בשפה שבה נכתבה הבקשה.
המתכון חייב להיות שלם: כותרת קצרה, זמן הכנה וזמן בישול בדקות, רשימת מצרכים עם כמות ויחידת מידה לכל מצרך, ושלבי הכנה ברורים לפי הסדר.
ציין תמיד את מספר המנות שהמתכון מניב, ואת הערכים התזונתיים למנה אחת — קלוריות, חלבון, פחמימות ושומן בגרמים — מחושבים מהמצרכים והכמויות שכתבת חלקי מספר המנות. אם הבקשה מציינת כמות סועדים, זה מספר המנות.
השתמש ביחידות מטריות (גרם, מ"ל, כפית, כף, כוס, יחידה).
התאם את המתכון לכל דרישה שבבקשה — גיל, אלרגיות, העדפות תזונתיות, כמות סועדים, זמן — ולהעדפות התזונתיות של המשתמש אם צוינו. אם הבקשה מזכירה תינוק או ילד קטן, הקפד על התאמה בטיחותית לגיל (ללא דבש מתחת לגיל שנה, ללא מלח או סוכר מוספים לתינוקות, מרקם מתאים).
${DIETARY_TAG_RULES}
אל תוסיף הערות, הקדמות או הסברים מחוץ למבנה. החזר JSON בלבד, ללא טקסט נלווה וללא גדרות קוד.`;

const REFINE_SYSTEM_PROMPT = `אתה מגיה עברית של מתכונים. הטקסט הוקלד בנייד ולכן הוא מלא בשגיאות הקלדה.
המשימה העיקרית שלך: לתקן כל שגיאת כתיב והקלדה בכותרת, בשמות המצרכים ובשלבי ההכנה.

רוב השגיאות הן אותיות שכנות במקלדת העברית או אות סופית במקום רגילה. תקן אותן תמיד:
"ןאז" → "ואז"
"עפ מלח" → "עם מלח"
"לאיזב דקה" → "לאיזה דקה"
"מערביפ" → "מערבים"
"בסיר" נשאר "בסיר" — מילה תקינה לא משתנה.
כל מילה שאינה מילה תקינה בעברית היא שגיאת הקלדה שצריך לתקן למילה הקרובה ביותר שמתאימה להקשר של המתכון.

בנוסף: עדכן זמנים שמוזכרים בתוך טקסט השלבים כך שיתאימו לזמן ההכנה ולזמן הבישול שהמשתמש קבע.

מגבלות:
אסור להוסיף, למחוק, לפצל או לאחד מצרכים או שלבים — החזר בדיוק את אותו מספר פריטים ובאותו סדר.
אסור לשנות כמויות, יחידות מידה, או את הזמנים המספריים עצמם.
אל תשנה סגנון או ניסוח של טקסט תקין — רק שגיאות.
החזר JSON בלבד, ללא טקסט נלווה וללא גדרות קוד.`;

const SERVINGS_SCHEMA = {
  type: "integer",
  minimum: 1,
  description: "How many servings the recipe yields. Use the stated yield; otherwise estimate from the ingredient amounts",
};

const NUTRITION_SCHEMA = {
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

const ESTIMATE_SCHEMA = {
  type: "object",
  properties: { servings: SERVINGS_SCHEMA, nutrition: NUTRITION_SCHEMA },
  required: ["servings", "nutrition"],
};

const RECIPE_SCHEMA = {
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
          unit: { type: "string", enum: [...MEASUREMENT_UNITS] },
        },
        required: ["name", "unit"],
      },
    },
    steps: { type: "array", items: { type: "string" }, description: "Ordered preparation steps, without numbering prefixes" },
    dietary_tags: {
      type: "array",
      items: { type: "string", enum: [...DIETARY] },
      description: "Dietary tags decided from the ingredient list alone. Empty when none clearly applies",
    },
    allergens: { type: "array", items: { type: "string", enum: [...ALLERGENS] }, description: "Allergens actually present in the ingredient list" },
    may_contain: {
      type: "array",
      items: { type: "string", enum: [...ALLERGENS] },
      description: "Allergens the source explicitly warns may be present as traces. Empty unless stated",
    },
    servings: SERVINGS_SCHEMA,
    nutrition: NUTRITION_SCHEMA,
  },
  required: ["title", "ingredients", "steps", "dietary_tags", "allergens", "may_contain", "servings", "nutrition"],
};

const REFINE_SCHEMA = {
  type: "object",
  properties: {
    title: { type: "string" },
    ingredient_names: { type: "array", items: { type: "string" }, description: "Same names in the same order, spelling corrected" },
    steps: { type: "array", items: { type: "string" }, description: "Same steps in the same order, spelling and stated times corrected" },
  },
  required: ["title", "ingredient_names", "steps"],
};

function body(input: string, schema: object, systemInstruction = SYSTEM_PROMPT) {
  return {
    model: MODEL,
    system_instruction: systemInstruction,
    input,
    generation_config: { thinking_level: THINKING_LEVEL },
    response_format: { type: "text", mime_type: "application/json", schema },
  };
}

interface InteractionResponse {
  steps?: { content?: { type?: string; text?: string; data?: string }[] }[];
}

/** Capacity errors are re-sent twice (600 ms, 1200 ms), like _callRaw; a spent quota is not. */
async function callRaw(req: object, feature: string): Promise<InteractionResponse> {
  for (let attempt = 0; ; attempt++) {
    try {
      return await interactions<InteractionResponse>(req, { feature });
    } catch (e) {
      const capacity = e instanceof ApiError && [429, 500, 502, 503, 504, 529].includes(e.status) && !quotaOf(e);
      if (!capacity || attempt >= 2) throw e;
      await new Promise((r) => setTimeout(r, 600 << attempt));
    }
  }
}

export class AiParseError extends Error {}

async function callStructured(req: object, feature: string): Promise<Record<string, unknown>> {
  const data = await callRaw(req, feature);
  let text = "";
  for (const step of data.steps ?? []) for (const block of step?.content ?? []) if (typeof block?.text === "string") text += block.text;
  const start = text.indexOf("{");
  const end = text.lastIndexOf("}");
  if (start === -1 || end <= start) throw new AiParseError("No JSON object returned");
  try {
    return JSON.parse(text.slice(start, end + 1)) as Record<string, unknown>;
  } catch (_) {
    throw new AiParseError("Bad JSON");
  }
}

/** nutritionFromModel: null when unusable; negatives clamped. */
function nutritionFromModel(raw: unknown): Nutrition | null {
  if (!raw || typeof raw !== "object") return null;
  const r = raw as Record<string, unknown>;
  if (typeof r.calories !== "number") return null;
  const g = (k: string) => Math.max(0, typeof r[k] === "number" ? (r[k] as number) : 0);
  return { calories: Math.max(0, Math.trunc(r.calories)), proteinGrams: g("protein_g"), carbsGrams: g("carbs_g"), fatGrams: g("fat_g") };
}

function servingsFrom(raw: unknown): number | null {
  const n = typeof raw === "number" ? Math.trunc(raw) : null;
  return n === null || n < 1 ? null : n;
}

/** The payload estimateNutrition sends (nutritionPayload): steps only when an amount is missing. */
function nutritionPayload(r: Recipe): string {
  const payload: Record<string, unknown> = {
    title: r.title,
    servings: r.servings,
    ingredients: r.ingredients.map((i) => ({ name: i.name, amount: i.amount, unit: i.unit })),
  };
  if (r.ingredients.some((i) => i.amount === null)) payload.steps = r.steps;
  return JSON.stringify(payload);
}

// One answer per payload for the page's life (the app's _nutritionAnswers):
// a double trigger or a re-estimate of an unchanged recipe shares a call.
const nutritionAnswers = new Map<string, Promise<{ servings: number | null; nutrition: Nutrition }>>();

/** Servings (kept when already set) and per-serving nutrition. */
export async function estimateNutrition(r: Recipe): Promise<Recipe> {
  const payload = nutritionPayload(r);
  let answer = nutritionAnswers.get(payload);
  if (!answer) {
    answer = (async () => {
      const data = await callStructured(
        body(`הערך את מספר המנות ואת הערכים התזונתיים למנה אחת של המתכון הבא. אם מספר המנות נתון, השתמש בו.\n\n${payload}`, ESTIMATE_SCHEMA),
        "nutrition",
      );
      const nutrition = nutritionFromModel(data.nutrition);
      if (!nutrition) throw new AiParseError("No nutrition returned");
      return { servings: servingsFrom(data.servings), nutrition };
    })();
    nutritionAnswers.set(payload, answer);
    answer.catch(() => nutritionAnswers.delete(payload));
    if (nutritionAnswers.size > 50) nutritionAnswers.delete(nutritionAnswers.keys().next().value as string);
  }
  const { servings, nutrition } = await answer;
  return { ...r, servings: r.servings ?? servings, nutrition };
}

/** Spelling (and, when times changed, the times written in the steps). Only words come back. */
export async function refineRecipe(r: Recipe, timesChanged: boolean): Promise<Recipe> {
  const payload = JSON.stringify({
    title: r.title,
    prep_time_minutes: r.prepTimeMinutes,
    cook_time_minutes: r.cookTimeMinutes,
    ingredient_names: r.ingredients.map((i) => i.name),
    steps: r.steps,
  });
  const instruction = timesChanged
    ? "המשתמש שינה את זמן ההכנה או את זמן הבישול. תקן שגיאות כתיב, וגם ודא שכל זמן שמוזכר בתוך שלבי ההכנה תואם לזמנים החדשים."
    : "תקן שגיאות כתיב ודקדוק בלבד.";
  const data = await callStructured(body(`${instruction}\n\n${payload}`, REFINE_SCHEMA, REFINE_SYSTEM_PROMPT), "refine");
  const names = Array.isArray(data.ingredient_names) ? data.ingredient_names.filter((x): x is string => typeof x === "string") : [];
  const steps = Array.isArray(data.steps) ? data.steps.filter((x): x is string => typeof x === "string") : [];
  return {
    ...r,
    title: typeof data.title === "string" && data.title.trim() ? data.title.trim() : r.title,
    ingredients: names.length === r.ingredients.length ? r.ingredients.map((ing, i) => ({ ...ing, name: names[i] })) : r.ingredients,
    steps: steps.length === r.steps.length ? steps : r.steps,
  };
}

/** The structured fields of a parsed/generated recipe (_toEntity), shape-tolerant. */
function parsedFields(input: Record<string, unknown>) {
  const title = input.title;
  if (typeof title !== "string" || !title.trim()) throw new AiParseError("No title");
  const ingredients: Ingredient[] = [];
  for (const raw of Array.isArray(input.ingredients) ? input.ingredients : []) {
    if (!raw || typeof raw !== "object") continue;
    const o = raw as Record<string, unknown>;
    if (typeof o.name !== "string" || !o.name.trim()) continue;
    const unit = (MEASUREMENT_UNITS as readonly string[]).includes(o.unit as string) ? (o.unit as Ingredient["unit"]) : "unspecified";
    ingredients.push({ name: o.name.trim(), amount: typeof o.amount === "number" ? o.amount : null, unit });
  }
  const names = (v: unknown) => (Array.isArray(v) ? v.filter((x): x is string => typeof x === "string") : []);
  const allergens = names(input.allergens).filter((a): a is Allergen => (ALLERGENS as readonly string[]).includes(a));
  const tagSet = new Set(names(input.dietary_tags));
  let dietaryTags = DIETARY.filter((d) => tagSet.has(d)) as DietaryPreference[];
  if (allergens.length && !dietaryTags.includes("allergy")) dietaryTags = [...dietaryTags, "allergy"];
  return {
    title: title.trim(),
    prepTimeMinutes: typeof input.prep_time_minutes === "number" ? Math.trunc(input.prep_time_minutes) : null,
    cookTimeMinutes: typeof input.cook_time_minutes === "number" ? Math.trunc(input.cook_time_minutes) : null,
    ingredients,
    steps: names(input.steps),
    dietaryTags,
    allergens,
    mayContain: names(input.may_contain).filter((a): a is Allergen => (ALLERGENS as readonly string[]).includes(a)),
    servings: servingsFrom(input.servings),
    nutrition: nutritionFromModel(input.nutrition),
  };
}

/**
 * The deferred analysis of a template saved as raw text (details page
 * _analyzeNow): a recipe *request* is written, anything else is parsed. The
 * result keeps the recipe's id, photo and origin; the user's own topics,
 * allergens, servings and nutrition win where the model is silent.
 */
export async function analyzePending(r: Recipe): Promise<Recipe> {
  const raw = r.steps.join("\n");
  const data =
    r.sourceChannel === "aiRequest"
      ? await callStructured(body(`כתוב מתכון מלא לפי הבקשה הבאה:\n\n${raw}`, RECIPE_SCHEMA, GENERATE_SYSTEM_PROMPT), "generate")
      : await callStructured(body(`נתח את המתכון הבא לפורמט מובנה:\n\n${raw}`, RECIPE_SCHEMA), "text");
  const p = parsedFields(data);
  return {
    ...r,
    title: p.title,
    prepTimeMinutes: p.prepTimeMinutes,
    cookTimeMinutes: p.cookTimeMinutes,
    ingredients: p.ingredients,
    steps: p.steps,
    dietaryTags: p.dietaryTags.length ? p.dietaryTags : r.dietaryTags,
    allergens: p.allergens.length ? p.allergens : r.allergens,
    mayContain: p.mayContain.length ? p.mayContain : r.mayContain,
    servings: p.servings ?? r.servings,
    nutrition: p.nutrition ?? r.nutrition,
    pendingAnalysis: false,
  };
}

/** GenerateImageUseCase.recipePrompt: English, the title as written, up to eight ingredients. */
export function recipeImagePrompt(r: Pick<Recipe, "title" | "ingredients">): string {
  const ingredients = r.ingredients.slice(0, 8).map((i) => i.name).filter(Boolean).join(", ");
  return (
    `Appetizing food photograph of the dish "${r.title}"${ingredients ? `, made with ${ingredients}` : ""}. ` +
    "Plated and ready to eat, natural daylight, shallow depth of field, " +
    "top-down or 45-degree angle, clean background. No text, no people, no hands."
  );
}

/** One picture from the image model (generateImage), as a JPEG blob. */
export async function generateImage(prompt: string): Promise<Blob> {
  const data = await callRaw(
    { model: IMAGE_MODEL, input: prompt, response_format: { type: "image", aspect_ratio: "4:3", image_size: "1K", mime_type: "image/jpeg" } },
    "image",
  );
  for (const step of data.steps ?? []) {
    for (const block of step?.content ?? []) {
      if (block?.type === "image" && typeof block.data === "string") {
        const bin = atob(block.data);
        const bytes = new Uint8Array(bin.length);
        for (let i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i);
        if (bytes.length < 1024) throw new AiParseError("Image too small");
        return new Blob([bytes], { type: "image/jpeg" });
      }
    }
  }
  throw new AiParseError("No image returned");
}

type T = (key: string, vars?: Record<string, string | number>) => string;

/** A translated message for any failure of these calls (never raw error text). */
export function aiErrorMessage(t: T, err: unknown, fallbackKey: string): string {
  const q = quotaOf(err);
  if (q) return t("recipes.quota", { used: q.used, limit: q.limit });
  const refusal = refusalText(t, err);
  if (refusal) return refusal;
  if (err instanceof TypeError) return t("recipes.network");
  if (err instanceof ApiError && err.status === 401) return t("recipes.notConfigured");
  return t(fallbackKey);
}
