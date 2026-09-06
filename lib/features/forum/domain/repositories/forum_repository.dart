import '../entities/forum_post_entity.dart';
import '../entities/forum_reply_entity.dart';

abstract class ForumRepository {
  /// Newest thread first.
  Future<List<ForumPostEntity>> getPosts({int limit = 50});

  Future<void> createPost({
    required String title,
    required String body,
    required String authorUid,
    required String authorName,
    String? authorPhotoUrl,
  });

  /// Oldest reply first, so a thread reads top to bottom.
  Future<List<ForumReplyEntity>> getReplies(String postId);

  Future<void> addReply({
    required String postId,
    required String body,
    required String authorUid,
    required String authorName,
    String? authorPhotoUrl,
    String? sharedRecipeId,
    String? sharedRecipeTitle,
  });

  Future<void> deletePost(String postId);
}
