import '../../../../core/hive/user_scope.dart';

import '../models/recipe_model.dart';

abstract class RecipesLocalDataSource {
  Future<List<RecipeModel>> getRecipes();

  /// Emits the current contents, then again after every write. Saves happen
  /// from screens that are not the list (ingestion, the editor, importing
  /// from the community), and the list lives in an IndexedStack that never
  /// rebuilds on its own — polling it on navigation missed those.
  Stream<List<RecipeModel>> watchRecipes();
  Future<RecipeModel?> getRecipeById(String id);
  Future<void> saveRecipe(RecipeModel recipe);
  Future<void> deleteRecipe(String id);
}

class RecipesLocalDataSourceImpl implements RecipesLocalDataSource {
  @override
  Future<List<RecipeModel>> getRecipes() async {
    final box = await UserScope().open<RecipeModel>(RecipeModel.hiveKey);
    return box.values.toList();
  }

  @override
  Stream<List<RecipeModel>> watchRecipes() async* {
    final box = await UserScope().open<RecipeModel>(RecipeModel.hiveKey);
    yield box.values.toList();
    yield* box.watch().map((_) => box.values.toList());
  }

  @override
  Future<RecipeModel?> getRecipeById(String id) async {
    final box = await UserScope().open<RecipeModel>(RecipeModel.hiveKey);
    return box.get(id);
  }

  @override
  Future<void> saveRecipe(RecipeModel recipe) async {
    final box = await UserScope().open<RecipeModel>(RecipeModel.hiveKey);
    await box.put(recipe.id, recipe);
  }

  @override
  Future<void> deleteRecipe(String id) async {
    final box = await UserScope().open<RecipeModel>(RecipeModel.hiveKey);
    await box.delete(id);
  }
}
