// Runs the model's function calls against the web's own stores — the port of
// AssistantDispatcher (lib/features/assistant/domain/assistant_dispatcher.dart).
// Same tool names, same argument handling and caps (titles ≤200, text ≤4000,
// lists ≤100), same refusal shapes ({ok:false, error, message}), same flag /
// Premium gates and the same daily AI allowance for imports. Every write goes
// through the store that already implements the app's save rule (stamping,
// whole-record writes, collab publishing for grocery lists and recipes).
import { ApiError } from "../../lib/api";
import { getRecord, listRecords, newId } from "../../lib/cloud";
import type { Access, Flag } from "../../lib/flags";
import { quotaOf } from "../../lib/functions";
import type { Lang } from "../../lib/i18n";
import { deleteRecipe as deleteRecipeRecord } from "../../lib/recipesStore";
import { canEditBook, newBook, normalizeBook, withRecipeAdded, type RecipeBook } from "../../models/book";
import {
  byCreatedAt,
  canEditList,
  checkedCount,
  DEFAULT_GROCERY_CATEGORY,
  groceryItemsForRecipe,
  newGroceryList,
  normalizeGroceryList,
  totalAmount,
  type GroceryItem,
  type GroceryList,
} from "../../models/groceryList";
import { canEditPlan, mealsForWeekday, newMealPlan, normalizeMealPlan, WEEKDAYS, type Meal, type MealItem, type MealPlan } from "../../models/mealPlan";
import { appLanguageOf, defaultPreferences, normalizePreferences, PREFERENCES_ID, updatePreferences, type Preferences } from "../../models/preferences";
import { canEditRecipe, DIETARY, MEASUREMENT_UNITS, normalizeRecipe, type DietaryPreference, type Ingredient, type MeasurementUnit, type Recipe } from "../../models/recipe";
import { readActiveList, saveList, writeActiveList } from "../groceries/store";
import { sendFeedback, type FeedbackType } from "../support/data";
import { generateRecipe, IngestError, parseFromSocialVideo, parseFromUrl, parseRawText, searchWeb } from "../ingest/ai";
import { isWebUrl } from "../ingest/channels";
import { createBook as createBookRecord, updateBook } from "../library/booksStore";
import { createPlan, updatePlan } from "../plans/plansStore";
import { estimateNutrition as estimateNutritionAi } from "../recipes/lib/ai";
import { persistRecipe } from "../recipes/lib/persist";
import * as cooking from "./cooking";
import { fail, ok, type ToolCall, type ToolResult } from "./models";
import { ParseError } from "./remote";
import type { AssistantScope } from "./scope";
import { SCREENS, T, type Screen } from "./tools";

/** What a tool needs from the account and the screen, read fresh for every call. */
export interface DispatcherEnv {
  uid: string;
  lang: Lang;
  premium: boolean;
  access: (flag: Flag) => Access;
  t: (key: string, vars?: Record<string, string | number>) => string;
  /** For contact_support: the same signature the support form sends. */
  authorName: string;
  authorEmail: string | null;
  phone: string | null;
}

/** The few things a tool needs from the page (AssistantUiBridge). Null once the page is gone. */
export interface UiBridge {
  confirmDelete(what: string): Promise<boolean>;
  allowAiExtraction(): Promise<boolean>;
  openRecipe(id: string): void;
  openCookMode(id: string): void;
  openScreen(screen: Screen): void;
}

// ---- Caps ------------------------------------------------------------------

export const MAX_TITLE_LENGTH = 200;
export const MAX_TEXT_LENGTH = 4000;
export const MAX_LIST_ITEMS = 100;
/** How many books or plans a listing tool hands the model. */
export const MAX_LISTED_ENTITIES = 100;
/** The largest multiplier create_grocery_list_from_recipe accepts. */
export const MAX_SCALE = 20;
/** How many lines of a grocery list go to the model (prompt and results). */
export const SCOPED_GROCERY_ITEM_CAP = 150;

function asString(raw: unknown): string {
  if (typeof raw === "string") return raw;
  if (raw === null || raw === undefined) return "";
  if (typeof raw === "object") {
    try {
      return JSON.stringify(raw);
    } catch {
      return "";
    }
  }
  return String(raw);
}

function capped(raw: unknown, max: number): string {
  const s = asString(raw).trim();
  return s.length <= max ? s : s.slice(0, max).trimEnd();
}

/** A short string — a title, a name, a key — trimmed and capped. */
const title = (raw: unknown) => capped(raw, MAX_TITLE_LENGTH);
/** A long string — a step, a message — trimmed and capped. */
const text = (raw: unknown) => capped(raw, MAX_TEXT_LENGTH);
/** A list argument, at most 100 long; anything else is empty. */
const list = (raw: unknown): unknown[] => (Array.isArray(raw) ? raw.slice(0, MAX_LIST_ITEMS) : []);
const strings = (raw: unknown): string[] => list(raw).map(text);

/** An integer as the model sent it: 4, 4.0 or "4". */
function int(raw: unknown): number | null {
  if (typeof raw === "number" && Number.isFinite(raw)) return Math.trunc(raw);
  if (typeof raw === "string" && /^[+-]?\d+$/.test(raw.trim())) return parseInt(raw.trim(), 10);
  return null;
}

const clamp = (n: number, lo: number, hi: number) => Math.min(hi, Math.max(lo, n));

function weekdayFrom(raw: unknown): number | null {
  if (typeof raw === "number" && Number.isFinite(raw)) return clamp(Math.trunc(raw), 0, 6);
  if (typeof raw === "string") {
    const i = (WEEKDAYS as readonly string[]).indexOf(raw.trim().toLowerCase());
    return i < 0 ? null : i;
  }
  return null;
}

const unitFrom = (raw: unknown): MeasurementUnit => ((MEASUREMENT_UNITS as readonly string[]).includes(raw as string) ? (raw as MeasurementUnit) : "unspecified");

function dietaryFrom(raw: unknown): DietaryPreference[] {
  const out: DietaryPreference[] = [];
  for (const n of list(raw)) if (typeof n === "string" && (DIETARY as readonly string[]).includes(n)) out.push(n as DietaryPreference);
  return out;
}

/** Ingredient-shaped entries of a list argument, nameless ones dropped. */
function ingredients(raw: unknown): Ingredient[] {
  const out: Ingredient[] = [];
  for (const m of list(raw)) {
    if (!m || typeof m !== "object" || Array.isArray(m)) continue;
    const r = m as Record<string, unknown>;
    const amount = typeof r.amount === "number" && Number.isFinite(r.amount) ? r.amount : null;
    const ing = { name: title(r.name), amount, unit: unitFrom(r.unit === undefined || r.unit === null ? null : asString(r.unit)) };
    if (ing.name) out.push(ing);
  }
  return out;
}

/** A failure as the model reads it: the first line, capped at 300. */
function brief(message: string): string {
  const line = message.trimStart().split("\n")[0].trimEnd();
  return line.length <= 300 ? line : `${line.slice(0, 299)}…`;
}

/** The app's AppErrorType names for a failure, so the model reads the same codes. */
function errorCode(err: unknown): string {
  if (quotaOf(err)) return "quotaExceeded";
  if (err instanceof ApiError) {
    if (err.status === 401 || err.status === 403) return "unauthorized";
    if ([429, 500, 502, 503, 504, 529].includes(err.status)) return "overloaded";
    return "serverError";
  }
  if (err instanceof ParseError) return "parsingFailed";
  if (err instanceof IngestError) return err.kind === "parsing" ? "parsingFailed" : err.kind === "network" ? "networkError" : err.kind;
  if (err instanceof TypeError) return "networkError";
  return "failed";
}

/** English names of the gated features, for the model's "not available" message. */
const FEATURE_LABEL: Partial<Record<Flag, string>> = {
  ff_books: "Recipe books",
  ff_meal_plans: "Meal plans",
  ff_grocery_lists: "Grocery lists",
  ff_grocery_from_recipe: "Grocery list from a recipe",
  ff_ingest_text: "Recipe from text",
  ff_ingest_link: "Recipe from a link",
  ff_ingest_social_video: "Recipe from a video",
  ff_ingest_ai_request: "Recipe from a request",
  ff_ingest_web_search: "Web recipe search",
  ff_cook_mode: "Cook mode",
  ff_cook_timers: "Cook timers",
  ff_nutrition: "Nutrition",
};

const sameName = (a: string, b: string) => a.toLowerCase() === b.toLowerCase();
const newestFirst = <X extends { createdAt: string }>(a: X, b: X) => (a.createdAt < b.createdAt ? 1 : a.createdAt > b.createdAt ? -1 : 0);

// One write at a time per record: a card's tick and a tool's write never
// start from the same version (the bloc's sequential toggles).
const queues = new Map<string, Promise<unknown>>();
function serial<X>(key: string, run: () => Promise<X>): Promise<X> {
  const before = queues.get(key) ?? Promise.resolve();
  const next = before.catch(() => undefined).then(run);
  const tail = next.catch(() => undefined);
  queues.set(key, tail);
  void tail.then(() => {
    if (queues.get(key) === tail) queues.delete(key);
  });
  return next;
}

export class AssistantDispatcher {
  constructor(
    private readonly env: () => DispatcherEnv,
    private readonly ui: () => UiBridge | null,
  ) {}

  private get t() {
    return this.env().t;
  }

  async execute(call: ToolCall): Promise<ToolResult> {
    try {
      return await this.run(call.name, call.arguments ?? {});
    } catch (e) {
      return fail(errorCode(e), brief(e instanceof Error ? e.message : String(e)));
    }
  }

  private run(name: string, a: Record<string, unknown>): Promise<ToolResult> {
    switch (name) {
      case T.searchRecipes: return this.searchRecipes(a);
      case T.getRecipe: return this.getRecipe(a);
      case T.createRecipe: return this.createRecipe(a);
      case T.updateRecipe: return this.updateRecipe(a);
      case T.deleteRecipe: return this.deleteRecipe(a);
      case T.importRecipe: return this.importRecipe(a);
      case T.searchWebRecipes: return this.searchWebRecipes(a);
      case T.openRecipe: return this.openRecipe(a);
      case T.listBooks: return this.listBooks();
      case T.createBook: return this.createBook(a);
      case T.addRecipeToBook: return this.addRecipeToBook(a);
      case T.listMealPlans: return this.listMealPlans(a);
      case T.createMealPlan: return this.createMealPlan(a);
      case T.planMeal: return this.planMeal(a);
      case T.removePlannedItem: return this.removePlannedItem(a);
      case T.listGroceryLists: return this.listGroceryLists();
      case T.createGroceryList: return this.createGroceryList(a);
      case T.getGroceryList: return this.getGroceryList(a);
      case T.addGroceryItems: return this.addGroceryItems(a);
      case T.setGroceryItemChecked: return this.setGroceryItemChecked(a);
      case T.removeGroceryItems: return this.removeGroceryItems(a);
      case T.clearCheckedItems: return this.clearCheckedItems(a);
      case T.groceryListFromRecipe: return this.groceryListFromRecipe(a);
      case T.startCookMode: return this.startCookMode(a);
      case T.startTimer: return this.startTimer(a);
      case T.cookingStatus: return this.cookingStatus();
      case T.contactSupport: return this.contactSupport(a);
      case T.getPreferences: return this.getPreferences();
      case T.setShoppingDay: return this.setShoppingDay(a);
      case T.setDietaryPreferences: return this.setDietaryPreferences(a);
      case T.premiumStatus: return Promise.resolve(this.premiumStatus());
      case T.convertMeasurement: return Promise.resolve(convertMeasurement(a));
      case T.estimateNutrition: return this.estimateNutrition(a);
      case T.openScreen: return Promise.resolve(this.openScreen(a));
    }
    return Promise.resolve(fail("unknown_tool", `No tool named ${name}`));
  }

  // ---- Shared helpers ------------------------------------------------------

  /**
   * The gate the screen shows before the feature's own entry point: hidden or
   * "coming soon" is refused; Premium-only on a free account is refused with
   * the way to Premium (the app opens the paywall on top of the chat; the
   * web draws the card instead of leaving the conversation).
   */
  private gate(flag: Flag): ToolResult | null {
    const access = this.env().access(flag);
    if (access === "enabled") return null;
    if (access === "locked") return fail("premium_required", this.t("assistant.needsPremium"), { kind: "premium" });
    return fail("unavailable", `${FEATURE_LABEL[flag] ?? flag} is not available in this app right now`);
  }

  private async recipes(): Promise<Recipe[]> {
    return (await listRecords<unknown>("recipes")).map(normalizeRecipe).filter((r) => r.id);
  }

  private async recipeById(id: string): Promise<Recipe | null> {
    if (!id || id.includes("/")) return null;
    const raw = await getRecord<unknown>("recipes", id);
    return raw ? normalizeRecipe(raw) : null;
  }

  /** A recipe by id, or by the closest title when the model passed a name. */
  private async findRecipe(raw: unknown): Promise<Recipe | null> {
    if (typeof raw !== "string" || !raw.trim()) return null;
    const idOrTitle = title(raw);
    const byId = await this.recipeById(idOrTitle);
    if (byId) return byId;
    const needle = idOrTitle.toLowerCase();
    const all = await this.recipes();
    return all.find((r) => r.title.toLowerCase() === needle) ?? all.find((r) => r.title.toLowerCase().includes(needle)) ?? null;
  }

  private notFound(what: string, name: unknown): ToolResult {
    return fail("not_found", `${what} "${typeof name === "string" ? name : ""}" was not found`);
  }

  /** A recipe change: a shared recipe writes its shared document first, like the details page. */
  private saveRecipe(r: Recipe): Promise<Recipe> {
    const { lang, uid } = this.env();
    return persistRecipe(r, lang, uid);
  }

  private async preferences(): Promise<Preferences> {
    const raw = await getRecord<unknown>("preferences", PREFERENCES_ID);
    return raw ? normalizePreferences(raw) : defaultPreferences(appLanguageOf(this.env().lang));
  }

  private async dietaryPreferences(): Promise<DietaryPreference[]> {
    return (await this.preferences()).dietaryPreferences;
  }

  // ---- Recipes -------------------------------------------------------------

  private async searchRecipes(a: Record<string, unknown>): Promise<ToolResult> {
    const query = title(a.query).toLowerCase();
    const dietary = dietaryFrom(a.dietary);
    // A model's "limit: 0" is read as the default, not "nothing".
    const limit = clamp(int(a.limit) ?? 20, 1, 100);
    const hits = (await this.recipes()).filter((r) => {
      if (dietary.length && !dietary.every((d) => r.dietaryTags.includes(d))) return false;
      if (!query) return true;
      return r.title.toLowerCase().includes(query) || r.ingredients.some((i) => i.name.toLowerCase().includes(query));
    });
    const shown = hits.slice(0, limit);
    return ok(
      { count: hits.length, recipes: shown.map(recipeSummary) },
      shown.length ? { kind: "recipeList", title: this.t("assistant.results", { count: hits.length }), recipes: shown } : undefined,
    );
  }

  private async getRecipe(a: Record<string, unknown>): Promise<ToolResult> {
    const recipe = await this.findRecipe(a.recipe_id);
    if (!recipe) return this.notFound("Recipe", a.recipe_id);
    return ok(recipeFull(recipe), { kind: "recipe", recipe });
  }

  private async createRecipe(a: Record<string, unknown>): Promise<ToolResult> {
    const recipe: Recipe = {
      ...normalizeRecipe({ id: newId(), createdAt: new Date().toISOString(), sourceChannel: "manual" }),
      title: title(a.title),
      ingredients: ingredients(a.ingredients),
      steps: strings(a.steps).filter((s) => s.length > 0),
      servings: int(a.servings),
      prepTimeMinutes: int(a.prep_minutes),
      cookTimeMinutes: int(a.cook_minutes),
      dietaryTags: dietaryFrom(a.dietary_tags),
    };
    if (!recipe.title) return fail("invalid", "A title is required");
    const saved = await this.saveRecipe(recipe);
    return ok(recipeSummary(saved), { kind: "recipe", recipe: saved, caption: this.t("assistant.recipeSaved") });
  }

  private async updateRecipe(a: Record<string, unknown>): Promise<ToolResult> {
    const recipe = await this.findRecipe(a.recipe_id);
    if (!recipe) return this.notFound("Recipe", a.recipe_id);
    if (!canEditRecipe(recipe)) return fail("read_only", "This recipe is view-only");
    const remove = new Set(strings(a.remove_ingredient_names).map((s) => s.toLowerCase()));
    const nextIngredients = [...recipe.ingredients.filter((i) => !remove.has(i.name.toLowerCase())), ...ingredients(a.add_ingredients)];
    const steps = a.steps === undefined || a.steps === null ? null : strings(a.steps);
    // A blank title is "no change", not a recipe with no name.
    const newTitle = title(a.title);
    const updated: Recipe = {
      ...recipe,
      title: newTitle || recipe.title,
      servings: int(a.servings) ?? recipe.servings,
      prepTimeMinutes: int(a.prep_minutes) ?? recipe.prepTimeMinutes,
      cookTimeMinutes: int(a.cook_minutes) ?? recipe.cookTimeMinutes,
      ingredients: nextIngredients,
      steps: steps ?? recipe.steps,
    };
    const saved = await this.saveRecipe(updated);
    return ok(recipeFull(saved), { kind: "recipe", recipe: saved });
  }

  private async deleteRecipe(a: Record<string, unknown>): Promise<ToolResult> {
    const recipe = await this.findRecipe(a.recipe_id);
    if (!recipe) return this.notFound("Recipe", a.recipe_id);
    const ui = this.ui();
    if (!ui || !(await ui.confirmDelete(recipe.title))) return fail("cancelled", "The user did not confirm");
    await deleteRecipeRecord(recipe);
    return ok({ deleted: recipe.id }, { kind: "status", text: this.t("assistant.done"), icon: "delete" });
  }

  private async importRecipe(a: Record<string, unknown>): Promise<ToolResult> {
    const source = typeof a.source === "string" ? a.source : "text";
    const content = (typeof a.content === "string" ? a.content : "").trim();
    if (!content) return fail("invalid", "Nothing to import");
    // Cut, a pasted recipe would silently lose its last steps: refused instead.
    if (content.length > MAX_TEXT_LENGTH) return fail("invalid", `content is longer than ${MAX_TEXT_LENGTH} characters`);
    const link = source === "url" || source === "social_video";
    // The same four switches as the add screen's channels.
    const gate = this.gate(source === "url" ? "ff_ingest_link" : source === "social_video" ? "ff_ingest_social_video" : source === "request" ? "ff_ingest_ai_request" : "ff_ingest_text");
    if (gate) return gate;
    // Only an http(s) address reaches the fetch — checked before the allowance is spent.
    if (link && !isWebUrl(content)) return fail("invalid", "content must be an http(s) link");
    const prefs = await this.dietaryPreferences();
    // Every source is a model call and costs one extraction from the daily allowance.
    const ui = this.ui();
    if (!ui || !(await ui.allowAiExtraction())) return fail("quota", this.t("assistant.aiQuotaReached"));
    const parsed =
      source === "url"
        ? await parseFromUrl(content)
        : source === "social_video"
          ? await parseFromSocialVideo(content, prefs)
          : source === "request"
            ? await generateRecipe(content, prefs)
            : await parseRawText(content);
    const saved = await this.saveRecipe(parsed);
    return ok(recipeFull(saved), { kind: "recipe", recipe: saved, caption: this.t("assistant.recipeSaved") });
  }

  private async searchWebRecipes(a: Record<string, unknown>): Promise<ToolResult> {
    const gate = this.gate("ff_ingest_web_search");
    if (gate) return gate;
    const query = title(a.query);
    if (!query) return fail("invalid", "query is required");
    // Model output: only http(s) addresses reach the card's links and the model's next turn.
    // Capped too: the results ride in the conversation for every later turn.
    const results = (await searchWeb(query, await this.dietaryPreferences()))
      .filter((r) => isWebUrl(r.url) && r.url.length <= 2048)
      .slice(0, 10)
      .map((r) => ({ title: title(r.title), url: r.url.trim(), snippet: capped(r.snippet, 500) }));
    return ok(
      { results: results.map((r) => ({ title: r.title, url: r.url, snippet: r.snippet })) },
      results.length ? { kind: "web", results } : undefined,
    );
  }

  private async openRecipe(a: Record<string, unknown>): Promise<ToolResult> {
    const recipe = await this.findRecipe(a.recipe_id);
    if (!recipe) return this.notFound("Recipe", a.recipe_id);
    this.ui()?.openRecipe(recipe.id);
    return ok({ opened: recipe.id });
  }

  // ---- Books ---------------------------------------------------------------

  private async books(): Promise<RecipeBook[]> {
    return (await listRecords<unknown>("books")).map(normalizeBook).filter((b) => b.id).sort((x, y) => x.createdAt.localeCompare(y.createdAt));
  }

  private async listBooks(): Promise<ToolResult> {
    const all = await this.books();
    const data: Record<string, unknown> = {
      books: all.slice(0, MAX_LISTED_ENTITIES).map((b) => ({ id: b.id, title: b.title, recipe_count: b.recipeRefs.length })),
    };
    if (all.length > MAX_LISTED_ENTITIES) data.more_books_not_listed = all.length - MAX_LISTED_ENTITIES;
    return ok(data, { kind: "lines", title: this.t("assistant.nav.library"), lines: all.map((b) => `${b.title} · ${b.recipeRefs.length}`) });
  }

  private async createBook(a: Record<string, unknown>): Promise<ToolResult> {
    const gate = this.gate("ff_books");
    if (gate) return gate;
    const name = title(a.title);
    if (!name) return fail("invalid", "A title is required");
    const book = await createBookRecord(newBook(newId(), name), this.env().lang);
    return ok({ id: book.id, title: name }, { kind: "status", text: name, icon: "book", to: `/library/${encodeURIComponent(book.id)}` });
  }

  private async addRecipeToBook(a: Record<string, unknown>): Promise<ToolResult> {
    const gate = this.gate("ff_books");
    if (gate) return gate;
    const recipe = await this.findRecipe(a.recipe_id);
    if (!recipe) return this.notFound("Recipe", a.recipe_id);
    const bookId = title(a.book_id);
    const all = await this.books();
    const book = all.find((b) => b.id === bookId) ?? all.find((b) => sameName(b.title, bookId)) ?? null;
    if (!book) return this.notFound("Book", bookId);
    if (!canEditBook(book)) return fail("read_only", "This book is view-only");
    if (book.recipeRefs.some((r) => r.recipeId === recipe.id)) return ok({ already_in_book: true, book: book.title });
    const saved = await updateBook(book.id, (b) => withRecipeAdded(b, recipe.id), this.env().lang);
    if (!saved) {
      const now = await getRecord<unknown>("books", book.id);
      if (now && normalizeBook(now).recipeRefs.some((r) => r.recipeId === recipe.id)) return ok({ already_in_book: true, book: book.title });
      return this.notFound("Book", bookId);
    }
    return ok({ book: book.title, recipe: recipe.title }, { kind: "status", text: `${recipe.title} → ${book.title}`, icon: "book", to: `/library/${encodeURIComponent(book.id)}` });
  }

  // ---- Meal plans ----------------------------------------------------------

  private dayLabel(weekday: number): string {
    return this.t(`assistant.weekday.${WEEKDAYS[weekday]}`);
  }

  /** A meal name the model may pass as a key ("dinner") or as the label the user sees. */
  private mealLabel(raw: string): string {
    const key = raw.trim();
    const keys = ["breakfast", "lunch", "dinner", "morningSnack", "afternoonSnack", "eveningSnack"];
    return keys.includes(key) ? this.t(`assistant.meal.${key}`) : key;
  }

  private templateMeals(template: "free" | "threeMeals" | "sixMeals"): string[] {
    const m = (k: string) => this.t(`assistant.meal.${k}`);
    if (template === "free") return [];
    if (template === "threeMeals") return [m("breakfast"), m("lunch"), m("dinner")];
    return [m("breakfast"), m("morningSnack"), m("lunch"), m("afternoonSnack"), m("dinner"), m("eveningSnack")];
  }

  private async plans(): Promise<MealPlan[]> {
    return (await listRecords<unknown>("meal_plans")).map(normalizeMealPlan).filter((p) => p.id).sort((x, y) => x.createdAt.localeCompare(y.createdAt));
  }

  private planJson(plan: MealPlan, index: Map<string, Recipe>): Record<string, unknown> {
    return {
      id: plan.id,
      name: plan.name,
      days: WEEKDAYS.map((weekday, d) => ({
        weekday,
        meals: mealsForWeekday(plan, d).map((m) => ({
          meal_id: m.id,
          name: m.name,
          items: m.items.map((i) => ({
            item_id: i.id,
            recipe_id: i.recipeId,
            title: i.recipeId !== null ? index.get(i.recipeId)?.title ?? null : i.freeText,
          })),
        })),
      })),
    };
  }

  private async listMealPlans(a: Record<string, unknown>): Promise<ToolResult> {
    const all = await this.plans();
    const wanted = a.plan_id === undefined || a.plan_id === null ? null : title(a.plan_id);
    const matching = wanted === null ? all : all.filter((p) => p.id === wanted || p.name === wanted);
    // Capped: each plan carries its whole week, and the result stays in the conversation.
    const chosen = matching.slice(0, MAX_LISTED_ENTITIES);
    const index = new Map((await this.recipes()).map((r) => [r.id, r]));
    const lines: string[] = [];
    for (const p of chosen) {
      for (let d = 0; d < 7; d++) {
        for (const m of mealsForWeekday(p, d)) {
          if (!m.items.length) continue;
          const titles = m.items
            .map((i) => (i.recipeId !== null ? index.get(i.recipeId)?.title : i.freeText))
            .filter((x): x is string => typeof x === "string")
            .join(", ");
          lines.push(`${this.dayLabel(d)} · ${m.name}: ${titles}`);
        }
      }
    }
    const data: Record<string, unknown> = { plans: chosen.map((p) => this.planJson(p, index)) };
    if (matching.length > chosen.length) data.more_plans_not_listed = matching.length - chosen.length;
    return ok(data, lines.length ? { kind: "lines", title: this.t("assistant.nav.mealPlan"), lines } : undefined);
  }

  private async newPlan(name: string, template: "free" | "threeMeals" | "sixMeals"): Promise<MealPlan> {
    return createPlan(newMealPlan(newId(), name, this.templateMeals(template), newId), this.env().lang);
  }

  private async createMealPlan(a: Record<string, unknown>): Promise<ToolResult> {
    const gate = this.gate("ff_meal_plans");
    if (gate) return gate;
    const name = title(a.name);
    if (!name) return fail("invalid", "A name is required");
    const template = a.template === "free" || a.template === "sixMeals" || a.template === "threeMeals" ? a.template : "threeMeals";
    const plan = await this.newPlan(name, template);
    return ok({ id: plan.id, name: plan.name }, { kind: "status", text: plan.name, icon: "calendar", to: `/plans/${encodeURIComponent(plan.id)}` });
  }

  private planReadOnly(): ToolResult {
    return fail("read_only", "This meal plan is view-only");
  }

  private async planMeal(a: Record<string, unknown>): Promise<ToolResult> {
    const gate = this.gate("ff_meal_plans");
    if (gate) return gate;
    const weekday = weekdayFrom(a.weekday);
    const mealName = this.mealLabel(title(a.meal));
    if (weekday === null || !mealName) return fail("invalid", "weekday and meal are required");
    let recipe: Recipe | null = null;
    const freeText = a.free_text === undefined || a.free_text === null ? null : title(a.free_text);
    if (a.recipe_id !== undefined && a.recipe_id !== null) {
      recipe = await this.findRecipe(a.recipe_id);
      if (!recipe) return this.notFound("Recipe", a.recipe_id);
    } else if (!freeText) {
      return fail("invalid", "recipe_id or free_text is required");
    }

    const all = await this.plans();
    let plan: MealPlan | null;
    const wanted = a.plan_id === undefined || a.plan_id === null ? null : title(a.plan_id);
    if (wanted !== null) {
      plan = all.find((p) => p.id === wanted || p.name === wanted) ?? null;
      if (!plan) return this.notFound("Plan", wanted);
      if (!canEditPlan(plan)) return this.planReadOnly();
    } else if (all.some(canEditPlan)) {
      // The newest plan this account may write: a plan it only views is never picked for it.
      plan = all.filter(canEditPlan).sort(newestFirst)[0];
    } else {
      plan = await this.newPlan(this.t("assistant.meal.newPlan"), "threeMeals");
    }

    const item: MealItem = { id: newId(), recipeId: recipe?.id ?? null, freeText: recipe ? null : freeText, ingredients: [] };
    const placed: { meal: Meal | null } = { meal: null };
    const saved = await updatePlan(
      plan.id,
      (p) => {
        const meals = [...p.meals];
        let meal = mealsForWeekday(p, weekday).find((m) => sameName(m.name, mealName)) ?? null;
        if (!meal) {
          meal = { id: newId(), weekday, name: mealName, order: mealsForWeekday(p, weekday).length, items: [] };
          meals.push(meal);
        }
        const updated: Meal = { ...meal, items: [...meal.items, item] };
        const at = meals.findIndex((m) => m.id === updated.id);
        meals[at] = updated;
        placed.meal = updated;
        return { ...p, meals };
      },
      this.env().lang,
    );
    if (!saved || !placed.meal) return this.notFound("Plan", wanted ?? plan.id);
    const dishTitle = recipe?.title ?? freeText ?? "";
    return ok(
      { plan_id: saved.id, meal_id: placed.meal.id, item_id: item.id, weekday: WEEKDAYS[weekday], meal: placed.meal.name, title: dishTitle },
      { kind: "planned", planId: saved.id, planName: saved.name, dayLabel: this.dayLabel(weekday), mealName: placed.meal.name, title: dishTitle, recipe },
    );
  }

  private async removePlannedItem(a: Record<string, unknown>): Promise<ToolResult> {
    const gate = this.gate("ff_meal_plans");
    if (gate) return gate;
    const planId = title(a.plan_id);
    const raw = planId && !planId.includes("/") ? await getRecord<unknown>("meal_plans", planId) : null;
    const plan = raw ? normalizeMealPlan(raw) : null;
    if (!plan) return this.notFound("Plan", a.plan_id);
    if (!canEditPlan(plan)) return this.planReadOnly();
    const mealId = typeof a.meal_id === "string" ? a.meal_id : null;
    const itemId = typeof a.item_id === "string" ? a.item_id : null;
    let removed = false;
    const saved = await updatePlan(
      plan.id,
      (p) => {
        removed = false;
        const meals = p.meals.map((m) => {
          if (m.id !== mealId) return m;
          const items = m.items.filter((i) => i.id !== itemId);
          if (items.length !== m.items.length) removed = true;
          return { ...m, items };
        });
        return removed ? { ...p, meals } : null;
      },
      this.env().lang,
    );
    if (!removed || !saved) return this.notFound("Planned item", itemId);
    return ok({ removed: itemId }, { kind: "status", text: this.t("assistant.done"), icon: "delete" });
  }

  // ---- Groceries -----------------------------------------------------------

  private listReadOnly(): ToolResult {
    return fail("read_only", "This grocery list is view-only");
  }

  private async lists(): Promise<GroceryList[]> {
    return (await listRecords<unknown>("grocery_lists")).map(normalizeGroceryList).filter((l) => l.id).sort(byCreatedAt);
  }

  private async listById(id: string): Promise<GroceryList | null> {
    if (!id || id.includes("/")) return null;
    const raw = await getRecord<unknown>("grocery_lists", id);
    return raw ? normalizeGroceryList(raw) : null;
  }

  async activeGroceryList(): Promise<GroceryList | null> {
    const id = readActiveList(this.env().uid);
    if (id) {
      const l = await this.listById(id);
      if (l) return l;
    }
    const all = await this.lists();
    return all.length ? [...all].sort(newestFirst)[0] : null;
  }

  /** The list the model named (id, else name), or the active one. */
  private async groceryList(idOrName: unknown): Promise<GroceryList | null> {
    if (typeof idOrName !== "string" || !idOrName.trim()) return this.activeGroceryList();
    const byId = await this.listById(idOrName);
    if (byId) return byId;
    const needle = idOrName.trim().toLowerCase();
    return (await this.lists()).find((l) => l.name.toLowerCase() === needle) ?? null;
  }

  /** "Grocery list", then "Grocery list 2", "Grocery list 3": two lists never share a name. */
  private async uniqueListName(wanted: string): Promise<string> {
    const base = wanted.trim();
    const taken = new Set((await this.lists()).map((l) => l.name.toLowerCase()));
    if (!taken.has(base.toLowerCase())) return base;
    for (let n = 2; ; n++) if (!taken.has(`${base} ${n}`.toLowerCase())) return `${base} ${n}`;
  }

  private listSummary(l: GroceryList, activeId: string | null): Record<string, unknown> {
    return { id: l.id, name: l.name, item_count: l.items.length, bought: checkedCount(l), active: l.id === activeId };
  }

  private listLines(all: GroceryList[], activeId: string | null): string[] {
    return all.map((l) => `${l.name} · ${l.items.length}${l.id === activeId ? " ✓" : ""}`);
  }

  /**
   * Applies `edit` to the list as stored right now, one write at a time per
   * list, and saves it through the groceries store (stamp + shared copy).
   * Resolves the saved list, or null when it is gone / not editable / unchanged.
   */
  private mutateList(id: string, edit: (l: GroceryList) => GroceryList | null): Promise<GroceryList | null> {
    return serial(`grocery_lists/${id}`, async () => {
      const current = await this.listById(id);
      if (!current || !canEditList(current)) return null;
      const next = edit(current);
      if (!next) return null;
      return saveList(next, current, this.env().lang);
    });
  }

  private groceryResult(l: GroceryList, extra: Record<string, unknown> = {}): ToolResult {
    // The model's copy is capped (still-to-buy lines first); the card keeps the whole list.
    const ordered = [...l.items.filter((i) => !i.isChecked), ...l.items.filter((i) => i.isChecked)];
    const shown = ordered.slice(0, SCOPED_GROCERY_ITEM_CAP);
    const more = l.items.length - shown.length;
    const data: Record<string, unknown> = { list_id: l.id, list_name: l.name, items: shown.map(itemJson) };
    if (more > 0) {
      data.total_items = l.items.length;
      data.more_items_not_listed = more;
    }
    return ok({ ...data, ...extra }, { kind: "grocery", listId: l.id, listName: l.name, items: l.items });
  }

  private async listGroceryLists(): Promise<ToolResult> {
    const all = await this.lists();
    const activeId = readActiveList(this.env().uid);
    return ok(
      { lists: all.map((l) => this.listSummary(l, activeId)) },
      all.length ? { kind: "lines", title: this.t("assistant.nav.groceries"), lines: this.listLines(all, activeId) } : undefined,
    );
  }

  private async createGroceryList(a: Record<string, unknown>): Promise<ToolResult> {
    const gate = this.gate("ff_grocery_lists");
    if (gate) return gate;
    const wanted = title(a.name);
    if (!wanted) return fail("invalid", "A name is required");
    const created = newGroceryList(newId(), await this.uniqueListName(wanted), "manual");
    const saved = await saveList(created, null, this.env().lang);
    writeActiveList(this.env().uid, saved.id);
    return ok(
      { list_id: saved.id, name: saved.name },
      { kind: "status", text: `${this.t("assistant.listCreated")}: ${saved.name}`, icon: "check", to: `/groceries/${encodeURIComponent(saved.id)}` },
    );
  }

  private async getGroceryList(a: Record<string, unknown>): Promise<ToolResult> {
    const l = await this.groceryList(a.list_id);
    if (!l) return ok({ list_id: null, items: [] });
    return this.groceryResult(l);
  }

  private async addGroceryItems(a: Record<string, unknown>): Promise<ToolResult> {
    const gate = this.gate("ff_grocery_lists");
    if (gate) return gate;
    const wanted = ingredients(a.items);
    if (!wanted.length) return fail("invalid", "No items given");

    const listId = a.list_id === undefined || a.list_id === null ? null : title(a.list_id);
    const all = await this.lists();
    let target: GroceryList | null;
    if (listId !== null && listId.trim()) {
      target = await this.groceryList(listId);
      if (!target) return this.notFound("Grocery list", listId);
    } else if (all.length > 1) {
      // Several lists and no choice: the model asks, it does not guess.
      const activeId = readActiveList(this.env().uid);
      return {
        data: { ok: false, error: "ambiguous_list", message: this.t("assistant.whichList"), lists: all.map((l) => this.listSummary(l, activeId)) },
        card: { kind: "lines", title: this.t("assistant.whichList"), lines: this.listLines(all, activeId) },
      };
    } else {
      target = all[0] ?? null;
    }
    if (target && !canEditList(target)) return this.listReadOnly();

    const merge = (items: GroceryItem[]): GroceryItem[] => {
      const out = [...items];
      for (const w of wanted) {
        const amount = w.amount ?? 1;
        const at = out.findIndex((i) => sameName(i.name, w.name) && i.unit === w.unit);
        if (at >= 0) {
          const existing = out[at];
          out[at] = { ...existing, isChecked: false, sources: [...existing.sources, { recipeId: null, label: w.name, amount }] };
        } else {
          out.push({ id: newId(), name: w.name, unit: w.unit, sources: [{ recipeId: null, label: w.name, amount }], isChecked: false, category: DEFAULT_GROCERY_CATEGORY, isAdHoc: true });
        }
      }
      return out;
    };

    let saved: GroceryList | null;
    if (!target) {
      const created = { ...newGroceryList(newId(), await this.uniqueListName(this.t("assistant.listTitle")), "manual") };
      saved = await saveList({ ...created, items: merge([]) }, null, this.env().lang);
      writeActiveList(this.env().uid, saved.id);
    } else {
      saved = await this.mutateList(target.id, (l) => ({ ...l, items: merge(l.items) }));
      if (!saved) return this.listReadOnly();
    }
    return this.groceryResult(saved, { added: wanted.length });
  }

  /** Items by id or by name (exact, then contains), in the order asked. */
  private matchItems(l: GroceryList, keys: string[]): GroceryItem[] {
    const found: GroceryItem[] = [];
    for (const key of keys) {
      const k = key.trim().toLowerCase();
      const hit = l.items.find((i) => i.id === key) ?? l.items.find((i) => i.name.toLowerCase() === k) ?? l.items.find((i) => i.name.toLowerCase().includes(k));
      if (hit && !found.includes(hit)) found.push(hit);
    }
    return found;
  }

  private async setGroceryItemChecked(a: Record<string, unknown>): Promise<ToolResult> {
    const gate = this.gate("ff_grocery_lists");
    if (gate) return gate;
    const l = await this.groceryList(a.list_id);
    if (!l) return this.notFound("Grocery list", null);
    if (!canEditList(l)) return this.listReadOnly();
    const checked = typeof a.checked === "boolean" ? a.checked : true;
    const keys = strings(a.items);
    const hits = new Set(this.matchItems(l, keys).map((i) => i.id));
    if (!hits.size) return this.notFound("Item", keys.join(", "));
    const saved = await this.mutateList(l.id, (cur) => ({ ...cur, items: cur.items.map((i) => (hits.has(i.id) ? { ...i, isChecked: checked } : i)) }));
    if (!saved) return this.listReadOnly();
    return this.groceryResult(saved, { changed: hits.size });
  }

  /**
   * The checklist card's own toggle, outside a model turn: sets the tick the
   * user asked for (the opposite of what the card showed), not a flip of the
   * stored one, which another device may have ticked meanwhile. Null when the
   * list is gone, view-only, or the item is no longer on it.
   */
  toggleGroceryItem(listId: string, itemId: string, checked: boolean): Promise<GroceryList | null> {
    return this.mutateList(listId, (l) => (l.items.some((i) => i.id === itemId) ? { ...l, items: l.items.map((i) => (i.id === itemId ? { ...i, isChecked: checked } : i)) } : null));
  }

  private async removeGroceryItems(a: Record<string, unknown>): Promise<ToolResult> {
    const gate = this.gate("ff_grocery_lists");
    if (gate) return gate;
    const l = await this.groceryList(a.list_id);
    if (!l) return this.notFound("Grocery list", null);
    if (!canEditList(l)) return this.listReadOnly();
    const keys = strings(a.items);
    const hits = new Set(this.matchItems(l, keys).map((i) => i.id));
    if (!hits.size) return this.notFound("Item", keys.join(", "));
    const saved = await this.mutateList(l.id, (cur) => ({ ...cur, items: cur.items.filter((i) => !hits.has(i.id)) }));
    if (!saved) return this.listReadOnly();
    return this.groceryResult(saved, { removed: hits.size });
  }

  private async clearCheckedItems(a: Record<string, unknown>): Promise<ToolResult> {
    const gate = this.gate("ff_grocery_lists");
    if (gate) return gate;
    const l = await this.groceryList(a.list_id);
    if (!l) return this.notFound("Grocery list", null);
    if (!canEditList(l)) return this.listReadOnly();
    let removed = 0;
    const saved = await this.mutateList(l.id, (cur) => {
      const kept = cur.items.filter((i) => !i.isChecked);
      removed = cur.items.length - kept.length;
      return { ...cur, items: kept };
    });
    if (!saved) return this.listReadOnly();
    return this.groceryResult(saved, { removed });
  }

  private async groceryListFromRecipe(a: Record<string, unknown>): Promise<ToolResult> {
    const gate = this.gate("ff_grocery_lists") ?? this.gate("ff_grocery_from_recipe");
    if (gate) return gate;
    const recipe = await this.findRecipe(a.recipe_id);
    if (!recipe) return this.notFound("Recipe", a.recipe_id);
    const raw = a.scale;
    const parsed = typeof raw === "number" ? raw : typeof raw === "string" && raw.trim() !== "" ? Number(raw) : NaN;
    const wanted = Number.isFinite(parsed) ? parsed : 1;
    // Bounded: a slip like 500 would fill the list with absurd amounts.
    const scale = wanted > 0 ? clamp(wanted, 0.1, MAX_SCALE) : 1;
    // CreateRecipeGroceryListUseCase: the recipe's lines, scaled; title and servings copied; made active.
    const name = await this.uniqueListName(recipe.title);
    const created: GroceryList = {
      ...newGroceryList(newId(), name.trim() ? name.trim() : recipe.title, "recipe"),
      items: groceryItemsForRecipe(recipe, scale),
      recipeId: recipe.id,
      recipeScale: scale,
      recipeServings: recipe.servings ?? null,
      recipeTitle: recipe.title,
    };
    const saved = await saveList(created, null, this.env().lang);
    writeActiveList(this.env().uid, saved.id);
    return this.groceryResult(saved);
  }

  // ---- Cooking -------------------------------------------------------------

  private async startCookMode(a: Record<string, unknown>): Promise<ToolResult> {
    const recipe = await this.findRecipe(a.recipe_id);
    if (!recipe) return this.notFound("Recipe", a.recipe_id);
    // Locked, hidden or "coming soon": the screen's verdict, so no session starts.
    const gate = this.gate("ff_cook_mode");
    if (gate) return gate;
    const step = int(a.step) ?? 1;
    cooking.startSession(recipe);
    const last = recipe.steps.length === 0 ? 0 : recipe.steps.length - 1;
    cooking.setStep(recipe.id, clamp(step - 1, 0, last));
    this.ui()?.openCookMode(recipe.id);
    return ok({ recipe_id: recipe.id, step }, { kind: "status", text: this.t("assistant.cookStarted"), icon: "flame", to: `/cook/${encodeURIComponent(recipe.id)}` });
  }

  private async startTimer(a: Record<string, unknown>): Promise<ToolResult> {
    const recipe = await this.findRecipe(a.recipe_id);
    if (!recipe) return this.notFound("Recipe", a.recipe_id);
    const gate = this.gate("ff_cook_mode") ?? this.gate("ff_cook_timers");
    if (gate) return gate;
    const step = (int(a.step) ?? 1) - 1;
    const session = cooking.startSession(recipe);
    if (!session.timers[step]) {
      const available = Object.keys(session.timers).map((k) => Number(k) + 1).join(", ");
      return fail("no_timer", `Step ${step + 1} names no duration; available: ${available}`);
    }
    const timer = cooking.startTimer(recipe.id, step);
    return ok(
      { recipe_id: recipe.id, step: step + 1, remaining: timer ? cooking.display(timer) : "" },
      { kind: "status", text: this.t("assistant.timerSet", { n: String(step + 1) }), icon: "timer", to: `/cook/${encodeURIComponent(recipe.id)}` },
    );
  }

  private async cookingStatus(): Promise<ToolResult> {
    const sessions = cooking.allSessions();
    const titles = sessions.length ? new Map((await this.recipes()).map((r) => [r.id, r.title])) : new Map<string, string>();
    return ok({
      cooking: sessions
        .filter((s) => titles.has(s.id))
        .map((s) => ({
          recipe_id: s.id,
          title: titles.get(s.id) ?? "",
          step: s.stepIndex + 1,
          of: s.steps.length,
          timers: cooking.activeTimers(s).map(([step, t]) => ({ step: step + 1, remaining: cooking.display(t), rung: t.finished })),
        })),
    });
  }

  // ---- Account -------------------------------------------------------------

  private prefsJson(p: Preferences): Record<string, unknown> {
    return { shopping_day: p.shoppingDay, dietary: [...p.dietaryPreferences], language: p.language };
  }

  private async getPreferences(): Promise<ToolResult> {
    return ok(this.prefsJson(await this.preferences()));
  }

  private async setShoppingDay(a: Record<string, unknown>): Promise<ToolResult> {
    const day = weekdayFrom(a.day);
    if (day === null) return fail("invalid", "Unknown day");
    await updatePreferences((p) => ({ ...p, shoppingDay: WEEKDAYS[day] }), appLanguageOf(this.env().lang));
    return ok({ shopping_day: WEEKDAYS[day] }, { kind: "status", text: this.t("assistant.prefSaved"), icon: "check" });
  }

  private async setDietaryPreferences(a: Record<string, unknown>): Promise<ToolResult> {
    const add = dietaryFrom(a.add);
    const remove = new Set(dietaryFrom(a.remove));
    const saved = await updatePreferences(
      (p) => ({ ...p, dietaryPreferences: [...new Set([...p.dietaryPreferences.filter((d) => !remove.has(d)), ...add])] }),
      appLanguageOf(this.env().lang),
    );
    return ok({ dietary: [...saved.dietaryPreferences] }, { kind: "status", text: this.t("assistant.prefSaved"), icon: "check" });
  }

  private premiumStatus(): ToolResult {
    const { premium, access } = this.env();
    return ok({ premium, cook_mode_locked: access("ff_cook_mode") === "locked", notifications_locked: access("ff_notifications") === "locked" });
  }

  /** Opens a support conversation as the support form would, marked as coming through Shefi. */
  private async contactSupport(a: Record<string, unknown>): Promise<ToolResult> {
    const message = text(a.message);
    if (!message) return fail("invalid", "message is required");
    const reasons = ["bug", "suggestion", "account", "billing", "sharing", "recipes", "other"];
    const reason = typeof a.reason === "string" && reasons.includes(a.reason) ? (a.reason as FeedbackType) : null;
    if (!reason) return fail("invalid", "reason is not one of the list");
    const env = this.env();
    if (!env.uid || env.access("ff_feedback") !== "enabled" || env.access("ff_support_chat") !== "enabled") {
      return fail("unavailable", "Support messages cannot be sent from here right now.");
    }
    // The same lines the support form signs with, for the admin only.
    const raw: Record<string, string | null> = {
      name: env.authorName,
      email: env.authorEmail,
      phone: env.phone,
      uid: env.uid,
      version: "web",
      device: "Web",
      language: env.lang,
    };
    const details: Record<string, string> = {};
    for (const [k, v] of Object.entries(raw)) if (v && v.trim()) details[k] = v.trim();
    const id = await sendFeedback({ type: reason, message, authorUid: env.uid, authorName: env.authorName, authorEmail: env.authorEmail, details, source: "shefi" });
    return ok({
      ticket_id: id,
      reason,
      note: "Sent. The team answers in the app: support screen → my conversations, and a notification when they do.",
    }, { kind: "status", text: this.t("assistant.done"), icon: "check", to: `/support/${encodeURIComponent(id)}` });
  }

  private openScreen(a: Record<string, unknown>): ToolResult {
    const screen = title(a.screen);
    if (!(SCREENS as readonly string[]).includes(screen)) return fail("invalid", `No screen named "${screen}"`);
    this.ui()?.openScreen(screen as Screen);
    return ok({ opened: screen });
  }

  private async estimateNutrition(a: Record<string, unknown>): Promise<ToolResult> {
    const gate = this.gate("ff_nutrition");
    if (gate) return gate;
    const recipe = await this.findRecipe(a.recipe_id);
    if (!recipe) return this.notFound("Recipe", a.recipe_id);
    if (!canEditRecipe(recipe)) return fail("read_only", "This recipe is view-only");
    const estimated = await estimateNutritionAi(recipe);
    // The model took seconds: the estimate goes onto the recipe as stored now, not the copy read before.
    const fresh = await this.recipeById(recipe.id);
    if (!fresh) return this.notFound("Recipe", a.recipe_id);
    if (!canEditRecipe(fresh)) return fail("read_only", "This recipe is view-only");
    const saved = await this.saveRecipe({ ...fresh, servings: fresh.servings ?? estimated.servings, nutrition: estimated.nutrition });
    return ok(recipeFull(saved), { kind: "recipe", recipe: saved });
  }

  // ---- Context for the system prompt ---------------------------------------

  /** Everything about one item, for a conversation locked to it. Null when the item is gone. */
  async describe(scope: AssistantScope): Promise<string | null> {
    if (scope.kind === "recipe") {
      const r = await this.recipeById(scope.id);
      if (!r) return null;
      const lines = [
        `Recipe "${r.title}" (id ${r.id}).`,
        `Servings: ${r.servings ?? "?"}; prep ${r.prepTimeMinutes ?? "?"} min; cook ${r.cookTimeMinutes ?? "?"} min; tags: ${r.dietaryTags.join(", ")}; allergens: ${r.allergens.join(", ")}.`,
        "Ingredients:",
        ...r.ingredients.map((i) => `- ${i.name}${i.amount === null ? "" : `: ${i.amount} ${i.unit}`}`),
        "Steps:",
        ...r.steps.map((s, i) => `${i + 1}. ${s}`),
      ];
      if (r.nutrition) {
        const n = r.nutrition;
        lines.push(`Nutrition per serving (estimate): ${n.calories} kcal, protein ${n.proteinGrams} g, carbs ${n.carbsGrams} g, fat ${n.fatGrams} g.`);
      }
      return `${lines.join("\n")}\n`;
    }
    if (scope.kind === "mealPlan") {
      const raw = scope.id && !scope.id.includes("/") ? await getRecord<unknown>("meal_plans", scope.id) : null;
      if (!raw) return null;
      const p = normalizeMealPlan(raw);
      const titles = new Map((await this.recipes()).map((r) => [r.id, r.title]));
      const lines = [`Meal plan "${p.name}" (id ${p.id}).`];
      for (let day = 0; day < 7; day++) {
        const meals = mealsForWeekday(p, day);
        if (!meals.length) continue;
        lines.push(`${WEEKDAYS[day]}:`);
        for (const m of meals) {
          const items = m.items.map((i) => (i.recipeId !== null ? `${titles.get(i.recipeId) ?? "recipe"} (recipe_id ${i.recipeId})` : i.freeText ?? "")).join(", ");
          lines.push(`- ${m.name} (meal_id ${m.id}): ${items || "empty"}`);
        }
      }
      return `${lines.join("\n")}\n`;
    }
    const l = await this.listById(scope.id);
    if (!l) return null;
    const lines = [`Grocery list "${l.name}" (list_id ${l.id}): ${l.items.length} items, ${checkedCount(l)} bought.`];
    // Capped: a 600-line list would otherwise ride along on every turn. Still-to-buy first.
    const unchecked = l.items.filter((i) => !i.isChecked);
    const checked = l.items.filter((i) => i.isChecked);
    const shown = [...unchecked, ...checked].slice(0, SCOPED_GROCERY_ITEM_CAP);
    for (const i of shown) {
      const amount = totalAmount(i);
      lines.push(`- ${i.isChecked ? "[x]" : "[ ]"} ${i.name} (item_id ${i.id})${amount > 0 ? `: ${amount} ${i.unit}` : ""}`);
    }
    const rest = l.items.length - shown.length;
    if (rest > 0) {
      const restUnchecked = unchecked.length - shown.filter((i) => !i.isChecked).length;
      lines.push(`...and ${rest} more items not listed here (${restUnchecked} still to buy, ${rest - restUnchecked} bought); call get_grocery_list to read them.`);
    }
    return `${lines.join("\n")}\n`;
  }

  /** The date, the preferences, the recipes by id, the active list and what is cooking. */
  async snapshot(): Promise<string> {
    const [prefs, all, active] = await Promise.all([this.preferences(), this.recipes(), this.activeGroceryList()]);
    const now = new Date();
    const two = (n: number) => String(n).padStart(2, "0");
    const today = `${now.getFullYear()}-${two(now.getMonth() + 1)}-${two(now.getDate())}`;
    const lines = [
      `Today: ${today} (${WEEKDAYS[now.getDay()]}).`,
      `User language: ${prefs.language}; shopping day: ${prefs.shoppingDay}; dietary: ${prefs.dietaryPreferences.join(", ")}.`,
      `Premium: ${this.env().premium}.`,
      "Saved recipes (id: title), most recent first:",
      ...[...all].sort(newestFirst).slice(0, 40).map((r) => `- ${r.id}: ${r.title}`),
    ];
    if (active) {
      lines.push(`Active grocery list "${active.name}" (${active.items.length} items, ${checkedCount(active)} bought): ${active.items.slice(0, 30).map((i) => i.name).join(", ")}`);
    } else {
      lines.push("No grocery list yet.");
    }
    const sessions = cooking.allSessions();
    if (sessions.length) {
      const titles = new Map(all.map((r) => [r.id, r.title]));
      const cookingNow = sessions.filter((s) => titles.has(s.id)).map((s) => `${titles.get(s.id)} (step ${s.stepIndex + 1})`);
      if (cookingNow.length) lines.push(`Cooking now: ${cookingNow.join("; ")}`);
    }
    return `${lines.join("\n")}\n`;
  }
}

// ---- Pure helpers ------------------------------------------------------------

function recipeSummary(r: Recipe): Record<string, unknown> {
  return {
    id: r.id,
    title: r.title,
    servings: r.servings,
    prep_minutes: r.prepTimeMinutes,
    cook_minutes: r.cookTimeMinutes,
    dietary_tags: [...r.dietaryTags],
    ingredient_count: r.ingredients.length,
    step_count: r.steps.length,
  };
}

function recipeFull(r: Recipe): Record<string, unknown> {
  const out: Record<string, unknown> = {
    ...recipeSummary(r),
    ingredients: r.ingredients.map((i) => ({ name: i.name, amount: i.amount, unit: i.unit })),
    steps: [...r.steps],
  };
  if (r.nutrition) {
    out.nutrition_per_serving = { calories: r.nutrition.calories, protein_g: r.nutrition.proteinGrams, carbs_g: r.nutrition.carbsGrams, fat_g: r.nutrition.fatGrams };
  }
  out.allergens = [...r.allergens];
  return out;
}

function itemJson(i: GroceryItem): Record<string, unknown> {
  return { id: i.id, name: i.name, amount: totalAmount(i), unit: i.unit, bought: i.isChecked, category: i.category };
}

const TO_ML: Record<string, number> = { milliliter: 1, ml: 1, liter: 1000, l: 1000, teaspoon: 5, tsp: 5, tablespoon: 15, tbsp: 15, cup: 240 };
const TO_G: Record<string, number> = { gram: 1, g: 1, kilogram: 1000, kg: 1000 };
/** Grams per millilitre for the pantry staples people convert most (map order matters). */
const DENSITY: [string, number][] = [
  ["water", 1],
  ["milk", 1.03],
  ["flour", 0.53],
  ["sugar", 0.85],
  ["brown sugar", 0.8],
  ["butter", 0.96],
  ["oil", 0.92],
  ["olive oil", 0.92],
  ["honey", 1.42],
  ["rice", 0.78],
  ["salt", 1.2],
  ["cocoa", 0.5],
  ["oats", 0.4],
];

const has = (o: object, k: string) => Object.prototype.hasOwnProperty.call(o, k);

/** Dart's double.toString for the card: 2 → "2.0". */
const dartDouble = (n: number) => (Number.isInteger(n) ? `${n}.0` : String(n));

export function convertMeasurement(a: Record<string, unknown>): ToolResult {
  const amount = typeof a.amount === "number" && Number.isFinite(a.amount) ? a.amount : null;
  const from = title(a.from).toLowerCase();
  const to = title(a.to).toLowerCase();
  if (amount === null || !from || !to) return fail("invalid", "amount, from and to are required");
  let result: number | null = null;
  if ((from === "celsius" || from === "c") && (to === "fahrenheit" || to === "f")) {
    result = (amount * 9) / 5 + 32;
  } else if ((from === "fahrenheit" || from === "f") && (to === "celsius" || to === "c")) {
    result = ((amount - 32) * 5) / 9;
  } else {
    const ingredient = title(a.ingredient).toLowerCase();
    const density = DENSITY.find(([k]) => ingredient.includes(k))?.[1] ?? 1;
    // Everything goes through millilitres; weight crosses over by density.
    let ml: number | null = null;
    if (has(TO_ML, from)) ml = amount * TO_ML[from];
    if (has(TO_G, from)) ml = (amount * TO_G[from]) / density;
    if (ml !== null) {
      if (has(TO_ML, to)) result = ml / TO_ML[to];
      if (has(TO_G, to)) result = (ml * density) / TO_G[to];
    }
  }
  if (result === null) return fail("unsupported", `Cannot convert ${from} to ${to}`);
  const rounded = Math.round(result * 100) / 100;
  return ok({ amount, from, to, result: rounded }, { kind: "status", text: `${dartDouble(amount)} ${from} = ${dartDouble(rounded)} ${to}`, icon: "scale" });
}
