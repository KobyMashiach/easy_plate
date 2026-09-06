import '../../../user_profile/domain/repositories/user_profile_repository.dart';
import '../../domain/entities/app_notification_entity.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../datasources/notifications_remote_datasource.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  final NotificationsRemoteDataSource remoteDataSource;

  /// Sender names come from the live public profiles, same as everywhere
  /// else — a notification from a renamed account shows the new name.
  final UserProfileRepository userProfileRepository;

  NotificationsRepositoryImpl({
    required this.remoteDataSource,
    required this.userProfileRepository,
  });

  @override
  Stream<List<AppNotificationEntity>> watch(String uid) {
    return remoteDataSource.watch(uid).asyncMap((items) async {
      if (items.isEmpty) return items;
      final profiles =
          await userProfileRepository.getPublicProfiles(items.map((n) => n.fromUid).toSet());
      return [
        for (final item in items)
          if (profiles[item.fromUid] case final profile?)
            item.withFromName(profile.fullName)
          else
            item,
      ];
    });
  }

  @override
  Future<void> markRead(String uid, String notificationId) =>
      remoteDataSource.markRead(uid, notificationId);

  @override
  Future<void> markAllRead(String uid) => remoteDataSource.markAllRead(uid);
}
