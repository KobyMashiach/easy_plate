import '../entities/recipe_entity.dart';

abstract class RecipesRepository {
  Future<List<RecipeEntity>> getRecipes();

  /// The list, kept current as recipes are saved from anywhere in the app.
  Stream<List<RecipeEntity>> watchRecipes();
  Future<RecipeEntity?> getRecipeById(String id);
  Future<void> saveRecipe(RecipeEntity recipe);
  Future<void> deleteRecipe(String id);
}
