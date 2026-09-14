import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/forum_post_entity.dart';
import '../../domain/entities/forum_reply_entity.dart';

abstract class ForumRemoteDataSource {
  Future<List<ForumPostEntity>> getPosts({required String viewerUid, int limit = 50});
  Future<void> createPost({
    required String title,
    required String body,
    required String authorUid,
    required String authorName,
    String? authorPhotoUrl,
  });
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
  Future<bool> togglePostLike(String postId, {required String viewerUid});
  Future<bool> toggleReplyLike(String postId, String replyId, {required String viewerUid});
  Future<void> deletePost(String postId);
}

class ForumFirestoreDataSource implements ForumRemoteDataSource {
  static const collection = 'forum_posts';
  static const _replies = 'replies';
  static const _likes = 'likes';
  static const _uuid = Uuid();

  final FirebaseFirestore _firestore;

  ForumFirestoreDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _root => _firestore.collection(collection);

  /// One like lookup per row rather than a read of every like: the list only
  /// needs to know about this viewer. Same shape as the shared-recipes feed.
  Future<List<bool>> _likedByViewer(
    List<DocumentSnapshot<Map<String, dynamic>>> docs,
    String viewerUid,
  ) async {
    final liked = await Future.wait(
      docs.map((doc) => doc.reference.collection(_likes).doc(viewerUid).get()),
    );
    return [for (final like in liked) like.exists];
  }

  @override
  Future<List<ForumPostEntity>> getPosts({required String viewerUid, int limit = 50}) async {
    final snapshot = await _root.orderBy('createdAt', descending: true).limit(limit).get();
    final liked = await _likedByViewer(snapshot.docs, viewerUid);

    return [
      for (var i = 0; i < snapshot.docs.length; i++)
        _toPost(snapshot.docs[i], likedByMe: liked[i]),
    ];
  }

  ForumPostEntity _toPost(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    required bool likedByMe,
  }) {
    final data = doc.data() ?? const <String, dynamic>{};
    return ForumPostEntity(
      id: doc.id,
      title: (data['title'] as String?) ?? '',
      body: (data['body'] as String?) ?? '',
      authorUid: (data['authorUid'] as String?) ?? '',
      authorName: (data['authorName'] as String?) ?? '',
      authorPhotoUrl: data['authorPhotoUrl'] as String?,
      replyCount: (data['replyCount'] as num?)?.toInt() ?? 0,
      // Threads written before likes existed have no counter; they read as
      // zero, and the first like's increment creates the field.
      likeCount: (data['likeCount'] as num?)?.toInt() ?? 0,
      likedByMe: likedByMe,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  @override
  Future<void> createPost({
    required String title,
    required String body,
    required String authorUid,
    required String authorName,
    String? authorPhotoUrl,
  }) {
    return _root.doc(_uuid.v4()).set({
      'title': title,
      'body': body,
      'authorUid': authorUid,
      'authorName': authorName,
      'authorPhotoUrl': authorPhotoUrl,
      'replyCount': 0,
      'likeCount': 0,
      'createdAt': Timestamp.now(),
    });
  }

  @override
  Future<List<ForumReplyEntity>> getReplies(String postId, {required String viewerUid}) async {
    final snapshot =
        await _root.doc(postId).collection(_replies).orderBy('createdAt').get();
    final liked = await _likedByViewer(snapshot.docs, viewerUid);

    return [
      for (var i = 0; i < snapshot.docs.length; i++)
        _toReply(snapshot.docs[i], likedByMe: liked[i]),
    ];
  }

  ForumReplyEntity _toReply(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    required bool likedByMe,
  }) {
    final data = doc.data() ?? const <String, dynamic>{};
    return ForumReplyEntity(
      id: doc.id,
      body: (data['body'] as String?) ?? '',
      authorUid: (data['authorUid'] as String?) ?? '',
      authorName: (data['authorName'] as String?) ?? '',
      authorPhotoUrl: data['authorPhotoUrl'] as String?,
      sharedRecipeId: data['sharedRecipeId'] as String?,
      sharedRecipeTitle: data['sharedRecipeTitle'] as String?,
      likeCount: (data['likeCount'] as num?)?.toInt() ?? 0,
      likedByMe: likedByMe,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// The reply and the thread's counter are written together, so a list built
  /// from the counter cannot drift from the replies that actually exist.
  @override
  Future<void> addReply({
    required String postId,
    required String body,
    required String authorUid,
    required String authorName,
    String? authorPhotoUrl,
    String? sharedRecipeId,
    String? sharedRecipeTitle,
  }) {
    final post = _root.doc(postId);
    final reply = post.collection(_replies).doc(_uuid.v4());

    final batch = _firestore.batch();
    batch.set(reply, {
      'body': body,
      'authorUid': authorUid,
      'authorName': authorName,
      'authorPhotoUrl': authorPhotoUrl,
      'sharedRecipeId': sharedRecipeId,
      'sharedRecipeTitle': sharedRecipeTitle,
      'likeCount': 0,
      'createdAt': Timestamp.now(),
    });
    batch.update(post, {'replyCount': FieldValue.increment(1)});
    return batch.commit();
  }

  @override
  Future<bool> togglePostLike(String postId, {required String viewerUid}) =>
      _toggleLike(_root.doc(postId), viewerUid: viewerUid);

  @override
  Future<bool> toggleReplyLike(String postId, String replyId, {required String viewerUid}) =>
      _toggleLike(_root.doc(postId).collection(_replies).doc(replyId), viewerUid: viewerUid);

  /// The per-user like document and the denormalised counter have to move
  /// together, or a double tap inflates the count. Threads and replies keep
  /// their likes the same way, so one transaction serves both.
  Future<bool> _toggleLike(
    DocumentReference<Map<String, dynamic>> target, {
    required String viewerUid,
  }) {
    final like = target.collection(_likes).doc(viewerUid);

    return _firestore.runTransaction<bool>((transaction) async {
      final existing = await transaction.get(like);
      if (existing.exists) {
        transaction.delete(like);
        transaction.update(target, {'likeCount': FieldValue.increment(-1)});
        return false;
      }
      transaction.set(like, {'createdAt': Timestamp.now()});
      transaction.update(target, {'likeCount': FieldValue.increment(1)});
      return true;
    });
  }

  /// Firestore does not cascade, so the replies — and the like documents under
  /// the thread and under each reply — have to go explicitly or they linger
  /// as unreachable, and still billed, documents.
  @override
  Future<void> deletePost(String postId) async {
    final post = _root.doc(postId);
    final replies = await post.collection(_replies).get();
    final postLikes = await post.collection(_likes).get();
    final replyLikes = await Future.wait(
      replies.docs.map((reply) => reply.reference.collection(_likes).get()),
    );

    final batch = _firestore.batch();
    for (final like in postLikes.docs) {
      batch.delete(like.reference);
    }
    for (final likes in replyLikes) {
      for (final like in likes.docs) {
        batch.delete(like.reference);
      }
    }
    for (final reply in replies.docs) {
      batch.delete(reply.reference);
    }
    batch.delete(post);
    await batch.commit();
  }
}
