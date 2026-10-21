import '../../../../core/constants/app_enums.dart';
import '../../../../core/translation/translated_merge.dart';
import '../../../my_recipes/domain/entities/recipe_entity.dart';
import '../../../my_recipes/domain/repositories/recipes_repository.dart';
import '../../../recipe_sharing/domain/repositories/recipe_sharing_repository.dart';
import '../../../recipe_sharing/domain/usecases/save_collab_recipe_usecase.dart';
import '../repositories/shared_recipes_repository.dart';

/// Brings a saved community recipe up to the author's latest version. The
/// local copy keeps its own id and its "saved from" mark; everything the
/// author can edit is replaced. Null when the post no longer exists — the
/// copy is then left as it was, which is all there is.
class RefreshSavedCopyUseCase {
  final SharedRecipesRepository shared;
  final RecipesRepository recipes;

  /// A copy that was shared on (it sits in a shared book, or was shared by
  /// itself) is the source of truth for the other members: with [sharing]
  /// the new version is written to its document too, through
  /// [SaveCollabRecipeUseCase]. Without it the copy is refreshed locally
  /// only, and the members keep the old version until the next edit.
  final RecipeSharingRepository? sharing;

  RefreshSavedCopyUseCase({
    required this.shared,
    required this.recipes,
    this.sharing,
  });

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
    // What the author can edit comes from the post; what belongs to this
    // copy stays. Rebuilt from scratch, a copy that sits in a shared book
    // (RecipeLinker shares it as a collab) lost its collab id — the next
    // book publish minted a second collab and members got a duplicate —
    // and a translated copy lost its language stamp.
    final merged = RecipeEntity(
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
      sourceChannel: local.sourceChannel,
      sourceUrl: local.sourceUrl,
      pendingAnalysis: local.pendingAnalysis,
      collabId: local.collabId,
      collabRole: local.collabRole,
      sharedRecipeId: local.sharedRecipeId,
      contentLang: local.contentLang,
      contentVersion: local.contentVersion,
    );
    final (recipe: updated, :keptTranslation) = keepTranslation(local, merged);
    // Shared on by this account (owner) or editable by it: the document
    // first, then the copy — a refused write leaves neither ahead. A viewer
    // only refreshes its own cache; the next sync lays the document back.
    if (sharing case final sharing?
        when updated.collabId != null &&
            updated.collabRole != CollabRole.viewer) {
      return SaveCollabRecipeUseCase(sharing: sharing, recipes: recipes)(
        updated,
        byUid: viewerUid,
        stampLanguage: !keptTranslation,
      );
    }
    await recipes.saveRecipe(updated, stampLanguage: !keptTranslation);
    return updated;
  }
}
