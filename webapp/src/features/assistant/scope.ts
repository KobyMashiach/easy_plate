// A conversation locked to one item (AssistantScope in
// lib/features/assistant/domain/assistant_scope.dart): opened from a recipe,
// a meal plan or a grocery list, it knows that item in full and has only the
// tools that act on it. On the web: /assistant?scope=recipe|plan|list&id=…
import { T } from "./tools";

export type ScopeKind = "recipe" | "mealPlan" | "groceryList";

export interface AssistantScope {
  kind: ScopeKind;
  id: string;
  title: string;
}

/** The URL word for each kind (`?scope=`). */
export const SCOPE_PARAM: Record<string, ScopeKind> = { recipe: "recipe", plan: "mealPlan", list: "groceryList" };

export const SCOPE_TOOLS: Record<ScopeKind, ReadonlySet<string>> = {
  recipe: new Set([
    T.getRecipe,
    T.updateRecipe,
    T.openRecipe,
    T.listBooks,
    T.addRecipeToBook,
    T.listMealPlans,
    T.planMeal,
    T.groceryListFromRecipe,
    T.startCookMode,
    T.startTimer,
    T.cookingStatus,
    T.convertMeasurement,
    T.estimateNutrition,
    T.getPreferences,
  ]),
  mealPlan: new Set([
    T.listMealPlans,
    T.planMeal,
    T.removePlannedItem,
    T.searchRecipes,
    T.getRecipe,
    T.openRecipe,
    T.createGroceryList,
    T.listGroceryLists,
    T.convertMeasurement,
    T.estimateNutrition,
    T.getPreferences,
  ]),
  groceryList: new Set([
    T.getGroceryList,
    T.listGroceryLists,
    T.addGroceryItems,
    T.setGroceryItemChecked,
    T.removeGroceryItems,
    T.clearCheckedItems,
    T.convertMeasurement,
    T.getPreferences,
  ]),
};

const NOUN: Record<ScopeKind, string> = { recipe: "recipe", mealPlan: "meal plan", groceryList: "grocery list" };

/** The standing order that keeps the conversation on this item (promptSection). */
export function scopePromptSection(scope: AssistantScope, details: string, offTopicReply: string): string {
  const noun = NOUN[scope.kind];
  return `SCOPE LOCK (overrides everything above): this conversation is about ONE ${noun} only — "${scope.title}" (id: ${scope.id}). Here it is in full:
${details}

You answer questions about this ${noun} and perform actions on it (its tools are the only ones you have). Use id "${scope.id}" for it; never ask the user for an id. Anything that is not about this ${noun} — another recipe, list or plan, general cooking questions not tied to it, anything else — you do NOT answer, not even briefly; reply with exactly this sentence and nothing more: "${offTopicReply}". A question that uses this ${noun} as its subject (substitutions in it, scaling it, its nutrition, what to serve with it, when to cook it, what is still to buy on it) is in scope.`;
}
