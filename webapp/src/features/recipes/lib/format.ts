// The app's display rules for a recipe, ported one for one:
//   formatAmount       lib/core/utils/amount_format.dart
//   durationLabel      lib/core/utils/duration_label.dart
//   kcalNumber         lib/core/widgets/nutrition/nutrition_widgets.dart
//   ingredient lines   recipe_details_page.dart _ingredientLine
import type { Ingredient, Nutrition, Recipe } from "../../../models/recipe";

type T = (key: string, vars?: Record<string, string | number>) => string;

/** `800`, not `800.0`; `1.5`, not `1.50`; two decimals at most; null → "". */
export function formatAmount(value: number | null | undefined): string {
  if (value === null || value === undefined || !Number.isFinite(value)) return "";
  if (value === Math.round(value)) return String(Math.round(value));
  return value.toFixed(2).replace(/0+$/, "").replace(/\.$/, "");
}

/** "45 min", "2 hr", "2 hr 40 min" — minutes roll over into hours past 59. */
export function durationLabel(t: T, minutes: number): string {
  if (minutes < 60) return t("recipes.minutes", { count: minutes });
  const hours = Math.floor(minutes / 60);
  const rest = minutes % 60;
  return rest === 0 ? t("recipes.hours", { count: hours }) : t("recipes.hoursAndMinutes", { hours, minutes: rest });
}

/** Null means the source never said, which is not zero. */
export function optionalDuration(t: T, minutes: number | null): string {
  return minutes === null ? t("recipes.missingInfo") : durationLabel(t, minutes);
}

/** "1,247": thousands grouped with a comma, as the app writes calories. */
export function kcalNumber(kcal: number): string {
  const digits = String(Math.abs(Math.trunc(kcal)));
  const grouped = digits.replace(/\B(?=(\d{3})+(?!\d))/g, ",");
  return kcal < 0 ? `-${grouped}` : grouped;
}

/** The unit as the cook reads it (blank for "unspecified"). */
export function unitLabel(t: T, unit: Ingredient["unit"]): string {
  return unit === "unspecified" ? "" : t(`unit.${unit}`);
}

/** The picker label: "unspecified" still needs something to tap. */
export function unitPickerLabel(t: T, unit: Ingredient["unit"]): string {
  return unit === "unspecified" ? t("recipes.unitNone") : t(`unit.${unit}`);
}

/** Amount and unit, scaled; the app's placeholder when the amount is missing. */
export function quantityLabel(t: T, ingredient: Ingredient, scale = 1): string {
  const amount = ingredient.amount === null ? t("recipes.missingInfo") : formatAmount(ingredient.amount * scale);
  return [amount, unitLabel(t, ingredient.unit)].filter((s) => s !== "").join(" ");
}

export function ingredientLine(t: T, ingredient: Ingredient, scale = 1): string {
  return [quantityLabel(t, ingredient, scale), ingredient.name].filter((s) => s !== "").join(" ");
}

export function totalMinutes(r: Recipe): number {
  return (r.prepTimeMinutes ?? 0) + (r.cookTimeMinutes ?? 0);
}

export function roleLabel(t: T, role: Recipe["collabRole"]): string | null {
  if (role === "owner") return t("recipes.ownerTag");
  if (role === "editor") return t("recipes.editorTag");
  if (role === "viewer") return t("recipes.viewerTag");
  return null;
}

/** A nutrition entry for the whole recipe (per serving × servings). */
export function scaledNutrition(n: Nutrition, factor: number): Nutrition {
  return {
    calories: Math.round(n.calories * factor),
    proteinGrams: n.proteinGrams * factor,
    carbsGrams: n.carbsGrams * factor,
    fatGrams: n.fatGrams * factor,
  };
}

/** Whole grams, as the app shows an estimate. */
export function grams(t: T, value: number): string {
  return `${Math.round(value)} ${t("recipes.nut.gramsShort")}`;
}

/** Recipes this account wrote (not saved from the community, not someone else's share). */
export function isMine(r: Recipe): boolean {
  return r.savedFromSharedId === null && (r.collabRole === null || r.collabRole === "owner");
}

/** The tag colours of the app's dietaryTagColors, as token classes. */
export const DIET_TONE: Record<string, string> = {
  meat: "bg-error-container text-on-error-container",
  dairy: "bg-info-container text-on-info-container",
  vegetarian: "bg-secondary-container text-on-secondary-container",
  vegan: "bg-secondary-fixed text-on-secondary-fixed",
  kosher: "bg-tertiary-fixed text-on-tertiary-fixed",
  glutenFree: "bg-primary-fixed text-on-primary-fixed-variant",
  allergy: "bg-surface-highest text-on-surface-variant",
};
