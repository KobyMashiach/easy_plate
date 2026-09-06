import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../features/notifications/domain/entities/app_notification_entity.dart';
import '../../features/notifications/domain/repositories/notifications_repository.dart';

/// Holds the signed-in account's notification stream for the whole session, so
/// the bell on every screen shares one subscription instead of each opening
/// its own Firestore listener.
class NotificationsService {
  static final NotificationsService _instance = NotificationsService._internal();
  factory NotificationsService() => _instance;
  NotificationsService._internal();

  final items = ValueNotifier<List<AppNotificationEntity>>(const []);
  final unreadCount = ValueNotifier<int>(0);

  StreamSubscription<List<AppNotificationEntity>>? _subscription;
  String? _uid;

  String? get uid => _uid;

  void bind(String uid, NotificationsRepository repository) {
    if (_uid == uid) return;
    unbind();
    _uid = uid;
    _subscription = repository.watch(uid).listen(
      (list) {
        items.value = list;
        unreadCount.value = list.where((n) => !n.read).length;
      },
      onError: (Object e) => debugPrint('Notifications stream error: $e'),
    );
  }

  /// On sign-out. The next account must never see the previous one's items.
  void unbind() {
    _subscription?.cancel();
    _subscription = null;
    _uid = null;
    items.value = const [];
    unreadCount.value = 0;
  }
}
