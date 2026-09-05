import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

/// Background isolate entry point for FCM. Must be top level and annotated, or
/// the isolate cannot find it after tree shaking.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Background FCM message: ${message.messageId}');
}

/// Boots the Firebase services the app uses and holds the handles other layers
/// need. Configuration comes from `google-services.json` / `GoogleService-Info.plist`,
/// so there is no generated `firebase_options.dart` to keep in sync.
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  FirebaseAnalytics? _analytics;
  bool _initialized = false;

  /// Null until [init] has finished. Callers on unawaited paths must cope
  /// with that rather than assume Firebase is up.
  FirebaseAnalytics? get analytics => _analytics;

  /// Remote Config keys, with the values used until the first fetch lands.
  static const _remoteDefaults = <String, dynamic>{
    'ai_ingestion_enabled': true,
    'max_recipes_per_book': 50,
  };

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    await Firebase.initializeApp();
    _analytics = FirebaseAnalytics.instance;

    _wireCrashlytics();
    _wireMessaging();
    // Not awaited: a slow or offline fetch must not hold up the first frame.
    unawaited(_initRemoteConfig());
  }

  void _wireCrashlytics() {
    final crashlytics = FirebaseCrashlytics.instance;
    // Debug crashes are noise in the dashboard, and they are already visible
    // in the console.
    unawaited(crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode));
    FlutterError.onError = crashlytics.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      crashlytics.recordError(error, stack, fatal: true);
      return true;
    };
  }

  void _wireMessaging() {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('Foreground FCM message: ${message.notification?.title}');
    });
  }

  Future<void> _initRemoteConfig() async {
    try {
      final config = FirebaseRemoteConfig.instance;
      await config.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        // A release build must not hammer the backend; debug wants each run to
        // see the latest values.
        minimumFetchInterval: kDebugMode ? Duration.zero : const Duration(hours: 1),
      ));
      await config.setDefaults(_remoteDefaults);
      await config.fetchAndActivate();
    } catch (e) {
      debugPrint('Remote Config unavailable: $e');
    }
  }

  /// Push permission is asked for only once there is a signed-in user to
  /// attach the token to — a prompt on a cold first launch has nothing to
  /// explain itself with.
  Future<String?> registerPushToken() async {
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return null;
      return await messaging.getToken();
    } catch (e) {
      debugPrint('Push registration failed: $e');
      return null;
    }
  }

  /// Tolerant of Firebase not being up: this runs from the auth session on an
  /// unawaited path, where a throw would surface as an unhandled async error.
  Future<void> setAnalyticsUser(String? uid) async {
    final analytics = _analytics;
    if (analytics == null) return;
    try {
      await analytics.setUserId(id: uid);
      await FirebaseCrashlytics.instance.setUserIdentifier(uid ?? '');
    } catch (e) {
      debugPrint('Analytics user update failed: $e');
    }
  }

  Future<void> logEvent(String name, [Map<String, Object>? parameters]) async =>
      _analytics?.logEvent(name: name, parameters: parameters);
}
