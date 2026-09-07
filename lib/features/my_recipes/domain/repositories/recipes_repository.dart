import '../entities/recipe_entity.dart';

abstract class RecipesRepository {
  Future<List<RecipeEntity>> getRecipes();

  /// The list, kept current as recipes are saved from anywhere in the app.
  Stream<List<RecipeEntity>> watchRecipes();
  Future<RecipeEntity?> getRecipeById(String id);
  Future<void> saveRecipe(RecipeEntity recipe);
  Future<void> deleteRecipe(String id);

  /// The recipe with its photo guaranteed uploaded, for the paths that publish
  /// it to someone else.
  ///
  /// [saveRecipe] uploads in the background so the editor never waits on a
  /// picture. Sharing cannot use that: a recipe published in the seconds after
  /// its photo was picked would go out with no image path, and the copy the
  /// other side keeps would stay pictureless for good. Returns the recipe
  /// unchanged when there is nothing to upload or the upload failed.
  Future<RecipeEntity> readyForSharing(RecipeEntity recipe);
}
