import '../../../my_recipes/domain/entities/recipe_entity.dart';
import '../../../my_recipes/domain/repositories/recipes_repository.dart';
import '../entities/collab_recipe_entity.dart';
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
      final orphaned = orphan(local);
      await recipes.saveRecipe(orphaned);
      return orphaned;
    }

    final refreshed = merged(local, collab, uid: uid);
    await recipes.saveRecipe(refreshed);
    return refreshed;
  }

  /// The same recipe with every trace of sharing dropped. Reached only from a
  /// direct document read that came back empty — a bulk pass must not conclude
  /// this from a query, which answers from cache when offline.
  static RecipeEntity orphan(RecipeEntity local) => RecipeEntity(
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
        imageStoragePath: local.imageStoragePath,
        savedFromSharedId: local.savedFromSharedId,
        pendingAnalysis: local.pendingAnalysis,
        createdAt: local.createdAt,
      );

  /// The shared document laid over the local cache, keeping what belongs to
  /// this copy: its own id, where it came from, and when it was created here.
  ///
  /// Pure, and shared with [RefreshCollabRecipesUseCase] so the one-recipe and
  /// the all-recipes paths cannot drift apart.
  static RecipeEntity merged(
    RecipeEntity local,
    CollabRecipeEntity collab, {
    required String uid,
  }) =>
      RecipeEntity(
        id: local.id,
        title: collab.recipe.title,
        prepTimeMinutes: collab.recipe.prepTimeMinutes,
        cookTimeMinutes: collab.recipe.cookTimeMinutes,
        ingredients: collab.recipe.ingredients,
        steps: collab.recipe.steps,
        dietaryTags: collab.recipe.dietaryTags,
        sourceChannel: local.sourceChannel,
        sourceUrl: local.sourceUrl,
        // The photo is part of what is shared now. The shared document wins when
        // it has one — it is the source of truth, and the owner may have changed
        // the picture since — but a recipe shared without a photo does not wipe
        // one this account set on its own copy.
        imageFileName: collab.recipe.imageStoragePath != null
            ? collab.recipe.imageFileName
            : local.imageFileName,
        imageStoragePath: collab.recipe.imageStoragePath ?? local.imageStoragePath,
        savedFromSharedId: local.savedFromSharedId,
        collabId: collab.id,
        // The role the document says, not the one cached at accept time — the
        // owner may have changed it since.
        collabRole: collab.roleOf(uid),
        createdAt: local.createdAt,
      );
}
