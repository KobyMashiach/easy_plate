// A meal plan exactly as the app stores it in users/{uid}/meal_plans/{id}
// (MealPlanModel / MealModel / MealItemModel .toJson in
// lib/features/meal_planner/data/models/*.g.dart). Read through
// `normalizeMealPlan`, write only what `mealPlanToDart` returns — every key
// present, nulls included. webapp/contract-fixtures/meal_plans/ holds the
// samples the Dart contract test parses.
//
// The week is `weekday` 0..6 = ShoppingDay.sunday..saturday. An item is either
// a recipe (`recipeId`, no ingredients) or a quick entry (`freeText` plus the
// products it is made of). There is no per-item servings field: the app counts
// every recipe item as one serving (PlanNutrition).
import { normalizeIngredient, type Ingredient, type Nutrition, type Recipe } from "./recipe";

export const WEEKDAYS = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"] as const;
export type Weekday = (typeof WEEKDAYS)[number];

export type PlanCollabRole = "owner" | "editor" | "viewer";

export interface MealItem {
  id: string;
  recipeId: string | null;
  freeText: string | null;
  /** Products of a quick entry; empty for a recipe item. */
  ingredients: Ingredient[];
}

export interface Meal {
  id: string;
  /** 0 = Sunday … 6 = Saturday. */
  weekday: number;
  name: string;
  order: number;
  items: MealItem[];
}

export interface MealPlan {
  id: string;
  name: string;
  meals: Meal[];
  /** ISO-8601, as DateTime.toIso8601String(). */
  createdAt: string;
  collabId: string | null;
  collabRole: PlanCollabRole | null;
  contentLang: string | null;
  contentVersion: number;
}

const str = (v: unknown): string | null => (typeof v === "string" ? v : null);
const int = (v: unknown): number | null => (typeof v === "number" && Number.isFinite(v) ? Math.trunc(v) : null);
const obj = (v: unknown) => (v && typeof v === "object" ? v : {}) as Record<string, unknown>;
const ROLES = ["owner", "editor", "viewer"] as const;

export function normalizeMealItem(raw: unknown): MealItem {
  const r = obj(raw);
  return {
    id: String(r.id ?? ""),
    recipeId: str(r.recipeId),
    freeText: str(r.freeText),
    ingredients: Array.isArray(r.ingredients) ? r.ingredients.map(normalizeIngredient) : [],
  };
}

export function normalizeMeal(raw: unknown, index = 0): Meal {
  const r = obj(raw);
  const weekday = int(r.weekday) ?? 0;
  return {
    id: String(r.id ?? ""),
    weekday: Math.max(0, Math.min(6, weekday)),
    name: String(r.name ?? ""),
    order: int(r.order) ?? index,
    items: Array.isArray(r.items) ? r.items.map(normalizeMealItem) : [],
  };
}

/** Any stored document → a complete MealPlan (the app's defaults). */
export function normalizeMealPlan(raw: unknown): MealPlan {
  const r = obj(raw);
  const role = typeof r.collabRole === "string" && (ROLES as readonly string[]).includes(r.collabRole) ? (r.collabRole as PlanCollabRole) : null;
  return {
    id: String(r.id ?? ""),
    name: String(r.name ?? ""),
    meals: Array.isArray(r.meals) ? r.meals.map((m, i) => normalizeMeal(m, i)) : [],
    createdAt: str(r.createdAt) ?? new Date(0).toISOString(),
    collabId: str(r.collabId),
    collabRole: role,
    contentLang: str(r.contentLang),
    contentVersion: int(r.contentVersion) ?? 0,
  };
}

export function mealItemToDart(i: MealItem): Record<string, unknown> {
  return {
    id: i.id,
    recipeId: i.recipeId,
    freeText: i.freeText,
    ingredients: i.ingredients.map((g) => ({ name: g.name, amount: g.amount, unit: g.unit })),
  };
}

export function mealToDart(m: Meal): Record<string, unknown> {
  return { id: m.id, weekday: Math.trunc(m.weekday), name: m.name, order: Math.trunc(m.order), items: m.items.map(mealItemToDart) };
}

/** The exact document the app writes (key order mirrors MealPlanModel.toJson). */
export function mealPlanToDart(p: MealPlan): Record<string, unknown> {
  return {
    id: p.id,
    name: p.name,
    meals: p.meals.map(mealToDart),
    createdAt: p.createdAt,
    collabId: p.collabId,
    collabRole: p.collabRole,
    contentLang: p.contentLang,
    contentVersion: Math.trunc(p.contentVersion),
  };
}

/** MealPlanEntity.canEdit / isMine / isShared. */
export function canEditPlan(p: MealPlan): boolean {
  return p.collabRole !== "viewer";
}
export function isPlanMine(p: MealPlan): boolean {
  return p.collabRole === null || p.collabRole === "owner";
}
export function isPlanShared(p: MealPlan): boolean {
  return p.collabId !== null;
}

/** MealPlanEntity.mealsForWeekday: that day's meals in `order`. */
export function mealsForWeekday(p: MealPlan, weekday: number): Meal[] {
  return p.meals.filter((m) => m.weekday === weekday).sort((a, b) => a.order - b.order);
}

/**
 * MealPlannerBloc._createPlan: a template seeds the same meal names on every
 * weekday (pass [] for the free template). Names are in the UI language, as
 * the app writes them.
 */
export function newMealPlan(id: string, name: string, mealNames: string[], makeId: () => string): MealPlan {
  const meals: Meal[] = [];
  for (let weekday = 0; weekday < WEEKDAYS.length; weekday++)
    mealNames.forEach((mealName, order) => meals.push({ id: makeId(), weekday, name: mealName, order, items: [] }));
  return { id, name, meals, createdAt: new Date().toISOString(), collabId: null, collabRole: null, contentLang: null, contentVersion: 0 };
}

/** MealPlannerBloc._addMeal: appended after the day's last meal. */
export function withMealAdded(p: MealPlan, weekday: number, name: string, id: string): MealPlan {
  const order = mealsForWeekday(p, weekday).length;
  return { ...p, meals: [...p.meals, { id, weekday, name, order, items: [] }] };
}

export function withMealRemoved(p: MealPlan, mealId: string): MealPlan {
  return { ...p, meals: p.meals.filter((m) => m.id !== mealId) };
}

export function withMealRenamed(p: MealPlan, mealId: string, name: string): MealPlan {
  return { ...p, meals: p.meals.map((m) => (m.id === mealId ? { ...m, name } : m)) };
}

export function withItemAdded(p: MealPlan, mealId: string, item: MealItem): MealPlan {
  return { ...p, meals: p.meals.map((m) => (m.id === mealId ? { ...m, items: [...m.items, item] } : m)) };
}

export function withItemRemoved(p: MealPlan, mealId: string, itemId: string): MealPlan {
  return { ...p, meals: p.meals.map((m) => (m.id === mealId ? { ...m, items: m.items.filter((i) => i.id !== itemId) } : m)) };
}

/** MealPlannerBloc._updateFreeTextItem: a quick entry's text and products. */
export function withItemUpdated(p: MealPlan, mealId: string, itemId: string, freeText: string, ingredients: Ingredient[]): MealPlan {
  return {
    ...p,
    meals: p.meals.map((m) => (m.id === mealId ? { ...m, items: m.items.map((i) => (i.id === itemId ? { ...i, freeText, ingredients } : i)) } : m)),
  };
}

/** Moves an item to the end of another meal (same id, same content). */
export function withItemMoved(p: MealPlan, fromMealId: string, itemId: string, toMealId: string): MealPlan {
  if (fromMealId === toMealId) return p;
  const item = p.meals.find((m) => m.id === fromMealId)?.items.find((i) => i.id === itemId);
  if (!item || !p.meals.some((m) => m.id === toMealId)) return p;
  return withItemAdded(withItemRemoved(p, fromMealId, itemId), toMealId, item);
}

/** MealPlansRepositoryImpl._words: the text a translation is made from. */
export function planWords(p: MealPlan): string {
  return [p.name, ...p.meals.flatMap((m) => [m.name, ...m.items.map((i) => i.freeText ?? "")])].join("\n");
}

/**
 * The app's save rule (MealPlansRepositoryImpl._stamped): stamp the language
 * when the words changed or were never stamped; contentVersion moves on only
 * when an existing plan's words changed.
 */
export function stampMealPlan(next: MealPlan, previous: MealPlan | null, lang: string): MealPlan {
  const edited = previous === null || planWords(previous) !== planWords(next);
  if (!edited && next.contentLang !== null) return next;
  return {
    ...next,
    contentLang: lang,
    contentVersion: edited && previous !== null ? previous.contentVersion + 1 : next.contentVersion,
  };
}

// ---------------------------------------------------------------------------
// Nutrition roll-up (lib/features/meal_planner/domain/nutrition_summary.dart).
// Every recipe item is one serving of that recipe; quick entries and recipes
// with no estimate are counted as missing, never as zero.

export const ZERO_NUTRITION: Nutrition = { calories: 0, proteinGrams: 0, carbsGrams: 0, fatGrams: 0 };

export function addNutrition(a: Nutrition, b: Nutrition): Nutrition {
  return { calories: a.calories + b.calories, proteinGrams: a.proteinGrams + b.proteinGrams, carbsGrams: a.carbsGrams + b.carbsGrams, fatGrams: a.fatGrams + b.fatGrams };
}

export function scaleNutrition(n: Nutrition, factor: number): Nutrition {
  return { calories: Math.round(n.calories * factor), proteinGrams: n.proteinGrams * factor, carbsGrams: n.carbsGrams * factor, fatGrams: n.fatGrams * factor };
}

/** NutritionEntity.macroShares: each macro's share of the 4/4/9 calories. */
export function macroShares(n: Nutrition): { protein: number; carbs: number; fat: number } {
  const total = n.proteinGrams * 4 + n.carbsGrams * 4 + n.fatGrams * 9;
  if (total <= 0) return { protein: 0, carbs: 0, fat: 0 };
  return { protein: (n.proteinGrams * 4) / total, carbs: (n.carbsGrams * 4) / total, fat: (n.fatGrams * 9) / total };
}

export interface MealNutrition {
  meal: Meal;
  total: Nutrition;
  countedItems: number;
  missingItems: number;
}

export interface DayNutrition {
  weekday: number;
  total: Nutrition;
  countedItems: number;
  missingItems: number;
  meals: MealNutrition[];
  hasData: boolean;
}

export interface PlanNutrition {
  days: DayNutrition[];
  weekTotal: Nutrition;
  /** Days with at least one counted item — what the average is over. */
  plannedDays: number;
  dailyAverage: Nutrition;
  missingItems: number;
  hasData: boolean;
  /** The largest day's calories, never zero (bar scaling). */
  peakCalories: number;
}

/** PlanNutrition.of: pure, from the plan and the recipes it points at. */
export function planNutrition(plan: MealPlan, recipes: Map<string, Pick<Recipe, "nutrition">>): PlanNutrition {
  const days: DayNutrition[] = [];
  for (let weekday = 0; weekday < WEEKDAYS.length; weekday++) {
    const meals: MealNutrition[] = [];
    let total = ZERO_NUTRITION;
    let counted = 0;
    let missing = 0;
    for (const meal of mealsForWeekday(plan, weekday)) {
      let mealTotal = ZERO_NUTRITION;
      let mealCounted = 0;
      let mealMissing = 0;
      for (const item of meal.items) {
        const n = item.recipeId === null ? null : recipes.get(item.recipeId)?.nutrition ?? null;
        if (n === null) mealMissing++;
        else {
          mealTotal = addNutrition(mealTotal, n);
          mealCounted++;
        }
      }
      meals.push({ meal, total: mealTotal, countedItems: mealCounted, missingItems: mealMissing });
      total = addNutrition(total, mealTotal);
      counted += mealCounted;
      missing += mealMissing;
    }
    days.push({ weekday, total, countedItems: counted, missingItems: missing, meals, hasData: counted > 0 });
  }
  const weekTotal = days.reduce((s, d) => addNutrition(s, d.total), ZERO_NUTRITION);
  const plannedDays = days.filter((d) => d.hasData).length;
  return {
    days,
    weekTotal,
    plannedDays,
    dailyAverage: plannedDays === 0 ? ZERO_NUTRITION : scaleNutrition(weekTotal, 1 / plannedDays),
    missingItems: days.reduce((n, d) => n + d.missingItems, 0),
    hasData: plannedDays > 0,
    peakCalories: days.reduce((peak, d) => (d.total.calories > peak ? d.total.calories : peak), 1),
  };
}

// ---------------------------------------------------------------------------
// The shared copy: collab_containers/{collabId} with kind "mealPlan"
// (PlanContainerAdapter in lib/features/collab_containers/domain/
// container_adapter.dart). A recipe item travels by the recipe's collab id;
// one that cannot be shared goes across as a quick entry under its title.

export function planContainerContent(p: MealPlan, collabIdByRecipeId: Map<string, string>, titles: Map<string, string>): Record<string, unknown> {
  return {
    meals: p.meals.map((m) => ({
      id: m.id,
      weekday: Math.trunc(m.weekday),
      name: m.name,
      order: Math.trunc(m.order),
      items: m.items.map((i) => ({
        id: i.id,
        recipeCollabId: i.recipeId === null ? null : collabIdByRecipeId.get(i.recipeId) ?? null,
        label: i.recipeId === null ? i.freeText : titles.get(i.recipeId) ?? i.freeText,
        freeText: i.freeText,
        ingredients: i.ingredients.map((g) => ({ name: g.name, amount: g.amount, unit: g.unit })),
      })),
    })),
  };
}

/** PlanContainerAdapter.decode: the document laid over this account's copy. */
export function planFromContainer(
  container: { id: string; title: string; content: unknown },
  local: MealPlan | null,
  recipeIdByCollabId: Map<string, string>,
  role: PlanCollabRole,
  makeId: () => string,
): MealPlan {
  const content = obj(container.content);
  const linked = new Set(recipeIdByCollabId.values());
  // This copy's items pointing at a recipe that never made it into the
  // document: they went across as quick entries and come back as the recipe.
  const unlinked = new Map<string, MealItem>();
  for (const m of local?.meals ?? []) for (const it of m.items) if (it.recipeId !== null && !linked.has(it.recipeId)) unlinked.set(it.id, it);
  const meals: Meal[] = [];
  for (const raw of Array.isArray(content.meals) ? content.meals : []) {
    if (!raw || typeof raw !== "object") continue;
    const r = raw as Record<string, unknown>;
    const items: MealItem[] = [];
    for (const rawItem of Array.isArray(r.items) ? r.items : []) {
      if (!rawItem || typeof rawItem !== "object") continue;
      const ri = rawItem as Record<string, unknown>;
      const own = typeof ri.id === "string" ? unlinked.get(ri.id) : undefined;
      if (own && (ri.recipeCollabId === null || ri.recipeCollabId === undefined)) {
        items.push(own);
        continue;
      }
      const localId = typeof ri.recipeCollabId === "string" ? recipeIdByCollabId.get(ri.recipeCollabId) : undefined;
      const id = str(ri.id) ?? makeId();
      items.push(
        localId
          ? { id, recipeId: localId, freeText: null, ingredients: [] }
          : { id, recipeId: null, freeText: str(ri.freeText) ?? str(ri.label) ?? "", ingredients: Array.isArray(ri.ingredients) ? ri.ingredients.map(normalizeIngredient) : [] },
      );
    }
    meals.push({ id: str(r.id) ?? makeId(), weekday: int(r.weekday) ?? 0, name: str(r.name) ?? "", order: int(r.order) ?? meals.length, items });
  }
  return {
    id: local?.id ?? makeId(),
    name: container.title,
    meals,
    createdAt: local?.createdAt ?? new Date().toISOString(),
    collabId: container.id,
    collabRole: role,
    contentLang: local?.contentLang ?? null,
    contentVersion: local?.contentVersion ?? 0,
  };
}

/** The recipe ids a shared plan carries across (ContainerAdapter.recipeIdsOf). */
export function planRecipeIds(p: MealPlan): string[] {
  return p.meals.flatMap((m) => m.items.map((i) => i.recipeId).filter((id): id is string => id !== null));
}
