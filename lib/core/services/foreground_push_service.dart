import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// What the in-app popup shows for a push that arrived while the app was
/// open.
class PushBanner {
  final String id;
  final String title;
  final String body;

  const PushBanner({required this.id, required this.title, required this.body});
}

/// A push that lands while the app is open. The system draws nothing for
/// it, and by Koby's choice neither do we in the tray: the app shows its
/// own popup instead (see `main.dart`), which is where [latest] goes.
class ForegroundPushService {
  static final ForegroundPushService _instance =
      ForegroundPushService._internal();
  factory ForegroundPushService() => _instance;
  ForegroundPushService._internal();

  /// The most recent foreground push, for the popup drawn over the app.
  final latest = ValueNotifier<PushBanner?>(null);

  void show(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;
    latest.value = PushBanner(
      id: message.messageId ?? DateTime.now().microsecondsSinceEpoch.toString(),
      title: notification.title ?? '',
      body: notification.body ?? '',
    );
  }
}
