import '../../../my_recipes/domain/entities/recipe_entity.dart';
import '../../../my_recipes/domain/repositories/recipes_repository.dart';
import '../repositories/recipe_sharing_repository.dart';

/// Refreshes a local cache of a shared recipe from its source of truth.
///
/// Returns the recipe to show: the remote version, saved locally, when the
/// document still exists; the local copy as-is when the fetch fails (offline);
/// and the local copy with sharing cleared when the owner deleted the shared
/// document — it becomes an ordinary private recipe rather than vanishing.
class SyncCollabRecipeUseCase {
  final RecipeSharingRepository sharing;
  final RecipesRepository recipes;

  SyncCollabRecipeUseCase({required this.sharing, required this.recipes});

  Future<RecipeEntity> call(RecipeEntity local, {required String uid}) async {
    final collabId = local.collabId;
    if (collabId == null) return local;

    final collab = await sharing.getCollab(collabId);
    if (collab == null) {
      final orphaned = RecipeEntity(
        id: local.id,
        title: local.title,
        prepTimeMinutes: local.prepTimeMinutes,
        cookTimeMinutes: local.cookTimeMinutes,
        ingredients: local.ingredients,
        steps: local.steps,
        dietaryTags: local.dietaryTags,
        sourceChannel: local.sourceChannel,
        sourceUrl: local.sourceUrl,
        imageFileName: local.imageFileName,
        savedFromSharedId: local.savedFromSharedId,
        pendingAnalysis: local.pendingAnalysis,
        createdAt: local.createdAt,
      );
      await recipes.saveRecipe(orphaned);
      return orphaned;
    }

    final refreshed = RecipeEntity(
      id: local.id,
      title: collab.recipe.title,
      prepTimeMinutes: collab.recipe.prepTimeMinutes,
      cookTimeMinutes: collab.recipe.cookTimeMinutes,
      ingredients: collab.recipe.ingredients,
      steps: collab.recipe.steps,
      dietaryTags: collab.recipe.dietaryTags,
      sourceChannel: local.sourceChannel,
      sourceUrl: local.sourceUrl,
      // The photo is device-local and not part of what is shared.
      imageFileName: local.imageFileName,
      savedFromSharedId: local.savedFromSharedId,
      collabId: collab.id,
      // The role the document says, not the one cached at accept time — the
      // owner may have changed it since.
      collabRole: collab.roleOf(uid),
      createdAt: local.createdAt,
    );
    await recipes.saveRecipe(refreshed);
    return refreshed;
  }
}
