import '../repositories/notifications_repository.dart';

class MarkNotificationReadUseCase {
  final NotificationsRepository repository;
  MarkNotificationReadUseCase(this.repository);

  Future<void> call(String uid, String notificationId) =>
      repository.markRead(uid, notificationId);

  Future<void> all(String uid) => repository.markAllRead(uid);
}
