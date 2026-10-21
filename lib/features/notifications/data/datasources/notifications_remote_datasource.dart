import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/constants/app_enums.dart';
import '../../../community/data/doc_fields.dart';
import '../../domain/entities/app_notification_entity.dart';

abstract class NotificationsRemoteDataSource {
  Stream<List<AppNotificationEntity>> watch(String uid);
  Future<void> markRead(String uid, String notificationId);
  Future<void> markAllRead(String uid);
  Future<void> delete(String uid, String notificationId);
  Future<void> deleteAll(String uid);
}

class NotificationsFirestoreDataSource
    implements NotificationsRemoteDataSource {
  static const collection = 'notifications';

  /// A batch takes 500 writes; a little under, per commit. The inbox shows
  /// its newest hundred, but the collection behind it keeps growing.
  static const _batchLimit = 450;

  final FirebaseFirestore _firestore;

  NotificationsFirestoreDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _items(String uid) =>
      _firestore.collection(collection).doc(uid).collection('items');

  @override
  Stream<List<AppNotificationEntity>> watch(String uid) {
    return _items(uid)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map(
          (snapshot) => parseEach(
            snapshot.docs,
            (doc) => fromData(doc.id, doc.data()),
            label: 'Inbox',
          ),
        );
  }

  /// One inbox row, or null for a type this build does not know — a newer
  /// client or function may write one, and showing it as a share invite
  /// (the old fallback) offered accept/decline on something that is not
  /// an invite at all.
  @visibleForTesting
  static AppNotificationEntity? fromData(String id, Map<String, dynamic> data) {
    final type = docEnum(AppNotificationType.values, data['type']);
    if (type == null) {
      debugPrint('Inbox row $id skipped: unknown type ${data['type']}');
      return null;
    }
    return AppNotificationEntity(
      id: id,
      type: type,
      fromUid: docString(data['fromUid']),
      inviteId: docNonEmpty(data['inviteId']),
      collabId: docNonEmpty(data['collabId']),
      recipeTitle: docStringOrNull(data['recipeTitle']),
      sharedId: docNonEmpty(data['sharedId']),
      message: docStringOrNull(data['message']),
      feedbackExcerpt: docStringOrNull(data['feedbackExcerpt']),
      feedbackId: docNonEmpty(data['feedbackId']),
      title: docStringOrNull(data['title']),
      postId: docNonEmpty(data['postId']),
      replyId: docNonEmpty(data['replyId']),
      postTitle: docStringOrNull(data['postTitle']),
      excerpt: docStringOrNull(data['excerpt']),
      onMyPost: docBool(data['onMyPost']),
      kind: CollabKind.fromName(docStringOrNull(data['kind'])),
      role: docEnum(CollabRole.values, data['role']),
      read: docBool(data['read']),
      createdAt: docDate(data['createdAt']) ?? DateTime.now(),
    );
  }

  @override
  Future<void> markRead(String uid, String notificationId) =>
      _items(uid).doc(notificationId).update({'read': true});

  @override
  Future<void> markAllRead(String uid) async {
    final unread = await _items(uid).where('read', isEqualTo: false).get();
    for (var i = 0; i < unread.docs.length; i += _batchLimit) {
      final batch = _firestore.batch();
      for (final doc in unread.docs.skip(i).take(_batchLimit)) {
        batch.update(doc.reference, {'read': true});
      }
      await batch.commit();
    }
  }

  @override
  Future<void> delete(String uid, String notificationId) =>
      _items(uid).doc(notificationId).delete();

  @override
  Future<void> deleteAll(String uid) async {
    final all = await _items(uid).get();
    for (var i = 0; i < all.docs.length; i += _batchLimit) {
      final batch = _firestore.batch();
      for (final doc in all.docs.skip(i).take(_batchLimit)) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }
}
