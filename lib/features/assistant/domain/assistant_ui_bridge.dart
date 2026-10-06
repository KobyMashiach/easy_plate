import '../../my_recipes/domain/entities/recipe_entity.dart';

/// The few things a tool needs from the screen it runs on: a confirmation,
/// the AI allowance gate (which shows a sheet), and navigation. The chat
/// page implements it; the dispatcher never touches a BuildContext.
abstract class AssistantUiBridge {
  /// A destructive action: true when the user agreed.
  Future<bool> confirmDelete(String what);

  /// The daily AI-extraction allowance (free / rewarded video / blocked).
  Future<bool> allowAiExtraction();

  void openRecipe(RecipeEntity recipe);

  void openCookMode(RecipeEntity recipe);

  /// One of the `open_screen` tool's screen names.
  void openScreen(String screen);
}
