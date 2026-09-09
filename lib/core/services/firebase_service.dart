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
  @visibleForTesting
  static const remoteDefaults = <String, dynamic>{
    'ai_ingestion_enabled': true,
    'max_recipes_per_book': 50,
    // Defaults to production. A failed or slow fetch must never be what puts a
    // DEV marker in front of a real user; a developer briefly not seeing one is
    // the cheaper mistake.
    isProdKey: true,
    // Version gating, read by AppUpdateService. Both default to a version no
    // build can be behind, so an app that cannot reach the console never
    // decides on its own that it is out of date and locks the user out.
    minimumVersionKey: '0.0.0',
    latestVersionKey: '0.0.0',
    // Set once the app has an App Store listing; the numeric id is the only
    // way to link to it. Empty means "no iOS listing yet".
    iosAppStoreIdKey: '',
    // Monetisation, read by MonetizationConfig. Every ad and every daily quota
    // hangs off these, so a console change reaches users on their next resume
    // without a release.
    adsEnabledKey: true,
    // When no rewarded ad can be served (no fill, offline), the unlock is
    // granted anyway. A brand-new AdMob account fills poorly for a while, and
    // a user refused their recipe because *we* had nothing to show them is
    // the wrong person to punish.
    adsFailOpenKey: true,
    // One native card after every N feed items.
    feedAdIntervalKey: 5,
    quotaSharedFreeKey: 3,
    quotaSharedRewardedKey: 3,
    quotaAiRewardedKey: 2,
  };

  static const adsEnabledKey = 'ads_enabled';
  static const adsFailOpenKey = 'ads_fail_open';
  static const feedAdIntervalKey = 'ads_feed_interval';
  static const quotaSharedFreeKey = 'quota_shared_free';
  static const quotaSharedRewardedKey = 'quota_shared_rewarded';
  static const quotaAiRewardedKey = 'quota_ai_rewarded';

  static const isProdKey = 'isProd';

  /// The oldest build still allowed to run. Below this the update is forced.
  static const minimumVersionKey = 'minimumVersion';

  /// The newest build available in the stores. Above the running one — and
  /// with [minimumVersionKey] satisfied — the update is offered, not forced.
  static const latestVersionKey = 'latestVersion';

  static const iosAppStoreIdKey = 'iosAppStoreId';

  /// Whether this build is running as production, per Remote Config.
  ///
  /// A [ValueNotifier] rather than a plain getter: activated values survive a
  /// restart, so a screen that read the flag once would keep showing a stale
  /// answer after the console changed. Widgets listen and re-render when a
  /// refresh lands.
  final isProdListenable = ValueNotifier<bool>(remoteDefaults[isProdKey]! as bool);

  bool get isProd => isProdListenable.value;

  /// Ticks once per activation, so a listener can re-read the keys it cares
  /// about without this class having to grow a notifier per key.
  final configRevision = ValueNotifier<int>(0);

  /// A string parameter, with the blank-value trap of [resolveIsProd] handled
  /// the same way: a parameter that exists in the console but carries no value
  /// comes back as an empty string and would otherwise shadow the in-app
  /// default. Blank is treated as "not configured".
  String remoteString(String key) {
    try {
      final raw = FirebaseRemoteConfig.instance.getString(key).trim();
      return raw.isEmpty ? remoteDefaults[key]! as String : raw;
    } catch (e) {
      // Firebase not up yet; the default is the honest answer.
      return remoteDefaults[key]! as String;
    }
  }

  /// A boolean parameter, blank-safe the same way [remoteString] is.
  bool remoteBool(String key) {
    final fallback = remoteDefaults[key]! as bool;
    try {
      final value = FirebaseRemoteConfig.instance.getValue(key);
      return value.asString().trim().isEmpty ? fallback : value.asBool();
    } catch (e) {
      return fallback;
    }
  }

  /// An integer parameter. Blank or non-numeric falls back to the default, so
  /// a typo in the console can never set a quota to zero by accident.
  int remoteInt(String key) {
    final fallback = remoteDefaults[key]! as int;
    try {
      final raw = FirebaseRemoteConfig.instance.getString(key).trim();
      return int.tryParse(raw) ?? fallback;
    } catch (e) {
      return fallback;
    }
  }

  /// Re-fetches and activates, then republishes the flag.
  ///
  /// Called on every app entry — launch and each resume — because Remote
  /// Config caches the last activated values on disk. Without it the app can
  /// run for a whole session on a value the console has already changed, which
  /// is exactly how a DEV badge outlived the condition that produced it.
  Future<void> refreshRemoteConfig() async {
    try {
      final config = FirebaseRemoteConfig.instance;
      await config.fetchAndActivate();
      _publishFlags(config);
    } catch (e) {
      debugPrint('Remote Config refresh failed: $e');
    }
  }

  /// A parameter that exists in the console but has no value comes back as an
  /// empty string, and that still counts as a *remote* value — it shadows the
  /// in-app default. `asBool("")` is false, so a blank console parameter would
  /// mark a production build as DEV. Blank is treated as "not configured" and
  /// falls back to the default instead.
  @visibleForTesting
  static bool resolveIsProd({required String raw, required bool parsed}) =>
      raw.trim().isEmpty ? remoteDefaults[isProdKey]! as bool : parsed;

  void _publishFlags(FirebaseRemoteConfig config) {
    final value = config.getValue(isProdKey);
    final raw = value.asString();
    final resolved = resolveIsProd(raw: raw, parsed: config.getBool(isProdKey));

    // Source says where the answer came from: `valueRemote` is the console,
    // `valueStatic`/`valueDefault` mean the in-app default is in play.
    debugPrint(
      'Remote Config $isProdKey="$raw" source=${value.source.name} '
      'lastFetch=${config.lastFetchStatus.name} resolved=$resolved',
    );
    isProdListenable.value = resolved;
    configRevision.value++;
  }

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

  /// Set by the app once the router exists; a tap before that is held in
  /// [_pendingTap] and delivered by [deliverPendingNotificationTap].
  VoidCallback? onNotificationOpened;
  bool _pendingTap = false;

  void _wireMessaging() {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('Foreground FCM message: ${message.notification?.title}');
    });
    FirebaseMessaging.onMessageOpenedApp.listen((_) => _notifyTap());
  }

  void _notifyTap() {
    final handler = onNotificationOpened;
    if (handler == null) {
      _pendingTap = true;
      return;
    }
    handler();
  }

  /// A push that *launched* the app is reported by `getInitialMessage`, not the
  /// stream; the app calls this once its router can navigate.
  Future<void> deliverPendingNotificationTap() async {
    try {
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null || _pendingTap) {
        _pendingTap = false;
        onNotificationOpened?.call();
      }
    } catch (e) {
      debugPrint('Initial message check failed: $e');
    }
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
      await config.setDefaults(remoteDefaults);
      await config.fetchAndActivate();
      _publishFlags(config);
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
