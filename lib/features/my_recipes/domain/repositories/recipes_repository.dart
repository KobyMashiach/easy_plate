import '../entities/recipe_entity.dart';

abstract class RecipesRepository {
  Future<List<RecipeEntity>> getRecipes();
  Future<RecipeEntity?> getRecipeById(String id);
  Future<void> saveRecipe(RecipeEntity recipe);
  Future<void> deleteRecipe(String id);
}
