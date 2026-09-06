import 'package:uuid/uuid.dart';

import '../../../my_recipes/domain/entities/recipe_entity.dart';
import '../../../my_recipes/domain/repositories/recipes_repository.dart';
import '../entities/shared_recipe_entity.dart';

enum ImportOutcome { saved, alreadySaved }

/// Saves a community recipe into My Recipes as the user's own copy — a fresh
/// id, stamped with where it came from — and refuses to make a second copy of
/// the same one. Used by the feed and by a recipe link inside a forum reply.
class ImportSharedRecipeUseCase {
  final RecipesRepository recipes;
  static const _uuid = Uuid();

  ImportSharedRecipeUseCase(this.recipes);

  Future<ImportOutcome> call(SharedRecipeEntity shared) async {
    final existing = await recipes.getRecipes();
    if (existing.any((r) => r.savedFromSharedId == shared.id)) {
      return ImportOutcome.alreadySaved;
    }

    final source = shared.recipe;
    await recipes.saveRecipe(RecipeEntity(
      id: _uuid.v4(),
      title: source.title,
      prepTimeMinutes: source.prepTimeMinutes,
      cookTimeMinutes: source.cookTimeMinutes,
      ingredients: source.ingredients,
      steps: source.steps,
      dietaryTags: source.dietaryTags,
      savedFromSharedId: shared.id,
      createdAt: DateTime.now(),
    ));
    return ImportOutcome.saved;
  }
}
