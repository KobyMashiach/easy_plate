/// The function declarations the model can call, in the Interactions API's
/// `tools` shape. Every one maps onto a real repository or use case through
/// [AssistantDispatcher]; names are stable identifiers, not UI strings.
abstract class AssistantTools {
  // Recipes
  static const searchRecipes = 'search_recipes';
  static const getRecipe = 'get_recipe';
  static const createRecipe = 'create_recipe';
  static const updateRecipe = 'update_recipe';
  static const deleteRecipe = 'delete_recipe';
  static const importRecipe = 'import_recipe';
  static const searchWebRecipes = 'search_web_recipes';
  static const openRecipe = 'open_recipe';
  // Books
  static const listBooks = 'list_books';
  static const createBook = 'create_book';
  static const addRecipeToBook = 'add_recipe_to_book';
  // Meal plans
  static const listMealPlans = 'list_meal_plans';
  static const createMealPlan = 'create_meal_plan';
  static const planMeal = 'plan_meal';
  static const removePlannedItem = 'remove_planned_item';
  // Groceries
  static const listGroceryLists = 'list_grocery_lists';
  static const createGroceryList = 'create_grocery_list';
  static const getGroceryList = 'get_grocery_list';
  static const addGroceryItems = 'add_grocery_items';
  static const setGroceryItemChecked = 'set_grocery_item_checked';
  static const removeGroceryItems = 'remove_grocery_items';
  static const clearCheckedItems = 'clear_checked_items';
  static const groceryListFromRecipe = 'create_grocery_list_from_recipe';
  // Cooking
  static const startCookMode = 'start_cook_mode';
  static const startTimer = 'start_timer';
  static const cookingStatus = 'cooking_status';
  // Knowledge helpers
  static const convertMeasurement = 'convert_measurement';
  static const estimateNutrition = 'estimate_nutrition';
  // Account
  static const getPreferences = 'get_preferences';
  static const setShoppingDay = 'set_shopping_day';
  static const setDietaryPreferences = 'set_dietary_preferences';
  static const premiumStatus = 'premium_status';
  // Navigation
  static const openScreen = 'open_screen';

  static const _weekday = {
    'type': 'string',
    'enum': [
      'sunday',
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
    ],
  };

  static const _unit = {
    'type': 'string',
    'enum': [
      'gram',
      'kilogram',
      'milliliter',
      'liter',
      'teaspoon',
      'tablespoon',
      'cup',
      'unit',
      'pinch',
      'unspecified',
    ],
  };

  static const _dietary = {
    'type': 'string',
    'enum': [
      'meat',
      'dairy',
      'vegetarian',
      'vegan',
      'kosher',
      'glutenFree',
      'allergy',
    ],
  };

  static const _ingredient = {
    'type': 'object',
    'properties': {
      'name': {'type': 'string'},
      'amount': {'type': 'number', 'description': 'Omit when unknown'},
      'unit': _unit,
    },
    'required': ['name'],
  };

  static Map<String, dynamic> _tool(
    String name,
    String description,
    Map<String, dynamic> properties, {
    List<String> required = const [],
  }) => {
    'type': 'function',
    'name': name,
    'description': description,
    'parameters': {
      'type': 'object',
      'properties': properties,
      if (required.isNotEmpty) 'required': required,
    },
  };

  /// The declarations a scoped conversation gets: only the tools that act
  /// on its one item (see AssistantScope.toolNames).
  static List<Map<String, dynamic>> declarationsFor(Set<String> names) => [
    for (final d in declarations)
      if (names.contains(d['name'])) d,
  ];

  static final List<Map<String, dynamic>> declarations = [
    _tool(
      searchRecipes,
      "Search the user's own saved recipes by title, ingredient or dietary tag. Returns ids to use with other tools.",
      {
        'query': {
          'type': 'string',
          'description': 'Free text; empty lists everything',
        },
        'dietary': {'type': 'array', 'items': _dietary},
        'limit': {'type': 'integer'},
      },
    ),
    _tool(
      getRecipe,
      'Full details of one saved recipe: ingredients with amounts, steps, times, nutrition.',
      {
        'recipe_id': {'type': 'string'},
      },
      required: ['recipe_id'],
    ),
    _tool(
      createRecipe,
      'Save a new recipe the user dictated or you composed. Use the user\'s language for all text.',
      {
        'title': {'type': 'string'},
        'ingredients': {'type': 'array', 'items': _ingredient},
        'steps': {
          'type': 'array',
          'items': {'type': 'string'},
        },
        'servings': {'type': 'integer'},
        'prep_minutes': {'type': 'integer'},
        'cook_minutes': {'type': 'integer'},
        'dietary_tags': {'type': 'array', 'items': _dietary},
      },
      required: ['title', 'ingredients', 'steps'],
    ),
    _tool(
      updateRecipe,
      'Change a saved recipe: rename, change servings/times, add or remove ingredients, replace steps.',
      {
        'recipe_id': {'type': 'string'},
        'title': {'type': 'string'},
        'servings': {'type': 'integer'},
        'prep_minutes': {'type': 'integer'},
        'cook_minutes': {'type': 'integer'},
        'add_ingredients': {'type': 'array', 'items': _ingredient},
        'remove_ingredient_names': {
          'type': 'array',
          'items': {'type': 'string'},
        },
        'steps': {
          'type': 'array',
          'items': {'type': 'string'},
          'description': 'Replaces all steps when given',
        },
      },
      required: ['recipe_id'],
    ),
    _tool(
      deleteRecipe,
      'Delete a saved recipe. The app asks the user to confirm.',
      {
        'recipe_id': {'type': 'string'},
      },
      required: ['recipe_id'],
    ),
    _tool(
      importRecipe,
      'Extract and save a recipe with AI from pasted text, a website link, a TikTok/Instagram/YouTube/Facebook video link, or a free request ("a quick lentil soup for 4"). Slow (up to 45 s); counts against the daily AI allowance.',
      {
        'source': {
          'type': 'string',
          'enum': ['text', 'url', 'social_video', 'request'],
        },
        'content': {
          'type': 'string',
          'description': 'The text, the link, or the request',
        },
      },
      required: ['source', 'content'],
    ),
    _tool(
      searchWebRecipes,
      'Search the web for recipes (3–5 results with links). Does not save anything; follow up with import_recipe on a chosen url.',
      {
        'query': {'type': 'string'},
      },
      required: ['query'],
    ),
    _tool(
      openRecipe,
      'Open a saved recipe on screen.',
      {
        'recipe_id': {'type': 'string'},
      },
      required: ['recipe_id'],
    ),
    _tool(
      listBooks,
      "List the user's recipe books with their recipe counts.",
      {},
    ),
    _tool(
      createBook,
      'Create a recipe book.',
      {
        'title': {'type': 'string'},
      },
      required: ['title'],
    ),
    _tool(
      addRecipeToBook,
      'Add a saved recipe to a book.',
      {
        'recipe_id': {'type': 'string'},
        'book_id': {'type': 'string'},
      },
      required: ['recipe_id', 'book_id'],
    ),
    _tool(
      listMealPlans,
      'List weekly meal plans with what is planned on each day and meal.',
      {
        'plan_id': {'type': 'string', 'description': 'Only this plan'},
      },
    ),
    _tool(
      createMealPlan,
      'Create a weekly meal plan.',
      {
        'name': {'type': 'string'},
        'template': {
          'type': 'string',
          'enum': ['free', 'threeMeals', 'sixMeals'],
        },
      },
      required: ['name'],
    ),
    _tool(
      planMeal,
      'Put a saved recipe (by id) or a free-text dish on a weekday and meal of a plan. Uses the most recent plan when plan_id is omitted, creating one if none exists. Meal names: breakfast, lunch, dinner, morningSnack, afternoonSnack, eveningSnack, or an existing custom meal name.',
      {
        'plan_id': {'type': 'string'},
        'weekday': _weekday,
        'meal': {'type': 'string'},
        'recipe_id': {'type': 'string'},
        'free_text': {'type': 'string'},
      },
      required: ['weekday', 'meal'],
    ),
    _tool(
      removePlannedItem,
      'Remove a planned dish from a plan (ids from list_meal_plans).',
      {
        'plan_id': {'type': 'string'},
        'meal_id': {'type': 'string'},
        'item_id': {'type': 'string'},
      },
      required: ['plan_id', 'meal_id', 'item_id'],
    ),
    _tool(
      listGroceryLists,
      "The user's grocery lists: id, name, item count, and which one is active.",
      {},
    ),
    _tool(
      createGroceryList,
      'Create an empty grocery list and make it active. Names are kept unique (a repeat gets a number).',
      {
        'name': {'type': 'string'},
      },
      required: ['name'],
    ),
    _tool(
      getGroceryList,
      'A grocery list (the active one when list_id is omitted): items, amounts, units, bought state.',
      {
        'list_id': {'type': 'string'},
      },
    ),
    _tool(
      addGroceryItems,
      'Add items to a grocery list. With one list (or list_id given) it just adds, creating a list when there is none. With several lists and no list_id it returns the lists instead of guessing: ask the user which one, then call again with list_id. Merges into an existing item of the same name and unit.',
      {
        'items': {'type': 'array', 'items': _ingredient},
        'list_id': {'type': 'string', 'description': 'From list_grocery_lists'},
      },
      required: ['items'],
    ),
    _tool(
      setGroceryItemChecked,
      'Mark grocery items as bought or not bought, by name (fuzzy) or id, on the active list unless list_id is given.',
      {
        'items': {
          'type': 'array',
          'items': {'type': 'string'},
        },
        'checked': {'type': 'boolean'},
        'list_id': {'type': 'string'},
      },
      required: ['items', 'checked'],
    ),
    _tool(
      removeGroceryItems,
      'Remove items from a grocery list (the active one unless list_id is given) by name or id.',
      {
        'items': {
          'type': 'array',
          'items': {'type': 'string'},
        },
        'list_id': {'type': 'string'},
      },
      required: ['items'],
    ),
    _tool(
      clearCheckedItems,
      'Remove every bought item from a list (the active one unless list_id is given).',
      {
        'list_id': {'type': 'string'},
      },
    ),
    _tool(
      groceryListFromRecipe,
      'Create a grocery list from one recipe\'s ingredients and make it the active list.',
      {
        'recipe_id': {'type': 'string'},
        'scale': {
          'type': 'number',
          'description': 'Multiplier on the amounts; 1 = as written',
        },
      },
      required: ['recipe_id'],
    ),
    _tool(
      startCookMode,
      'Open step-by-step cook mode for a saved recipe (Premium feature; the app handles the paywall).',
      {
        'recipe_id': {'type': 'string'},
        'step': {
          'type': 'integer',
          'description': '1-based step to open on',
        },
      },
      required: ['recipe_id'],
    ),
    _tool(
      startTimer,
      "Start the timer of a recipe step that names a duration, without leaving the chat.",
      {
        'recipe_id': {'type': 'string'},
        'step': {'type': 'integer', 'description': '1-based'},
      },
      required: ['recipe_id', 'step'],
    ),
    _tool(
      cookingStatus,
      'What is cooking now: recipes, steps and running timers.',
      {},
    ),
    _tool(
      getPreferences,
      "The user's shopping day, dietary preferences and language.",
      {},
    ),
    _tool(
      setShoppingDay,
      'Set the weekly shopping day.',
      {'day': _weekday},
      required: ['day'],
    ),
    _tool(
      setDietaryPreferences,
      'Add or remove dietary preferences.',
      {
        'add': {'type': 'array', 'items': _dietary},
        'remove': {'type': 'array', 'items': _dietary},
      },
    ),
    _tool(
      premiumStatus,
      'Whether the account has EasyPlate Premium and what is gated.',
      {},
    ),
    _tool(
      convertMeasurement,
      'Exact kitchen unit conversion (gram, kilogram, milliliter, liter, teaspoon, tablespoon, cup; also fahrenheit/celsius). Water-density for volume↔weight unless an ingredient with a known density is named (flour, sugar, butter, oil, honey, rice).',
      {
        'amount': {'type': 'number'},
        'from': {'type': 'string'},
        'to': {'type': 'string'},
        'ingredient': {'type': 'string'},
      },
      required: ['amount', 'from', 'to'],
    ),
    _tool(
      estimateNutrition,
      'Estimate calories, protein, carbs and fat per serving for a saved recipe with AI and store them on the recipe.',
      {
        'recipe_id': {'type': 'string'},
      },
      required: ['recipe_id'],
    ),
    _tool(
      openScreen,
      'Navigate to a screen of the app.',
      {
        'screen': {
          'type': 'string',
          'enum': [
            'recipes',
            'library',
            'meal_plan',
            'groceries',
            'community',
            'settings',
            'preferences',
            'premium',
            'notifications',
            'add_recipe',
          ],
        },
      },
      required: ['screen'],
    ),
  ];
}
