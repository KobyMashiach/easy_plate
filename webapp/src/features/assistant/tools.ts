// The function declarations Shefi may call, in the Interactions API's
// `tools` shape — field for field the app's AssistantTools
// (lib/features/assistant/domain/assistant_tools.dart). Names and schemas are
// the contract with the model; the web sends exactly what the phone sends.

export const T = {
  searchRecipes: "search_recipes",
  getRecipe: "get_recipe",
  createRecipe: "create_recipe",
  updateRecipe: "update_recipe",
  deleteRecipe: "delete_recipe",
  importRecipe: "import_recipe",
  searchWebRecipes: "search_web_recipes",
  openRecipe: "open_recipe",
  listBooks: "list_books",
  createBook: "create_book",
  addRecipeToBook: "add_recipe_to_book",
  listMealPlans: "list_meal_plans",
  createMealPlan: "create_meal_plan",
  planMeal: "plan_meal",
  removePlannedItem: "remove_planned_item",
  listGroceryLists: "list_grocery_lists",
  createGroceryList: "create_grocery_list",
  getGroceryList: "get_grocery_list",
  addGroceryItems: "add_grocery_items",
  setGroceryItemChecked: "set_grocery_item_checked",
  removeGroceryItems: "remove_grocery_items",
  clearCheckedItems: "clear_checked_items",
  groceryListFromRecipe: "create_grocery_list_from_recipe",
  startCookMode: "start_cook_mode",
  startTimer: "start_timer",
  cookingStatus: "cooking_status",
  convertMeasurement: "convert_measurement",
  estimateNutrition: "estimate_nutrition",
  getPreferences: "get_preferences",
  setShoppingDay: "set_shopping_day",
  setDietaryPreferences: "set_dietary_preferences",
  premiumStatus: "premium_status",
  openScreen: "open_screen",
  contactSupport: "contact_support",
} as const;

/** The screens `open_screen` may name; anything else is refused. */
export const SCREENS = ["recipes", "library", "meal_plan", "groceries", "community", "settings", "preferences", "premium", "notifications", "add_recipe"] as const;
export type Screen = (typeof SCREENS)[number];

const weekday = { type: "string", enum: ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"] };
const unit = { type: "string", enum: ["gram", "kilogram", "milliliter", "liter", "teaspoon", "tablespoon", "cup", "unit", "pinch", "unspecified"] };
const dietary = { type: "string", enum: ["meat", "dairy", "vegetarian", "vegan", "kosher", "glutenFree", "allergy"] };
const ingredient = {
  type: "object",
  properties: {
    name: { type: "string" },
    amount: { type: "number", description: "Omit when unknown" },
    unit,
  },
  required: ["name"],
};

export type Declaration = { type: "function"; name: string; description: string; parameters: Record<string, unknown> };

function tool(name: string, description: string, properties: Record<string, unknown>, required: string[] = []): Declaration {
  const parameters: Record<string, unknown> = { type: "object", properties };
  if (required.length) parameters.required = required;
  return { type: "function", name, description, parameters };
}

export const DECLARATIONS: Declaration[] = [
  tool(
    T.searchRecipes,
    "Search the user's own saved recipes by title, ingredient or dietary tag. Returns ids to use with other tools.",
    {
      query: { type: "string", description: "Free text; empty lists everything" },
      dietary: { type: "array", items: dietary },
      limit: { type: "integer" },
    },
  ),
  tool(T.getRecipe, "Full details of one saved recipe: ingredients with amounts, steps, times, nutrition.", { recipe_id: { type: "string" } }, ["recipe_id"]),
  tool(
    T.createRecipe,
    "Save a new recipe the user dictated or you composed. Use the user's language for all text.",
    {
      title: { type: "string" },
      ingredients: { type: "array", items: ingredient },
      steps: { type: "array", items: { type: "string" } },
      servings: { type: "integer" },
      prep_minutes: { type: "integer" },
      cook_minutes: { type: "integer" },
      dietary_tags: { type: "array", items: dietary },
    },
    ["title", "ingredients", "steps"],
  ),
  tool(
    T.updateRecipe,
    "Change a saved recipe: rename, change servings/times, add or remove ingredients, replace steps.",
    {
      recipe_id: { type: "string" },
      title: { type: "string" },
      servings: { type: "integer" },
      prep_minutes: { type: "integer" },
      cook_minutes: { type: "integer" },
      add_ingredients: { type: "array", items: ingredient },
      remove_ingredient_names: { type: "array", items: { type: "string" } },
      steps: { type: "array", items: { type: "string" }, description: "Replaces all steps when given" },
    },
    ["recipe_id"],
  ),
  tool(T.deleteRecipe, "Delete a saved recipe. The app asks the user to confirm.", { recipe_id: { type: "string" } }, ["recipe_id"]),
  tool(
    T.importRecipe,
    'Extract and save a recipe with AI from pasted text, a website link, a TikTok/Instagram/YouTube/Facebook video link, or a free request ("a quick lentil soup for 4"). Slow (up to 45 s); counts against the daily AI allowance.',
    {
      source: { type: "string", enum: ["text", "url", "social_video", "request"] },
      content: { type: "string", description: "The text, the link, or the request" },
    },
    ["source", "content"],
  ),
  tool(
    T.searchWebRecipes,
    "Search the web for recipes (3–5 results with links). Does not save anything; follow up with import_recipe on a chosen url.",
    { query: { type: "string" } },
    ["query"],
  ),
  tool(T.openRecipe, "Open a saved recipe on screen.", { recipe_id: { type: "string" } }, ["recipe_id"]),
  tool(T.listBooks, "List the user's recipe books with their recipe counts.", {}),
  tool(T.createBook, "Create a recipe book.", { title: { type: "string" } }, ["title"]),
  tool(T.addRecipeToBook, "Add a saved recipe to a book.", { recipe_id: { type: "string" }, book_id: { type: "string" } }, ["recipe_id", "book_id"]),
  tool(T.listMealPlans, "List weekly meal plans with what is planned on each day and meal.", { plan_id: { type: "string", description: "Only this plan" } }),
  tool(
    T.createMealPlan,
    "Create a weekly meal plan.",
    { name: { type: "string" }, template: { type: "string", enum: ["free", "threeMeals", "sixMeals"] } },
    ["name"],
  ),
  tool(
    T.planMeal,
    "Put a saved recipe (by id) or a free-text dish on a weekday and meal of a plan. Uses the most recent plan when plan_id is omitted, creating one if none exists. Meal names: breakfast, lunch, dinner, morningSnack, afternoonSnack, eveningSnack, or an existing custom meal name.",
    {
      plan_id: { type: "string" },
      weekday,
      meal: { type: "string" },
      recipe_id: { type: "string" },
      free_text: { type: "string" },
    },
    ["weekday", "meal"],
  ),
  tool(
    T.removePlannedItem,
    "Remove a planned dish from a plan (ids from list_meal_plans).",
    { plan_id: { type: "string" }, meal_id: { type: "string" }, item_id: { type: "string" } },
    ["plan_id", "meal_id", "item_id"],
  ),
  tool(T.listGroceryLists, "The user's grocery lists: id, name, item count, and which one is active.", {}),
  tool(
    T.createGroceryList,
    "Create an empty grocery list and make it active. Names are kept unique (a repeat gets a number).",
    { name: { type: "string" } },
    ["name"],
  ),
  tool(T.getGroceryList, "A grocery list (the active one when list_id is omitted): items, amounts, units, bought state.", { list_id: { type: "string" } }),
  tool(
    T.addGroceryItems,
    "Add items to a grocery list. With one list (or list_id given) it just adds, creating a list when there is none. With several lists and no list_id it returns the lists instead of guessing: ask the user which one, then call again with list_id. Merges into an existing item of the same name and unit.",
    {
      items: { type: "array", items: ingredient },
      list_id: { type: "string", description: "From list_grocery_lists" },
    },
    ["items"],
  ),
  tool(
    T.setGroceryItemChecked,
    "Mark grocery items as bought or not bought, by name (fuzzy) or id, on the active list unless list_id is given.",
    { items: { type: "array", items: { type: "string" } }, checked: { type: "boolean" }, list_id: { type: "string" } },
    ["items", "checked"],
  ),
  tool(
    T.removeGroceryItems,
    "Remove items from a grocery list (the active one unless list_id is given) by name or id.",
    { items: { type: "array", items: { type: "string" } }, list_id: { type: "string" } },
    ["items"],
  ),
  tool(T.clearCheckedItems, "Remove every bought item from a list (the active one unless list_id is given).", { list_id: { type: "string" } }),
  tool(
    T.groceryListFromRecipe,
    "Create a grocery list from one recipe's ingredients and make it the active list.",
    { recipe_id: { type: "string" }, scale: { type: "number", description: "Multiplier on the amounts; 1 = as written" } },
    ["recipe_id"],
  ),
  tool(
    T.startCookMode,
    "Open step-by-step cook mode for a saved recipe (Premium feature; the app handles the paywall).",
    { recipe_id: { type: "string" }, step: { type: "integer", description: "1-based step to open on" } },
    ["recipe_id"],
  ),
  tool(
    T.startTimer,
    "Start the timer of a recipe step that names a duration, without leaving the chat.",
    { recipe_id: { type: "string" }, step: { type: "integer", description: "1-based" } },
    ["recipe_id", "step"],
  ),
  tool(T.cookingStatus, "What is cooking now: recipes, steps and running timers.", {}),
  tool(T.getPreferences, "The user's shopping day, dietary preferences and language.", {}),
  tool(T.setShoppingDay, "Set the weekly shopping day.", { day: weekday }, ["day"]),
  tool(T.setDietaryPreferences, "Add or remove dietary preferences.", { add: { type: "array", items: dietary }, remove: { type: "array", items: dietary } }),
  tool(T.premiumStatus, "Whether the account has EasyPlate Premium and what is gated.", {}),
  tool(
    T.convertMeasurement,
    "Exact kitchen unit conversion (gram, kilogram, milliliter, liter, teaspoon, tablespoon, cup; also fahrenheit/celsius). Water-density for volume↔weight unless an ingredient with a known density is named (flour, sugar, butter, oil, honey, rice).",
    { amount: { type: "number" }, from: { type: "string" }, to: { type: "string" }, ingredient: { type: "string" } },
    ["amount", "from", "to"],
  ),
  tool(
    T.estimateNutrition,
    "Estimate calories, protein, carbs and fat per serving for a saved recipe with AI and store them on the recipe.",
    { recipe_id: { type: "string" } },
    ["recipe_id"],
  ),
  tool(
    T.contactSupport,
    "Send a message to the EasyPlate support team on the user's behalf: a bug report, a suggestion, or a question about their account, Premium, sharing or recipe import. Opens a support conversation the team answers in the app. Ask for the reason and the message if they are not clear; never send without the user's words.",
    {
      reason: { type: "string", enum: ["bug", "suggestion", "account", "billing", "sharing", "recipes", "other"] },
      message: { type: "string", description: "The user's message, in their own words" },
    },
    ["reason", "message"],
  ),
  tool(T.openScreen, "Navigate to a screen of the app.", { screen: { type: "string", enum: [...SCREENS] } }, ["screen"]),
];

/** The declarations a scoped conversation gets: only its item's tools, in declaration order. */
export function declarationsFor(names: ReadonlySet<string>): Declaration[] {
  return DECLARATIONS.filter((d) => names.has(d.name));
}
