import 'package:flutter/foundation.dart';

import '../../../user_profile/domain/entities/public_profile_entity.dart';
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
      final Map<String, PublicProfileEntity> profiles;
      try {
        profiles = await userProfileRepository.getPublicProfiles(
          items.map((n) => n.fromUid).toSet(),
        );
      } catch (e) {
        // A failed name lookup must not cost the inbox this snapshot: it
        // became a stream error, and the new rows (and the badge) waited
        // for the next change. The rows show the names stored on them.
        debugPrint('Inbox sender lookup failed: $e');
        return items;
      }
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

  @override
  Future<void> delete(String uid, String notificationId) =>
      remoteDataSource.delete(uid, notificationId);

  @override
  Future<void> deleteAll(String uid) => remoteDataSource.deleteAll(uid);
}
