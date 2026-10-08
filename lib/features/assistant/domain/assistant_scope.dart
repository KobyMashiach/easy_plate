import 'assistant_tools.dart';

/// What a scoped conversation is about: the assistant opened from inside a
/// recipe, a meal plan or a grocery list knows that one item in full and
/// answers about nothing else.
enum AssistantScopeKind { recipe, mealPlan, groceryList }

class AssistantScope {
  final AssistantScopeKind kind;
  final String id;
  final String title;

  const AssistantScope({
    required this.kind,
    required this.id,
    required this.title,
  });

  const AssistantScope.recipe({required this.id, required this.title})
    : kind = AssistantScopeKind.recipe;
  const AssistantScope.mealPlan({required this.id, required this.title})
    : kind = AssistantScopeKind.mealPlan;
  const AssistantScope.groceryList({required this.id, required this.title})
    : kind = AssistantScopeKind.groceryList;

  /// The tools that act on, or read, this one item. Everything else stays
  /// out of the model's reach, so it cannot wander off even if asked.
  Set<String> get toolNames => switch (kind) {
    AssistantScopeKind.recipe => {
      AssistantTools.getRecipe,
      AssistantTools.updateRecipe,
      AssistantTools.openRecipe,
      AssistantTools.listBooks,
      AssistantTools.addRecipeToBook,
      AssistantTools.listMealPlans,
      AssistantTools.planMeal,
      AssistantTools.groceryListFromRecipe,
      AssistantTools.startCookMode,
      AssistantTools.startTimer,
      AssistantTools.cookingStatus,
      AssistantTools.convertMeasurement,
      AssistantTools.estimateNutrition,
      AssistantTools.getPreferences,
    },
    AssistantScopeKind.mealPlan => {
      AssistantTools.listMealPlans,
      AssistantTools.planMeal,
      AssistantTools.removePlannedItem,
      AssistantTools.searchRecipes,
      AssistantTools.getRecipe,
      AssistantTools.openRecipe,
      AssistantTools.createGroceryList,
      AssistantTools.listGroceryLists,
      AssistantTools.convertMeasurement,
      AssistantTools.estimateNutrition,
      AssistantTools.getPreferences,
    },
    AssistantScopeKind.groceryList => {
      AssistantTools.getGroceryList,
      AssistantTools.listGroceryLists,
      AssistantTools.addGroceryItems,
      AssistantTools.setGroceryItemChecked,
      AssistantTools.removeGroceryItems,
      AssistantTools.clearCheckedItems,
      AssistantTools.convertMeasurement,
      AssistantTools.getPreferences,
    },
  };

  /// The word the prompt uses for the item.
  String get noun => switch (kind) {
    AssistantScopeKind.recipe => 'recipe',
    AssistantScopeKind.mealPlan => 'meal plan',
    AssistantScopeKind.groceryList => 'grocery list',
  };

  /// The standing order that keeps the conversation on this item. [details]
  /// is the dispatcher's full description of it, so the model never has to
  /// look it up and never confuses it with another.
  String promptSection({
    required String details,
    required String offTopicReply,
  }) =>
      '''
SCOPE LOCK (overrides everything above): this conversation is about ONE $noun only — "$title" (id: $id). Here it is in full:
$details

You answer questions about this $noun and perform actions on it (its tools are the only ones you have). Use id "$id" for it; never ask the user for an id. Anything that is not about this $noun — another recipe, list or plan, general cooking questions not tied to it, anything else — you do NOT answer, not even briefly; reply with exactly this sentence and nothing more: "$offTopicReply". A question that uses this $noun as its subject (substitutions in it, scaling it, its nutrition, what to serve with it, when to cook it, what is still to buy on it) is in scope.''';
}
