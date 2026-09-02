import '../entities/recipe_entity.dart';
import '../repositories/recipes_repository.dart';

class SaveRecipeUseCase {
  final RecipesRepository repository;
  SaveRecipeUseCase(this.repository);

  Future<void> call(RecipeEntity recipe) => repository.saveRecipe(recipe);
}
