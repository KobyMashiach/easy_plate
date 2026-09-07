import '../../../my_recipes/domain/entities/recipe_entity.dart';
import '../../../my_recipes/domain/repositories/recipes_repository.dart';
import '../repositories/shared_recipes_repository.dart';

class UpdateSharedRecipeUseCase {
  final SharedRecipesRepository repository;

  /// A photo added to the recipe after it was posted has to reach Storage
  /// before the post is rewritten to point at it.
  final RecipesRepository recipes;

  UpdateSharedRecipeUseCase(this.repository, this.recipes);

  Future<void> call(String sharedRecipeId, RecipeEntity recipe) async {
    final ready = await recipes.readyForSharing(recipe);
    return repository.updateShared(sharedRecipeId, ready);
  }
}
