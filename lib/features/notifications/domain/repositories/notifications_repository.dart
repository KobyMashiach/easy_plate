import '../entities/app_notification_entity.dart';

abstract class NotificationsRepository {
  /// Newest first, kept live: the bell badge is driven by this stream.
  Stream<List<AppNotificationEntity>> watch(String uid);
  Future<void> markRead(String uid, String notificationId);
  Future<void> markAllRead(String uid);
}
