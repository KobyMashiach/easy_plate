import 'package:flutter/foundation.dart';

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

/// How the copilot is opened from outside its own screen — a home-screen
/// widget: locked to [scope] or not, saying [prompt] first, and with the
/// microphone already open when [voice] is set.
class AssistantLaunch {
  final AssistantScope? scope;
  final String? prompt;
  final bool voice;

  /// The prompt was said out loud ("Hey Shefi, what's for dinner?"), so it
  /// is a spoken turn: the reply is read out and the conversation goes on
  /// by voice. A widget's quick question stays a typed one.
  final bool spokenPrompt;

  /// Whether [prompt] goes out on its own. Off by default: a prompt that
  /// came in through `easyplate://open/widget/assistant?prompt=…` may have
  /// been written by any app or web page, and sent unseen it would have
  /// the copilot act on this account (clear a list, spend the AI quota).
  /// Such a prompt is put in the input field and the user sends it.
  final bool autoSend;

  const AssistantLaunch({
    this.scope,
    this.prompt,
    this.voice = false,
    this.spokenPrompt = false,
    this.autoSend = false,
  });

  /// A launch from a home-screen widget, the launcher or "Hey Shefi" — all
  /// of which arrive as the same link any other app can open. Only Android
  /// vouches for the prompt: its native side drops a `prompt` that lacks
  /// the per-install token only the app's own widgets and wake-word service
  /// hold (WidgetIntents.kt). iOS cannot tell its callers apart, so there
  /// the prompt waits in the field — and the microphone is not opened on
  /// its own either (`voice=1` from a web page would otherwise start
  /// listening unasked); the user taps the mic.
  factory AssistantLaunch.external({
    String? prompt,
    bool voice = false,
    bool spokenPrompt = false,
    required TargetPlatform platform,
  }) => AssistantLaunch(
    prompt: prompt,
    voice: voice && platform == TargetPlatform.android,
    spokenPrompt: spokenPrompt,
    autoSend: platform == TargetPlatform.android,
  );
}
