import '../../../my_recipes/domain/entities/recipe_entity.dart';
import '../../../my_recipes/domain/repositories/recipes_repository.dart';
import '../repositories/shared_recipes_repository.dart';

/// Brings a saved community recipe up to the author's latest version. The
/// local copy keeps its own id and its "saved from" mark; everything the
/// author can edit is replaced. Null when the post no longer exists — the
/// copy is then left as it was, which is all there is.
class RefreshSavedCopyUseCase {
  final SharedRecipesRepository shared;
  final RecipesRepository recipes;

  RefreshSavedCopyUseCase({required this.shared, required this.recipes});

  Future<RecipeEntity?> call(
    String sharedId, {
    required String viewerUid,
  }) async {
    final post = await shared.getById(sharedId, viewerUid: viewerUid);
    if (post == null) return null;
    final local = (await recipes.getRecipes())
        .where((r) => r.savedFromSharedId == sharedId)
        .firstOrNull;
    if (local == null) return null;

    final source = post.recipe;
    final updated = RecipeEntity(
      id: local.id,
      title: source.title,
      prepTimeMinutes: source.prepTimeMinutes,
      cookTimeMinutes: source.cookTimeMinutes,
      ingredients: source.ingredients,
      steps: source.steps,
      dietaryTags: source.dietaryTags,
      allergens: source.allergens,
      mayContain: source.mayContain,
      imageFileName: source.imageFileName,
      imageStoragePath: source.imageStoragePath,
      servings: source.servings,
      nutrition: source.nutrition,
      savedFromSharedId: sharedId,
      createdAt: local.createdAt,
    );
    await recipes.saveRecipe(updated);
    return updated;
  }
}
