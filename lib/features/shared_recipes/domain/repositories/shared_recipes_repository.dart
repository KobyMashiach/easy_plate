import '../../../my_recipes/domain/entities/recipe_entity.dart';
import '../entities/shared_recipe_entity.dart';

abstract class SharedRecipesRepository {
  /// Newest first. [viewerUid] resolves each entry's `likedByMe`.
  Future<List<SharedRecipeEntity>> getFeed({required String viewerUid, int limit = 50});

  Future<void> share(
    RecipeEntity recipe, {
    required String authorUid,
    required String authorName,
    String? authorPhotoUrl,
  });

  /// Returns the new like state. Idempotent per user — liking twice is one like.
  Future<bool> toggleLike(String sharedRecipeId, {required String viewerUid});

  /// Only the author may remove their own post; the rules enforce it too.
  Future<void> unshare(String sharedRecipeId);
}
