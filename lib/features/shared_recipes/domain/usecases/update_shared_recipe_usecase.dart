import '../../../my_recipes/domain/entities/recipe_entity.dart';
import '../repositories/shared_recipes_repository.dart';

class UpdateSharedRecipeUseCase {
  final SharedRecipesRepository repository;
  UpdateSharedRecipeUseCase(this.repository);

  Future<void> call(String sharedRecipeId, RecipeEntity recipe) =>
      repository.updateShared(sharedRecipeId, recipe);
}
