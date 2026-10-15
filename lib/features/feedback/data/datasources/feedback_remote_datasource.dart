import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/feedback_entity.dart';

abstract class FeedbackRemoteDataSource {
  Future<void> send(FeedbackEntity feedback);
  Future<List<FeedbackEntity>> getAll({int limit = 200});
  Stream<List<FeedbackEntity>> watchAll({int limit = 500});
  Stream<List<FeedbackEntity>> watchMine(String uid);
  Stream<FeedbackEntity?> watchOne(String feedbackId);
  Future<void> addFollowUp(String feedbackId, String text);
  Future<void> markSeenByUser(String feedbackId);
  Future<void> setRead(String feedbackId, bool read);
  Future<void> setClosed(String feedbackId, bool closed);
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

  CollectionReference<Map<String, dynamic>> get _root =>
      _firestore.collection(collection);

  @override
  Future<void> send(FeedbackEntity feedback) {
    final now = Timestamp.now();
    return _root.doc(feedback.id).set({
      'type': feedback.type.name,
      'message': feedback.message,
      'authorUid': feedback.authorUid,
      'authorName': feedback.authorName,
      'authorEmail': feedback.authorEmail,
      'appVersion': feedback.appVersion,
      'details': feedback.details,
      'source': feedback.source.name,
      'followUps': const [],
      'userUnread': false,
      'read': false,
      'createdAt': now,
      'updatedAt': now,
    });
  }

  @override
  Future<List<FeedbackEntity>> getAll({int limit = 200}) async {
    final snapshot = await _root
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
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

  /// One equality filter and the order done here, so the query needs no
  /// composite index.
  @override
  Stream<List<FeedbackEntity>> watchMine(String uid) {
    return _root
        .where('authorUid', isEqualTo: uid)
        .limit(100)
        .snapshots()
        .map(
          (snapshot) =>
              [for (final doc in snapshot.docs) ?_toEntity(doc)]
                ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)),
        );
  }

  @override
  Stream<FeedbackEntity?> watchOne(String feedbackId) => _root
      .doc(feedbackId)
      .snapshots()
      .map((doc) => doc.exists ? _toEntity(doc) : null);

  @override
  Future<void> addFollowUp(String feedbackId, String text) {
    // `arrayUnion` cannot hold a server timestamp, hence the client clock;
    // `read: false` puts the conversation back among the administrator's
    // unread ones. The rules allow the author exactly these keys.
    return _root.doc(feedbackId).update({
      'followUps': FieldValue.arrayUnion([
        {'text': text, 'at': Timestamp.now()},
      ]),
      'updatedAt': FieldValue.serverTimestamp(),
      'read': false,
      'userUnread': false,
    });
  }

  @override
  Future<void> markSeenByUser(String feedbackId) =>
      _root.doc(feedbackId).update({'userUnread': false});

  @override
  Future<void> setRead(String feedbackId, bool read) {
    return _root.doc(feedbackId).update({
      'read': read,
      'readAt': read ? FieldValue.serverTimestamp() : null,
    });
  }

  /// Closing also marks the message read: a closed conversation is not
  /// something the badge should count.
  @override
  Future<void> setClosed(String feedbackId, bool closed) {
    return _root.doc(feedbackId).update({
      'status': closed ? 'closed' : 'open',
      'closedAt': closed ? FieldValue.serverTimestamp() : null,
      'updatedAt': FieldValue.serverTimestamp(),
      if (closed) 'read': true,
      if (closed) 'readAt': FieldValue.serverTimestamp(),
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
      'updatedAt': FieldValue.serverTimestamp(),
      'userUnread': true,
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

  static List<FeedbackReply> _lines(Object? raw) => [
    for (final r in (raw as List?) ?? const [])
      if (r is Map)
        FeedbackReply(
          text: (r['text'] as String?) ?? '',
          at: (r['at'] as Timestamp?)?.toDate() ?? DateTime(0),
        ),
  ];

  FeedbackEntity? _toEntity(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    final type = FeedbackType.values
        .where((t) => t.name == data['type'])
        .firstOrNull;
    if (type == null) return null;
    final createdAt =
        (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    return FeedbackEntity(
      id: doc.id,
      type: type,
      message: (data['message'] as String?) ?? '',
      authorUid: (data['authorUid'] as String?) ?? '',
      authorName: (data['authorName'] as String?) ?? '',
      authorEmail: data['authorEmail'] as String?,
      appVersion: data['appVersion'] as String?,
      createdAt: createdAt,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? createdAt,
      read: data['read'] == true,
      readAt: (data['readAt'] as Timestamp?)?.toDate(),
      replies: _lines(data['replies']),
      followUps: _lines(data['followUps']),
      details: {
        if (data['details'] is Map)
          for (final e in (data['details'] as Map).entries)
            if (e.key is String && e.value is String && (e.value as String).trim().isNotEmpty)
              e.key as String: e.value as String,
      },
      userUnread: data['userUnread'] == true,
      closed: data['status'] == 'closed',
      closedAt: (data['closedAt'] as Timestamp?)?.toDate(),
      source: data['source'] == FeedbackSource.shefi.name
          ? FeedbackSource.shefi
          : FeedbackSource.app,
    );
  }
}
