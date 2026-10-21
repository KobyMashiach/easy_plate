// A recipe record exactly as the app stores it in users/{uid}/recipes/{id}
// (RecipeModel.toJson in lib/features/my_recipes/data/models/recipe_model.g.dart).
// Read through `normalizeRecipe` (older documents can lack newer keys) and
// write only what `recipeToDart` returns — every key present, nulls included.
// webapp/contract-fixtures/recipes/ holds samples the Dart contract test parses.

export const MEASUREMENT_UNITS = ["gram", "kilogram", "milliliter", "liter", "teaspoon", "tablespoon", "cup", "unit", "pinch", "unspecified"] as const;
export type MeasurementUnit = (typeof MEASUREMENT_UNITS)[number];

export const DIETARY = ["meat", "dairy", "vegetarian", "vegan", "kosher", "glutenFree", "allergy"] as const;
export type DietaryPreference = (typeof DIETARY)[number];

export const ALLERGENS = ["gluten", "milk", "eggs", "fish", "shellfish", "peanuts", "treeNuts", "sesame", "soy"] as const;
export type Allergen = (typeof ALLERGENS)[number];

export const CHANNELS = ["rawText", "webSearch", "urlScrape", "socialVideo", "aiRequest", "manual", "file"] as const;
export type IngestionChannel = (typeof CHANNELS)[number];

export type CollabRole = "owner" | "editor" | "viewer";

export interface Ingredient {
  name: string;
  amount: number | null;
  unit: MeasurementUnit;
}

export interface Nutrition {
  calories: number;
  proteinGrams: number;
  carbsGrams: number;
  fatGrams: number;
}

export interface Recipe {
  id: string;
  title: string;
  prepTimeMinutes: number | null;
  cookTimeMinutes: number | null;
  ingredients: Ingredient[];
  steps: string[];
  dietaryTags: DietaryPreference[];
  sourceChannel: IngestionChannel | null;
  sourceUrl: string | null;
  /** ISO-8601, as DateTime.toIso8601String(). */
  createdAt: string;
  imageFileName: string | null;
  savedFromSharedId: string | null;
  pendingAnalysis: boolean;
  collabId: string | null;
  collabRole: CollabRole | null;
  imageStoragePath: string | null;
  allergens: Allergen[];
  mayContain: Allergen[];
  servings: number | null;
  nutrition: Nutrition | null;
  sharedRecipeId: string | null;
  contentLang: string | null;
  contentVersion: number;
}

const str = (v: unknown): string | null => (typeof v === "string" ? v : null);
const int = (v: unknown): number | null => (typeof v === "number" && Number.isFinite(v) ? Math.trunc(v) : null);
const num = (v: unknown): number | null => (typeof v === "number" && Number.isFinite(v) ? v : null);
const oneOf = <T extends string>(v: unknown, all: readonly T[]): T | null => (typeof v === "string" && (all as readonly string[]).includes(v) ? (v as T) : null);

export function normalizeIngredient(raw: unknown): Ingredient {
  const r = (raw && typeof raw === "object" ? raw : {}) as Record<string, unknown>;
  return { name: String(r.name ?? ""), amount: num(r.amount), unit: oneOf(r.unit, MEASUREMENT_UNITS) ?? "unspecified" };
}

/** Any stored document → a complete Recipe (defaults where the app has them). */
export function normalizeRecipe(raw: unknown): Recipe {
  const r = (raw && typeof raw === "object" ? raw : {}) as Record<string, unknown>;
  const nut = r.nutrition && typeof r.nutrition === "object" ? (r.nutrition as Record<string, unknown>) : null;
  return {
    id: String(r.id ?? ""),
    title: String(r.title ?? ""),
    prepTimeMinutes: int(r.prepTimeMinutes),
    cookTimeMinutes: int(r.cookTimeMinutes),
    ingredients: Array.isArray(r.ingredients) ? r.ingredients.map(normalizeIngredient) : [],
    steps: Array.isArray(r.steps) ? r.steps.filter((s): s is string => typeof s === "string") : [],
    dietaryTags: Array.isArray(r.dietaryTags) ? r.dietaryTags.map((d) => oneOf(d, DIETARY)).filter((d): d is DietaryPreference => d !== null) : [],
    sourceChannel: oneOf(r.sourceChannel, CHANNELS),
    sourceUrl: str(r.sourceUrl),
    createdAt: str(r.createdAt) ?? new Date(0).toISOString(),
    imageFileName: str(r.imageFileName),
    savedFromSharedId: str(r.savedFromSharedId),
    pendingAnalysis: r.pendingAnalysis === true,
    collabId: str(r.collabId),
    collabRole: oneOf(r.collabRole, ["owner", "editor", "viewer"] as const),
    imageStoragePath: str(r.imageStoragePath),
    allergens: Array.isArray(r.allergens) ? r.allergens.map((a) => oneOf(a, ALLERGENS)).filter((a): a is Allergen => a !== null) : [],
    mayContain: Array.isArray(r.mayContain) ? r.mayContain.map((a) => oneOf(a, ALLERGENS)).filter((a): a is Allergen => a !== null) : [],
    servings: int(r.servings),
    nutrition: nut && typeof nut.calories === "number"
      ? { calories: Math.trunc(nut.calories), proteinGrams: num(nut.proteinGrams) ?? 0, carbsGrams: num(nut.carbsGrams) ?? 0, fatGrams: num(nut.fatGrams) ?? 0 }
      : null,
    sharedRecipeId: str(r.sharedRecipeId),
    contentLang: str(r.contentLang),
    contentVersion: int(r.contentVersion) ?? 0,
  };
}

/** The exact document the app writes (key order mirrors RecipeModel.toJson). */
export function recipeToDart(r: Recipe): Record<string, unknown> {
  return {
    id: r.id,
    title: r.title,
    prepTimeMinutes: r.prepTimeMinutes,
    cookTimeMinutes: r.cookTimeMinutes,
    ingredients: r.ingredients.map((i) => ({ name: i.name, amount: i.amount, unit: i.unit })),
    steps: r.steps,
    dietaryTags: r.dietaryTags,
    sourceChannel: r.sourceChannel,
    sourceUrl: r.sourceUrl,
    createdAt: r.createdAt,
    imageFileName: r.imageFileName,
    savedFromSharedId: r.savedFromSharedId,
    pendingAnalysis: r.pendingAnalysis,
    collabId: r.collabId,
    collabRole: r.collabRole,
    imageStoragePath: r.imageStoragePath,
    allergens: r.allergens,
    mayContain: r.mayContain,
    servings: r.servings,
    nutrition: r.nutrition ? { calories: Math.trunc(r.nutrition.calories), proteinGrams: r.nutrition.proteinGrams, carbsGrams: r.nutrition.carbsGrams, fatGrams: r.nutrition.fatGrams } : null,
    sharedRecipeId: r.sharedRecipeId,
    contentLang: r.contentLang,
    contentVersion: r.contentVersion,
  };
}

export function blankRecipe(id: string): Recipe {
  return normalizeRecipe({ id, title: "", createdAt: new Date().toISOString(), sourceChannel: "manual" });
}

/** A recipe the account may change: its own, or a shared one it edits. */
export function canEditRecipe(r: Recipe): boolean {
  return r.collabRole === null || r.collabRole === "owner" || r.collabRole === "editor";
}

/**
 * The app's save rule (RecipesRepositoryImpl._stamped): a record is marked
 * with the language it is written in, and its contentVersion moves on only
 * when the words changed — so translations of the old wording are redone,
 * while a photo- or tag-only save leaves them alone.
 */
export function stampRecipe(next: Recipe, previous: Recipe | null, lang: string): Recipe {
  const words = (r: Recipe) => [r.title, ...r.ingredients.map((i) => i.name), ...r.steps].join("\n");
  const edited = previous === null || words(previous) !== words(next);
  if (!edited && next.contentLang !== null) return next;
  return {
    ...next,
    contentLang: lang,
    contentVersion: edited && previous !== null ? previous.contentVersion + 1 : next.contentVersion,
  };
}
