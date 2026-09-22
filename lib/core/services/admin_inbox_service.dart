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
  bool _bound = false;

  bool get isBound => _bound;

  void bind(FeedbackRepository repository) {
    if (_bound) return;
    _bound = true;
    _subscription = repository.watchAll().listen(
      (list) {
        items.value = list;
        unreadCount.value = list.where((f) => !f.read).length;
      },
      onError: (Object e) => debugPrint('Admin inbox stream error: $e'),
    );
  }

  /// On sign-out. The next account must never see the inbox.
  void unbind() {
    _subscription?.cancel();
    _subscription = null;
    _bound = false;
    items.value = const [];
    unreadCount.value = 0;
  }
}
