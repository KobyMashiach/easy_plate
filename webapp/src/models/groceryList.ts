// A grocery list exactly as the app stores it in users/{uid}/grocery_lists/{id}
// (GroceryListModel.toJson in lib/features/grocery_list/data/models/
// grocery_list_model.g.dart, with GroceryItemModel and GroceryItemSourceModel
// nested). Read through `normalizeGroceryList`; write only what
// `groceryListToDart` returns — every key present, nulls included.
// webapp/contract-fixtures/grocery_lists/ holds samples the Dart contract
// test parses.
//
// Pure: no React, no Firestore. The aggregation the app does
// (build_aggregate_grocery_list_usecase.dart) lives here too, so any screen —
// the groceries pages, the assistant — builds a list the same way.
import { MEASUREMENT_UNITS, normalizeIngredient, type CollabRole, type Ingredient, type MeasurementUnit } from "./recipe";

/** kDefaultGroceryCategory in lib/core/constants/app_constants.dart. */
export const DEFAULT_GROCERY_CATEGORY = "כללי";

/** What a list is built from, and so what "rebuild" means for it. */
export const GROCERY_LIST_SOURCES = ["plans", "recipe", "manual"] as const;
export type GroceryListSource = (typeof GROCERY_LIST_SOURCES)[number];

/** The id of the list every account had before there could be several. */
export const DEFAULT_GROCERY_LIST_ID = "primary";

export interface GroceryItemSource {
  /** Null for a hand-added amount (an ad-hoc line, a buffer). */
  recipeId: string | null;
  label: string;
  amount: number;
}

export interface GroceryItem {
  id: string;
  name: string;
  unit: MeasurementUnit;
  sources: GroceryItemSource[];
  isChecked: boolean;
  category: string;
  isAdHoc: boolean;
}

export interface GroceryList {
  id: string;
  name: string;
  items: GroceryItem[];
  /** uid → AccessRole name ("owner" | "editor" | "viewer"). */
  collaborators: Record<string, string>;
  /** ISO-8601, as DateTime.toIso8601String(). */
  createdAt: string;
  /** Empty means every plan. Only meaningful for a plans list. */
  selectedPlanIds: string[];
  contentLang: string | null;
  contentVersion: number;
  source: GroceryListSource;
  recipeId: string | null;
  recipeScale: number;
  recipeServings: number | null;
  recipeTitle: string | null;
  collabId: string | null;
  collabRole: CollabRole | null;
}

const rec = (v: unknown): Record<string, unknown> => (v && typeof v === "object" && !Array.isArray(v) ? (v as Record<string, unknown>) : {});
const str = (v: unknown): string | null => (typeof v === "string" ? v : null);
const num = (v: unknown): number | null => (typeof v === "number" && Number.isFinite(v) ? v : null);
const int = (v: unknown): number | null => (typeof v === "number" && Number.isFinite(v) ? Math.trunc(v) : null);
const unitOf = (v: unknown): MeasurementUnit => ((MEASUREMENT_UNITS as readonly string[]).includes(v as string) ? (v as MeasurementUnit) : "unspecified");
const roleOf = (v: unknown): CollabRole | null => (v === "owner" || v === "editor" || v === "viewer" ? v : null);

export function normalizeGrocerySource(raw: unknown): GroceryItemSource {
  const r = rec(raw);
  return { recipeId: str(r.recipeId), label: String(r.label ?? ""), amount: num(r.amount) ?? 0 };
}

export function normalizeGroceryItem(raw: unknown): GroceryItem {
  const r = rec(raw);
  return {
    id: String(r.id ?? ""),
    name: String(r.name ?? ""),
    unit: unitOf(r.unit),
    sources: Array.isArray(r.sources) ? r.sources.map(normalizeGrocerySource) : [],
    isChecked: r.isChecked === true,
    category: str(r.category) ?? DEFAULT_GROCERY_CATEGORY,
    isAdHoc: r.isAdHoc === true,
  };
}

/** Any stored document → a complete list (the app's defaults where it has them). */
export function normalizeGroceryList(raw: unknown): GroceryList {
  const r = rec(raw);
  const collaborators: Record<string, string> = {};
  for (const [k, v] of Object.entries(rec(r.collaborators))) if (typeof v === "string") collaborators[k] = v;
  const source = (GROCERY_LIST_SOURCES as readonly string[]).includes(r.source as string) ? (r.source as GroceryListSource) : "plans";
  return {
    id: String(r.id ?? ""),
    name: String(r.name ?? ""),
    items: Array.isArray(r.items) ? r.items.map(normalizeGroceryItem) : [],
    collaborators,
    createdAt: str(r.createdAt) ?? new Date(0).toISOString(),
    selectedPlanIds: Array.isArray(r.selectedPlanIds) ? r.selectedPlanIds.filter((s): s is string => typeof s === "string") : [],
    contentLang: str(r.contentLang),
    contentVersion: int(r.contentVersion) ?? 0,
    source,
    recipeId: str(r.recipeId),
    recipeScale: num(r.recipeScale) ?? 1,
    recipeServings: int(r.recipeServings),
    recipeTitle: str(r.recipeTitle),
    collabId: str(r.collabId),
    collabRole: roleOf(r.collabRole),
  };
}

export function groceryItemToDart(i: GroceryItem): Record<string, unknown> {
  return {
    id: i.id,
    name: i.name,
    unit: i.unit,
    sources: i.sources.map((s) => ({ recipeId: s.recipeId, label: s.label, amount: s.amount })),
    isChecked: i.isChecked,
    category: i.category,
    isAdHoc: i.isAdHoc,
  };
}

/** The exact document the app writes (key order mirrors GroceryListModel.toJson). */
export function groceryListToDart(l: GroceryList): Record<string, unknown> {
  return {
    id: l.id,
    name: l.name,
    items: l.items.map(groceryItemToDart),
    collaborators: { ...l.collaborators },
    createdAt: l.createdAt,
    selectedPlanIds: [...l.selectedPlanIds],
    contentLang: l.contentLang,
    contentVersion: Math.trunc(l.contentVersion),
    source: l.source,
    recipeId: l.recipeId,
    recipeScale: l.recipeScale,
    recipeServings: l.recipeServings === null ? null : Math.trunc(l.recipeServings),
    recipeTitle: l.recipeTitle,
    collabId: l.collabId,
    collabRole: l.collabRole,
  };
}

export function newGroceryList(id: string, name: string, source: GroceryListSource, createdAt = new Date().toISOString()): GroceryList {
  return normalizeGroceryList({ id, name, items: [], createdAt, source });
}

// ---------------------------------------------------------------------------
// What the entity knows about itself (grocery_list_entity.dart).

export const totalAmount = (item: GroceryItem): number => item.sources.reduce((sum, s) => sum + s.amount, 0);
export const isSharedList = (l: GroceryList): boolean => l.collabId !== null;
export const canEditList = (l: GroceryList): boolean => l.collabRole !== "viewer";
/** Mine outright, or mine as the owner of the share. */
export const isMyList = (l: GroceryList): boolean => l.collabRole === null || l.collabRole === "owner";
export const includesAllPlans = (l: GroceryList): boolean => l.selectedPlanIds.length === 0;
export const canRegenerate = (l: GroceryList): boolean => l.source !== "manual";
export const checkedCount = (l: GroceryList): number => l.items.filter((i) => i.isChecked).length;

/** Oldest first, as the app's switcher orders them. */
export const byCreatedAt = (a: GroceryList, b: GroceryList): number => a.createdAt.localeCompare(b.createdAt);

/**
 * The app's save rule (GroceryListsRepositoryImpl._stamped): marked with the
 * language it is written in; contentVersion moves on only when the words
 * (the name and the item names) changed.
 */
export function stampGroceryList(next: GroceryList, previous: GroceryList | null, lang: string): GroceryList {
  const words = (l: GroceryList) => [l.name, ...l.items.map((i) => i.name)].join("\n");
  const edited = previous === null || words(previous) !== words(next);
  if (!edited && next.contentLang !== null) return next;
  return { ...next, contentLang: lang, contentVersion: edited && previous !== null ? previous.contentVersion + 1 : next.contentVersion };
}

// ---------------------------------------------------------------------------
// Building lines (build_aggregate_grocery_list_usecase.dart).

/** The slice of a recipe the aggregation reads. */
export interface RecipeLike {
  id: string;
  title: string;
  ingredients: Ingredient[];
  servings?: number | null;
}

/** The slice of a meal plan the aggregation reads (MealPlanModel JSON). */
export interface PlanLike {
  id: string;
  name: string;
  meals: { name: string; items: { id: string; recipeId: string | null; freeText: string | null; ingredients: Ingredient[] }[] }[];
}

/** Any stored meal plan → the fields the aggregation needs. */
export function planLikeOf(raw: unknown): PlanLike {
  const r = rec(raw);
  return {
    id: String(r.id ?? ""),
    name: String(r.name ?? ""),
    meals: (Array.isArray(r.meals) ? r.meals : []).map((m) => {
      const mm = rec(m);
      return {
        name: String(mm.name ?? ""),
        items: (Array.isArray(mm.items) ? mm.items : []).map((it) => {
          const ii = rec(it);
          return {
            id: String(ii.id ?? ""),
            recipeId: str(ii.recipeId),
            freeText: str(ii.freeText),
            ingredients: Array.isArray(ii.ingredients) ? ii.ingredients.map(normalizeIngredient) : [],
          };
        }),
      };
    }),
  };
}

/** Folds ingredients into `aggregated`, summing any that match by normalized name + unit. */
export function addIngredientLines(
  aggregated: Map<string, GroceryItem>,
  ingredients: Ingredient[],
  sourceLabel: string,
  recipeId: string | null,
  scale = 1,
): void {
  for (const ing of ingredients) {
    const key = `${ing.name.trim().toLowerCase()}|${ing.unit}`;
    const source: GroceryItemSource = { recipeId, label: sourceLabel, amount: (ing.amount ?? 0) * scale };
    const existing = aggregated.get(key);
    aggregated.set(
      key,
      existing
        ? { ...existing, sources: [...existing.sources, source] }
        : { id: key, name: ing.name, unit: ing.unit, sources: [source], isChecked: false, category: DEFAULT_GROCERY_CATEGORY, isAdHoc: false },
    );
  }
}

/** One recipe's shopping lines, made `scale` times over. */
export function groceryItemsForRecipe(recipe: RecipeLike, scale = 1): GroceryItem[] {
  const aggregated = new Map<string, GroceryItem>();
  addIngredientLines(aggregated, recipe.ingredients, recipe.title, recipe.id, scale);
  return [...aggregated.values()];
}

/** Every line of the given plans: recipes resolved through `recipeById`, free-text dishes as ad-hoc lines. */
export function groceryItemsForPlans(plans: PlanLike[], recipeById: (id: string) => RecipeLike | null | undefined): GroceryItem[] {
  const aggregated = new Map<string, GroceryItem>();
  for (const plan of plans) {
    for (const meal of plan.meals) {
      for (const item of meal.items) {
        if (item.recipeId) {
          const recipe = recipeById(item.recipeId);
          if (!recipe) continue;
          addIngredientLines(aggregated, recipe.ingredients, recipe.title, recipe.id);
        } else if (item.freeText && item.freeText.trim()) {
          if (item.ingredients.length > 0) {
            addIngredientLines(aggregated, item.ingredients, item.freeText, null);
          } else {
            const key = `freeText|${item.id}`;
            aggregated.set(key, {
              id: key,
              name: item.freeText,
              unit: "unspecified",
              sources: [{ recipeId: null, label: meal.name, amount: 1 }],
              isChecked: false,
              category: DEFAULT_GROCERY_CATEGORY,
              isAdHoc: true,
            });
          }
        }
      }
    }
  }
  return [...aggregated.values()];
}

/**
 * The app's rebuild merge (GroceryListBloc._regenerate): the rebuilt lines,
 * ticked where the same line was ticked before, then the hand-added lines the
 * rebuild did not produce itself.
 */
export function mergeRebuilt(current: GroceryList, built: GroceryItem[]): GroceryItem[] {
  const checked = new Set(current.items.filter((i) => i.isChecked).map((i) => i.id));
  const builtIds = new Set(built.map((i) => i.id));
  const adHoc = current.items.filter((i) => i.isAdHoc && !builtIds.has(i.id));
  return [...built.map((i) => (checked.has(i.id) ? { ...i, isChecked: true } : i)), ...adHoc];
}

/** A line added by hand: one manual source, so it edits like any other. */
export function adHocItem(id: string, name: string, amount: number, unit: MeasurementUnit): GroceryItem {
  return { id, name, unit, sources: [{ recipeId: null, label: name, amount }], isChecked: false, category: DEFAULT_GROCERY_CATEGORY, isAdHoc: true };
}

/** A recipe list made `scale` times over: only the recipe's own shares move. */
export function rescaleRecipeList(list: GroceryList, scale: number): GroceryList {
  if (list.source !== "recipe" || scale <= 0 || scale === list.recipeScale) return list;
  const factor = scale / list.recipeScale;
  return {
    ...list,
    recipeScale: scale,
    items: list.items.map((item) =>
      item.isAdHoc
        ? item
        : { ...item, sources: item.sources.map((s) => (s.recipeId !== null && s.recipeId === list.recipeId ? { ...s, amount: s.amount * factor } : s)) },
    ),
  };
}

// ---------------------------------------------------------------------------
// The shared copy (collab_containers/{id}, kind "groceryList") — the app's
// GroceryListContainerAdapter encode/decode.

export function groceryContainerContent(l: GroceryList): Record<string, unknown> {
  return {
    items: l.items.map((line) => ({
      id: line.id,
      name: line.name,
      unit: line.unit,
      category: line.category,
      isChecked: line.isChecked,
      isAdHoc: line.isAdHoc,
      sources: line.sources.map((s) => ({ label: s.label, amount: s.amount })),
    })),
  };
}

/** The shared document laid over this account's copy. `mine`: this account owns the share. */
/**
 * An id for a shared line that came without one, the same on every read:
 * a random one made every snapshot look changed and rewrote the list each
 * time. uuid-shaped (v4 layout), from the list, the line's name, unit and
 * position.
 */
export function stableItemId(listId: string, name: string, unit: string, index: number): string {
  const input = `${listId}\u0000${name}\u0000${unit}\u0000${index}`;
  let hex = "";
  for (let seed = 0; seed < 4; seed++) {
    let h = (0x811c9dc5 ^ (seed * 0x9e3779b1)) >>> 0;
    for (let i = 0; i < input.length; i++) {
      h ^= input.charCodeAt(i);
      h = Math.imul(h, 0x01000193) >>> 0;
    }
    hex += h.toString(16).padStart(8, "0");
  }
  return `${hex.slice(0, 8)}-${hex.slice(8, 12)}-4${hex.slice(13, 16)}-${((parseInt(hex[16], 16) & 0x3) | 0x8).toString(16)}${hex.slice(17, 20)}-${hex.slice(20, 32)}`;
}

export function groceryListFromContainer(
  container: { id: string; title: string; content: unknown },
  local: GroceryList,
  role: CollabRole,
): GroceryList {
  const items: GroceryItem[] = [];
  const content = rec(container.content);
  const rawItems: unknown[] = Array.isArray(content.items) ? content.items : [];
  for (const [index, raw] of rawItems.entries()) {
    const r = rec(raw);
    if (!raw || typeof raw !== "object") continue;
    items.push({
      id: str(r.id) ?? stableItemId(container.id, str(r.name) ?? "", str(r.unit) ?? "", index),
      name: str(r.name) ?? "",
      unit: unitOf(r.unit),
      sources: (Array.isArray(r.sources) ? r.sources : [])
        .filter((s) => s && typeof s === "object")
        .map((s) => ({ recipeId: null, label: str(rec(s).label) ?? "", amount: num(rec(s).amount) ?? 0 })),
      category: str(r.category) ?? "",
      isChecked: r.isChecked === true,
      isAdHoc: r.isAdHoc === true,
    });
  }
  const mine = role === "owner";
  return {
    ...local,
    name: container.title,
    items,
    selectedPlanIds: mine ? local.selectedPlanIds : [],
    source: mine ? local.source : "manual",
    recipeId: mine ? local.recipeId : null,
    recipeScale: mine ? local.recipeScale : 1,
    recipeServings: mine ? local.recipeServings : null,
    recipeTitle: mine ? local.recipeTitle : null,
    collabId: container.id,
    collabRole: role,
  };
}

/** A line's shared-content fingerprint: equal means the shared copy says nothing new. */
export function groceryShareKey(l: GroceryList): string {
  return JSON.stringify({ t: l.name, r: l.collabRole, c: groceryContainerContent(l) });
}
