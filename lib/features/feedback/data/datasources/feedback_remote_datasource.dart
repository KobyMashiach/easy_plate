import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/feedback_entity.dart';

abstract class FeedbackRemoteDataSource {
  Future<void> send(FeedbackEntity feedback);
  Future<List<FeedbackEntity>> getAll({int limit = 200});
  Stream<List<FeedbackEntity>> watchAll({int limit = 500});
  Future<void> setRead(String feedbackId, bool read);
  Future<void> markAllRead(Iterable<String> feedbackIds);
  Future<void> delete(String feedbackId);
  Future<void> reply({
    required FeedbackEntity feedback,
    required String text,
    required String fromUid,
  });
}

class FeedbackFirestoreDataSource implements FeedbackRemoteDataSource {
  static const collection = 'feedback';

  /// Where a reply lands: the author's inbox, the same place a share invite
  /// goes, so the existing bell and push pick it up unchanged.
  static const notificationsCollection = 'notifications';
  static const replyNotificationType = 'adminReply';

  final FirebaseFirestore _firestore;

  FeedbackFirestoreDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _root => _firestore.collection(collection);

  @override
  Future<void> send(FeedbackEntity feedback) {
    return _root.doc(feedback.id).set({
      'type': feedback.type.name,
      'message': feedback.message,
      'authorUid': feedback.authorUid,
      'authorName': feedback.authorName,
      'authorEmail': feedback.authorEmail,
      'appVersion': feedback.appVersion,
      'createdAt': Timestamp.now(),
    });
  }

  @override
  Future<List<FeedbackEntity>> getAll({int limit = 200}) async {
    final snapshot = await _root.orderBy('createdAt', descending: true).limit(limit).get();
    return [for (final doc in snapshot.docs) ?_toEntity(doc)];
  }

  @override
  Stream<List<FeedbackEntity>> watchAll({int limit = 500}) {
    return _root
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => [for (final doc in snapshot.docs) ?_toEntity(doc)]);
  }

  @override
  Future<void> setRead(String feedbackId, bool read) {
    return _root.doc(feedbackId).update({
      'read': read,
      'readAt': read ? FieldValue.serverTimestamp() : null,
    });
  }

  @override
  Future<void> markAllRead(Iterable<String> feedbackIds) async {
    final ids = feedbackIds.toList();
    if (ids.isEmpty) return;
    // A batch takes 500 writes; the inbox is read in pages of that size.
    for (var i = 0; i < ids.length; i += 500) {
      final batch = _firestore.batch();
      for (final id in ids.skip(i).take(500)) {
        batch.update(_root.doc(id), {
          'read': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    }
  }

  @override
  Future<void> delete(String feedbackId) => _root.doc(feedbackId).delete();

  @override
  Future<void> reply({
    required FeedbackEntity feedback,
    required String text,
    required String fromUid,
  }) {
    final now = Timestamp.now();
    final batch = _firestore.batch();
    // Kept on the message so the inbox shows what was already answered.
    // `arrayUnion` cannot hold a server timestamp, hence the client clock.
    batch.update(_root.doc(feedback.id), {
      'replies': FieldValue.arrayUnion([
        {'text': text, 'at': now},
      ]),
      'repliedAt': FieldValue.serverTimestamp(),
    });
    batch.set(
      _firestore
          .collection(notificationsCollection)
          .doc(feedback.authorUid)
          .collection('items')
          .doc(),
      {
        'type': replyNotificationType,
        'fromUid': fromUid,
        'message': text,
        'feedbackId': feedback.id,
        'feedbackExcerpt': feedback.excerpt,
        'read': false,
        'createdAt': now,
      },
    );
    return batch.commit();
  }

  FeedbackEntity? _toEntity(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    final type = FeedbackType.values.where((t) => t.name == data['type']).firstOrNull;
    if (type == null) return null;
    return FeedbackEntity(
      id: doc.id,
      type: type,
      message: (data['message'] as String?) ?? '',
      authorUid: (data['authorUid'] as String?) ?? '',
      authorName: (data['authorName'] as String?) ?? '',
      authorEmail: data['authorEmail'] as String?,
      appVersion: data['appVersion'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      read: data['read'] == true,
      readAt: (data['readAt'] as Timestamp?)?.toDate(),
      replies: [
        for (final r in (data['replies'] as List?) ?? const [])
          if (r is Map)
            FeedbackReply(
              text: (r['text'] as String?) ?? '',
              at: (r['at'] as Timestamp?)?.toDate() ?? DateTime(0),
            ),
      ],
    );
  }
}
