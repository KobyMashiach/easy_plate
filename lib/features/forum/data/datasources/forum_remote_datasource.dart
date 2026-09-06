import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/forum_post_entity.dart';
import '../../domain/entities/forum_reply_entity.dart';

abstract class ForumRemoteDataSource {
  Future<List<ForumPostEntity>> getPosts({int limit = 50});
  Future<void> createPost({
    required String title,
    required String body,
    required String authorUid,
    required String authorName,
    String? authorPhotoUrl,
  });
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

class ForumFirestoreDataSource implements ForumRemoteDataSource {
  static const collection = 'forum_posts';
  static const _replies = 'replies';
  static const _uuid = Uuid();

  final FirebaseFirestore _firestore;

  ForumFirestoreDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _root => _firestore.collection(collection);

  @override
  Future<List<ForumPostEntity>> getPosts({int limit = 50}) async {
    final snapshot = await _root.orderBy('createdAt', descending: true).limit(limit).get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return ForumPostEntity(
        id: doc.id,
        title: (data['title'] as String?) ?? '',
        body: (data['body'] as String?) ?? '',
        authorUid: (data['authorUid'] as String?) ?? '',
        authorName: (data['authorName'] as String?) ?? '',
        authorPhotoUrl: data['authorPhotoUrl'] as String?,
        replyCount: (data['replyCount'] as num?)?.toInt() ?? 0,
        createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    }).toList();
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
      'createdAt': Timestamp.now(),
    });
  }

  @override
  Future<List<ForumReplyEntity>> getReplies(String postId) async {
    final snapshot =
        await _root.doc(postId).collection(_replies).orderBy('createdAt').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return ForumReplyEntity(
        id: doc.id,
        body: (data['body'] as String?) ?? '',
        authorUid: (data['authorUid'] as String?) ?? '',
        authorName: (data['authorName'] as String?) ?? '',
        authorPhotoUrl: data['authorPhotoUrl'] as String?,
        sharedRecipeId: data['sharedRecipeId'] as String?,
        sharedRecipeTitle: data['sharedRecipeTitle'] as String?,
        createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    }).toList();
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
      'createdAt': Timestamp.now(),
    });
    batch.update(post, {'replyCount': FieldValue.increment(1)});
    return batch.commit();
  }

  /// Firestore does not cascade, so the replies have to go explicitly or they
  /// linger as unreachable documents.
  @override
  Future<void> deletePost(String postId) async {
    final post = _root.doc(postId);
    final replies = await post.collection(_replies).get();

    final batch = _firestore.batch();
    for (final reply in replies.docs) {
      batch.delete(reply.reference);
    }
    batch.delete(post);
    await batch.commit();
  }
}
