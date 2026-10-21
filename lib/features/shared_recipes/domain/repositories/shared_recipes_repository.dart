import '../../../my_recipes/domain/entities/recipe_entity.dart';
import '../entities/shared_recipe_entity.dart';

abstract class SharedRecipesRepository {
  /// Newest first. [viewerUid] resolves each entry's `likedByMe`.
  /// [refresh] (pull to refresh) reads likes and author profiles past their
  /// caches, so another device's like or a rename shows up at once.
  Future<List<SharedRecipeEntity>> getFeed({
    required String viewerUid,
    int limit = 50,
    bool refresh = false,
  });

  /// Null when the recipe has been unshared — a forum reply can outlive the
  /// recipe it links to.
  Future<SharedRecipeEntity?> getById(String id, {required String viewerUid});

  /// The posts [authorUid] published, newest first, without the viewer's
  /// like resolved (`likedByMe` reads false). For matching a local recipe
  /// to its post, which needs the titles and nothing else; the feed read
  /// this replaced cost a like lookup per post on top.
  Future<List<SharedRecipeEntity>> getByAuthor(
    String authorUid, {
    int limit = 200,
  });

  /// The viewer's own posts, `likedByMe` resolved, in no particular order:
  /// the "mine" scope reaches past the newest-first feed window with these.
  Future<List<SharedRecipeEntity>> getMine({
    required String viewerUid,
    int limit = 200,
    bool refresh = false,
  });

  /// The posts among [ids] that still exist, in no particular order: the
  /// "saved" scope's posts older than the feed window.
  Future<List<SharedRecipeEntity>> getByIds(
    Set<String> ids, {
    required String viewerUid,
    bool refresh = false,
  });

  /// Publishes [recipe]; resolves with the new post's id.
  Future<String> share(
    RecipeEntity recipe, {
    required String authorUid,
    required String authorName,
    String? authorPhotoUrl,
  });

  /// Returns the new like state. Idempotent per user — liking twice is one like.
  Future<bool> toggleLike(String sharedRecipeId, {required String viewerUid});

  /// Replaces the published recipe's content. Author only — enforced by the
  /// rules, not just the UI.
  Future<void> updateShared(String sharedRecipeId, RecipeEntity recipe);

  /// Only the author may remove their own post; the rules enforce it too.
  Future<void> unshare(String sharedRecipeId);
}
