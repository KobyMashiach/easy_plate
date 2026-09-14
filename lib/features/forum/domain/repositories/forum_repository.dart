import '../entities/forum_post_entity.dart';
import '../entities/forum_reply_entity.dart';

abstract class ForumRepository {
  /// Newest thread first. [viewerUid] resolves each entry's `likedByMe`.
  Future<List<ForumPostEntity>> getPosts({required String viewerUid, int limit = 50});

  Future<void> createPost({
    required String title,
    required String body,
    required String authorUid,
    required String authorName,
    String? authorPhotoUrl,
  });

  /// Oldest reply first, so a thread reads top to bottom. [viewerUid]
  /// resolves each reply's `likedByMe`.
  Future<List<ForumReplyEntity>> getReplies(String postId, {required String viewerUid});

  Future<void> addReply({
    required String postId,
    required String body,
    required String authorUid,
    required String authorName,
    String? authorPhotoUrl,
    String? sharedRecipeId,
    String? sharedRecipeTitle,
  });

  /// Returns the new like state. Idempotent per user — liking twice is one
  /// like, exactly as on a shared recipe.
  Future<bool> togglePostLike(String postId, {required String viewerUid});

  /// Returns the new like state, per user, as [togglePostLike].
  Future<bool> toggleReplyLike(
    String postId,
    String replyId, {
    required String viewerUid,
  });

  Future<void> deletePost(String postId);
}
