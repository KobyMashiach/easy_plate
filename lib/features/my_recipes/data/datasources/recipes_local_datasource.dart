import 'package:hive_ce/hive.dart';

import '../models/recipe_model.dart';

abstract class RecipesLocalDataSource {
  Future<List<RecipeModel>> getRecipes();
  Future<RecipeModel?> getRecipeById(String id);
  Future<void> saveRecipe(RecipeModel recipe);
  Future<void> deleteRecipe(String id);
}

class RecipesLocalDataSourceImpl implements RecipesLocalDataSource {
  @override
  Future<List<RecipeModel>> getRecipes() async {
    final box = await Hive.openBox<RecipeModel>(RecipeModel.hiveKey);
    return box.values.toList();
  }

  @override
  Future<RecipeModel?> getRecipeById(String id) async {
    final box = await Hive.openBox<RecipeModel>(RecipeModel.hiveKey);
    return box.get(id);
  }

  @override
  Future<void> saveRecipe(RecipeModel recipe) async {
    final box = await Hive.openBox<RecipeModel>(RecipeModel.hiveKey);
    await box.put(recipe.id, recipe);
  }

  @override
  Future<void> deleteRecipe(String id) async {
    final box = await Hive.openBox<RecipeModel>(RecipeModel.hiveKey);
    await box.delete(id);
  }
}
