import '../../../my_recipes/domain/entities/recipe_entity.dart';
import '../../../my_recipes/domain/repositories/recipes_repository.dart';
import '../repositories/shared_recipes_repository.dart';
import '../shared_feed_changes.dart';

class UpdateSharedRecipeUseCase {
  final SharedRecipesRepository repository;

  /// A photo added to the recipe after it was posted has to reach Storage
  /// before the post is rewritten to point at it.
  final RecipesRepository recipes;

  UpdateSharedRecipeUseCase(this.repository, this.recipes);

  /// [persist] false when [recipe] *is* the post (edited from the feed or
  /// the post's own details page) rather than a local recipe.
  Future<void> call(
    String sharedRecipeId,
    RecipeEntity recipe, {
    bool persist = true,
  }) async {
    final ready = await recipes.readyForSharing(recipe, persist: persist);
    await repository.updateShared(sharedRecipeId, ready);
    SharedFeedChanges.instance.notify(sharedRecipeId);
  }
}
