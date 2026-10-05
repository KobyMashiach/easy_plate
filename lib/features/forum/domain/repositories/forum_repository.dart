import '../entities/forum_post_entity.dart';
import '../entities/forum_reply_entity.dart';

abstract class ForumRepository {
  /// Newest thread first. [viewerUid] resolves each entry's `likedByMe`.
  Future<List<ForumPostEntity>> getPosts({
    required String viewerUid,
    int limit = 50,
  });

  /// The same list, kept live: a new emission whenever any thread in the
  /// window changes — a new post, a reply landing, a like moving. Cheaper
  /// than polling, and faster: Firestore pushes the change rather than the
  /// app asking every few seconds and re-reading fifty documents each time.
  Stream<List<ForumPostEntity>> watchPosts({
    required String viewerUid,
    int limit = 50,
  });

  /// One thread by id, for a notification that points at it. Null when it
  /// has since been deleted.
  Future<ForumPostEntity?> getPost(String postId, {required String viewerUid});

  Future<void> createPost({
    required String title,
    required String body,
    required String authorUid,
    required String authorName,
    String? authorPhotoUrl,
  });

  /// Oldest reply first, so a thread reads top to bottom. [viewerUid]
  /// resolves each reply's `likedByMe`.
  Future<List<ForumReplyEntity>> getReplies(
    String postId, {
    required String viewerUid,
  });

  /// The replies of one thread, kept live, in the same order as [getReplies].
  Stream<List<ForumReplyEntity>> watchReplies(
    String postId, {
    required String viewerUid,
  });

  /// Returns the new reply's id. The id is chosen before the write so the
  /// caller can draw the reply at once and later match it against the one
  /// the stream delivers.
  Future<String> addReply({
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
