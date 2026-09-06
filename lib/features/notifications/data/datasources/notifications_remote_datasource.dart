import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/app_enums.dart';
import '../../domain/entities/app_notification_entity.dart';

abstract class NotificationsRemoteDataSource {
  Stream<List<AppNotificationEntity>> watch(String uid);
  Future<void> markRead(String uid, String notificationId);
  Future<void> markAllRead(String uid);
}

class NotificationsFirestoreDataSource implements NotificationsRemoteDataSource {
  static const collection = 'notifications';

  final FirebaseFirestore _firestore;

  NotificationsFirestoreDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _items(String uid) =>
      _firestore.collection(collection).doc(uid).collection('items');

  @override
  Stream<List<AppNotificationEntity>> watch(String uid) {
    return _items(uid).orderBy('createdAt', descending: true).limit(100).snapshots().map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            return AppNotificationEntity(
              id: doc.id,
              type: AppNotificationType.values.firstWhere(
                (t) => t.name == data['type'],
                orElse: () => AppNotificationType.shareInvite,
              ),
              fromUid: (data['fromUid'] as String?) ?? '',
              inviteId: data['inviteId'] as String?,
              collabId: data['collabId'] as String?,
              recipeTitle: data['recipeTitle'] as String?,
              role: CollabRole.values.where((r) => r.name == data['role']).firstOrNull,
              read: (data['read'] as bool?) ?? false,
              createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            );
          }).toList(),
        );
  }

  @override
  Future<void> markRead(String uid, String notificationId) =>
      _items(uid).doc(notificationId).update({'read': true});

  @override
  Future<void> markAllRead(String uid) async {
    final unread = await _items(uid).where('read', isEqualTo: false).get();
    if (unread.docs.isEmpty) return;
    final batch = _firestore.batch();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }
}
