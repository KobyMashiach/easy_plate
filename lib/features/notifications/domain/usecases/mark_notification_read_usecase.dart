import 'package:flutter/foundation.dart';

import '../entities/app_notification_entity.dart';
import '../repositories/notifications_repository.dart';

class MarkNotificationReadUseCase {
  final NotificationsRepository repository;
  MarkNotificationReadUseCase(this.repository);

  Future<void> call(String uid, String notificationId) =>
      repository.markRead(uid, notificationId);

  Future<void> all(String uid) => repository.markAllRead(uid);

  /// An invite answered somewhere other than its inbox row (the sharing
  /// page, a share code): the row it arrived with is done too, and used to
  /// stay unread — a badge on the bell for something already handled.
  ///
  /// The row is found by its invite id in [inbox] (a re-invite's row has a
  /// suffixed id); the invite's own id is tried as well, since that is the
  /// row a share code writes and it may not have reached the listener yet.
  /// Best effort: a missing row or a failed write only leaves it unread.
  Future<void> invite(
    String uid,
    String inviteId, {
    Iterable<AppNotificationEntity> inbox = const [],
  }) async {
    final known = {for (final item in inbox) item.id: item};
    final ids = <String>{
      if (known[inviteId]?.read != true) inviteId,
      for (final item in inbox)
        if (!item.read && item.inviteId == inviteId) item.id,
    };
    for (final id in ids) {
      try {
        await repository.markRead(uid, id);
      } catch (e) {
        debugPrint('Marking the invite row $id read failed: $e');
      }
    }
  }
}
