import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../features/feedback/domain/entities/feedback_entity.dart';
import '../../features/feedback/domain/repositories/feedback_repository.dart';

/// The administrator's live view of the support inbox, held for the whole
/// session so the badge on the avatar, the account menu and the dashboard
/// tab all share one Firestore listener. Bound only for the administrator's
/// account — the rules refuse the read to anyone else, and the count stays
/// at zero.
class AdminInboxService {
  static final AdminInboxService _instance = AdminInboxService._internal();
  factory AdminInboxService() => _instance;
  AdminInboxService._internal();

  final items = ValueNotifier<List<FeedbackEntity>>(const []);
  final unreadCount = ValueNotifier<int>(0);

  StreamSubscription<List<FeedbackEntity>>? _subscription;
  FeedbackRepository? _repository;
  bool _bound = false;

  /// Whether the app is in front. The inbox is every ticket, so its listener
  /// is closed while the app is away and reopened on return, when the first
  /// snapshot brings it up to date; the badge keeps its last count meanwhile.
  bool _foreground = true;

  bool get isBound => _bound;

  /// Whether a Firestore listener is open right now.
  @visibleForTesting
  bool get isListening => _subscription != null;

  void bind(FeedbackRepository repository) {
    if (_bound) return;
    _bound = true;
    _repository = repository;
    if (_foreground) _listen();
  }

  void _listen() {
    final repository = _repository;
    if (!_bound || repository == null || _subscription != null) return;
    _subscription = repository.watchAll().listen(
      (list) {
        items.value = list;
        unreadCount.value = list.where((f) => !f.read).length;
      },
      onError: (Object e) => debugPrint('Admin inbox stream error: $e'),
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

  /// On sign-out. The next account must never see the inbox.
  void unbind() {
    _subscription?.cancel();
    _subscription = null;
    _repository = null;
    _bound = false;
    items.value = const [];
    unreadCount.value = 0;
  }

  @visibleForTesting
  void resetForTest() {
    unbind();
    _foreground = true;
  }
}
