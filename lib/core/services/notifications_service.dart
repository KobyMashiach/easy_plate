import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../features/notifications/domain/entities/app_notification_entity.dart';
import '../../features/notifications/domain/repositories/notifications_repository.dart';

/// Holds the signed-in account's notification stream for the whole session, so
/// the bell on every screen shares one subscription instead of each opening
/// its own Firestore listener.
class NotificationsService {
  static final NotificationsService _instance =
      NotificationsService._internal();
  factory NotificationsService() => _instance;
  NotificationsService._internal();

  final items = ValueNotifier<List<AppNotificationEntity>>(const []);
  final unreadCount = ValueNotifier<int>(0);

  StreamSubscription<List<AppNotificationEntity>>? _subscription;
  NotificationsRepository? _repository;
  String? _uid;

  /// Whether the app is in front. While it is away the listener is closed —
  /// the query is the newest items as a whole, so the first snapshot after
  /// a resume brings back everything that changed in between, and a push already
  /// tells the user about anything new. What was last read stays on show.
  bool _foreground = true;

  String? get uid => _uid;

  /// Whether a Firestore listener is open right now.
  @visibleForTesting
  bool get isListening => _subscription != null;

  void bind(String uid, NotificationsRepository repository) {
    if (_uid == uid) return;
    unbind();
    _uid = uid;
    _repository = repository;
    if (_foreground) _listen();
  }

  void _listen() {
    final uid = _uid;
    final repository = _repository;
    if (uid == null || repository == null || _subscription != null) return;
    _subscription = repository.watch(uid).listen(
      (list) {
        items.value = list;
        unreadCount.value = list.where((n) => !n.read).length;
      },
      onError: (Object e) => debugPrint('Notifications stream error: $e'),
    );
  }

  /// The app moved to the foreground (true) or away from it (false).
  void setForeground(bool foreground) {
    if (_foreground == foreground) return;
    _foreground = foreground;
    if (foreground) {
      _listen();
    } else {
      _subscription?.cancel();
      _subscription = null;
    }
  }

  /// On sign-out. The next account must never see the previous one's items.
  void unbind() {
    _subscription?.cancel();
    _subscription = null;
    _uid = null;
    _repository = null;
    items.value = const [];
    unreadCount.value = 0;
  }

  @visibleForTesting
  void resetForTest() {
    unbind();
    _foreground = true;
  }
}
