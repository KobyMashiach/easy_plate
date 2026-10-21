import 'dart:async';
import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'firebase_service.dart';

/// What the running build owes the store, per Remote Config and the store.
enum UpdateRequirement {
  /// Current, or nobody has said otherwise.
  none,

  /// A newer build is in this platform's store and the user may take it or
  /// leave it.
  optional,

  /// The running build is below `minimumVersion` and must not keep running.
  forced,
}

/// What this platform's store answered when asked for its newest release.
///
/// [version] is the store's own label — the marketing version on iOS, the
/// build number on Android (Play reports a version code, not a name) — and
/// is only used to tell one release from the next, never shown as a number.
/// [storeUrl] is the listing, when the store told us where it is.
@immutable
class StoreRelease {
  final String version;
  final bool newer;
  final String? storeUrl;

  const StoreRelease({
    required this.version,
    required this.newer,
    this.storeUrl,
  });

  @override
  String toString() => 'StoreRelease($version, newer: $newer)';
}

/// Asks the store; null when it had no answer (offline, sideloaded build,
/// no listing yet). Injectable so the rule can be tested without a store.
typedef StoreProbe = Future<StoreRelease?> Function(PackageInfo installed);

/// Decides whether this build has to be replaced, and takes the user to the
/// store when it does.
///
/// Two sources drive it. Remote Config `minimumVersion` is the floor: below it
/// the app is blocked, which is the lever for a build that has to stop talking
/// to the backend — a broken write, a retired endpoint, a leaked build. The
/// platform's own store says what is live for *this* user: Play Core on
/// Android (which also knows about staged rollouts the device is in), the
/// iTunes lookup API on iOS. A newer store build produces a dismissible
/// prompt, so a release is announced by the store itself — nothing to edit in
/// the console, and Android and iOS can be on different versions.
class AppUpdateService {
  static final AppUpdateService _instance = AppUpdateService._internal();
  factory AppUpdateService() => _instance;
  AppUpdateService._internal();

  /// The gate widget listens; every activation of Remote Config re-publishes.
  final requirement = ValueNotifier<UpdateRequirement>(UpdateRequirement.none);

  String _current = '';
  PackageInfo? _installed;

  /// The store's answer for this process, once asked. Asked on launch only:
  /// the optional prompt is a fresh-entry thing (see [_wentToBackground]),
  /// so a later answer would have nowhere to go.
  StoreRelease? _store;

  /// The release "Skip" was tapped on. Kept in memory only, so every fresh
  /// launch asks again — but a return from the background does not.
  String? _skipped;

  /// Set once the app has been in the background: from then on, in this
  /// process, no optional prompt is raised. The prompt belongs to a fresh
  /// entry into the app, not to coming back to it mid-task (Koby, after
  /// it kept popping up on every return). A forced update is never held.
  bool _wentToBackground = false;
  AppLifecycleListener? _lifecycle;

  /// Overridable for tests; the default asks the real store.
  @visibleForTesting
  StoreProbe probe = probeStore;

  /// The version being offered, for the skip bookkeeping. Empty when the
  /// store has not answered.
  String get latestVersion => _store?.version ?? '';

  /// What the store reported, for the admin dashboard. Null until asked, or
  /// when the store had no answer.
  StoreRelease? get storeRelease => _store;

  /// Reads the running version, asks the store once, and starts tracking the
  /// console. Safe to call before Firebase has finished starting: the first
  /// evaluation then uses the in-app defaults, and the listener re-runs it
  /// once a fetch activates.
  Future<void> init() async {
    _installed = await _readInstalled();
    _current = _installed?.version ?? '';
    _lifecycle ??= AppLifecycleListener(
      onHide: () => _wentToBackground = true,
      onPause: () => _wentToBackground = true,
    );
    FirebaseService().configRevision.addListener(evaluate);
    evaluate();
    // Not awaited: `main` waits on init before the first frame, and the
    // store is a network round trip (Play Core, or Apple's lookup with two
    // storefronts to try). The gate listens to [requirement], so an answer
    // that lands after the first frame still raises the prompt.
    unawaited(refreshStore());
  }

  /// Asks the store for its newest release and re-runs the decision. The
  /// floor is checked regardless, so a store that does not answer costs
  /// nothing but the optional prompt.
  Future<void> refreshStore() async {
    final installed = _installed;
    if (installed == null) return;
    try {
      _store = await probe(installed);
    } catch (e) {
      debugPrint('Store version check failed: $e');
      _store = null;
    }
    evaluate();
  }

  /// Re-runs the decision against whatever Remote Config and the store hold.
  @visibleForTesting
  void evaluate() {
    requirement.value = decide(
      current: _current,
      minimum: FirebaseService().remoteString(
        FirebaseService.minimumVersionKey,
      ),
      store: _store,
      skipped: _skipped,
      optionalAllowed: !_wentToBackground,
    );
  }

  /// The whole rule, as a pure function so both branches can be exercised
  /// without a console or a store.
  ///
  /// The forced check comes first and ignores [skipped], [store] and
  /// [optionalAllowed] entirely — dismissing an optional prompt, or being
  /// mid-task, must not buy immunity from a floor that is raised afterwards.
  /// [optionalAllowed] is false once the app has been in the background
  /// (see [_wentToBackground]).
  @visibleForTesting
  static UpdateRequirement decide({
    required String current,
    required String minimum,
    StoreRelease? store,
    String? skipped,
    bool optionalAllowed = true,
  }) {
    if ((compareVersions(current, minimum) ?? 0) < 0) {
      return UpdateRequirement.forced;
    }

    if (!optionalAllowed) return UpdateRequirement.none;
    if (store == null || !store.newer) return UpdateRequirement.none;
    // [skipped] lives until the app is next launched (see [_skipped]).
    return skipped == store.version
        ? UpdateRequirement.none
        : UpdateRequirement.optional;
  }

  /// Compares dotted version names numerically, so `1.10.0` is above `1.9.0`
  /// where a string compare would have it below. A missing segment counts as
  /// zero, and a build suffix (`1.2.3+45`) is dropped — the stores compare the
  /// marketing version, and so does the console.
  ///
  /// Null when either side has no numeric segment at all. Callers treat that as
  /// "no opinion" rather than as an ordering: a typo in the console must not be
  /// what locks an install out.
  @visibleForTesting
  static int? compareVersions(String a, String b) {
    final left = _segments(a);
    final right = _segments(b);
    if (left.isEmpty || right.isEmpty) return null;

    for (
      var i = 0;
      i < (left.length > right.length ? left.length : right.length);
      i++
    ) {
      final l = i < left.length ? left[i] : 0;
      final r = i < right.length ? right[i] : 0;
      if (l != r) return l < r ? -1 : 1;
    }
    return 0;
  }

  static List<int> _segments(String version) {
    final marketing = version.split('+').first.trim();
    if (marketing.isEmpty) return const [];
    final parts = marketing.split('.');
    final segments = <int>[];
    for (final part in parts) {
      final digits = RegExp(r'\d+').stringMatch(part);
      if (digits == null) return const [];
      segments.add(int.parse(digits));
    }
    return segments;
  }

  /// Dismisses the optional prompt for the store's release until the app is
  /// next launched. A raised floor overrides this outright.
  void skip() {
    _skipped = latestVersion;
    requirement.value = UpdateRequirement.none;
  }

  /// The listing for this platform, or null when there is nothing to open —
  /// an iOS build whose store lookup failed before the App Store id has been
  /// set in the console.
  String? get storeUrl {
    final fromStore = _store?.storeUrl;
    if (fromStore != null && fromStore.isNotEmpty) return fromStore;
    if (Platform.isAndroid) {
      return 'https://play.google.com/store/apps/details?id=$androidPackageName';
    }
    if (Platform.isIOS) {
      final id = FirebaseService().remoteString(
        FirebaseService.iosAppStoreIdKey,
      );
      return id.isEmpty ? null : 'https://apps.apple.com/app/id$id';
    }
    return null;
  }

  /// Matches `applicationId` in android/app/build.gradle.kts.
  static const androidPackageName = 'com.KHEasyDev.easy_plate';

  /// On Android, Play's own in-app update flow first (the user never leaves
  /// the app); the store listing when that is not possible, and on iOS.
  Future<void> openStore() async {
    if (Platform.isAndroid) {
      try {
        final result = await InAppUpdate.performImmediateUpdate();
        if (result == AppUpdateResult.success) return;
      } catch (e) {
        debugPrint('In-app update unavailable: $e');
      }
    }
    final url = storeUrl;
    if (url == null) {
      debugPrint('No store listing configured for this platform');
      return;
    }
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Store launch failed: $e');
    }
  }

  Future<PackageInfo?> _readInstalled() async {
    try {
      return await PackageInfo.fromPlatform();
    } catch (e) {
      // Without a version to compare there is no honest verdict, and '' makes
      // every comparison return null — which reads as "no opinion".
      debugPrint('Package version read failed: $e');
      return null;
    }
  }

  /// Asks this platform's store what it has for [installed].
  ///
  /// Android: Play Core, which answers for the account and rollout track the
  /// device is on and throws for a build Play did not install — a sideloaded
  /// debug build reads as "no opinion". iOS: Apple's public lookup by bundle
  /// id, tried on the device's storefront first and the default one after,
  /// since an app not released in a country is absent from its answer.
  static Future<StoreRelease?> probeStore(PackageInfo installed) async {
    if (Platform.isAndroid) {
      final info = await InAppUpdate.checkForUpdate();
      final code = info.availableVersionCode;
      return StoreRelease(
        version: code == null ? 'play' : 'build $code',
        newer: info.updateAvailability == UpdateAvailability.updateAvailable,
      );
    }
    if (Platform.isIOS) {
      return _probeAppStore(installed);
    }
    return null;
  }

  static Future<StoreRelease?> _probeAppStore(PackageInfo installed) async {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
      ),
    );
    final locale = Platform.localeName; // e.g. he_IL
    final country = locale.contains('_')
        ? locale.split('_').last.split('.').first
        : '';
    for (final storefront in [country, '']) {
      if (storefront.isEmpty && country.isEmpty) continue;
      final response = await dio.get<Map<String, dynamic>>(
        'https://itunes.apple.com/lookup',
        queryParameters: {
          'bundleId': installed.packageName,
          if (storefront.isNotEmpty) 'country': storefront,
        },
      );
      final results = response.data?['results'];
      if (results is! List || results.isEmpty) continue;
      final first = results.first;
      if (first is! Map) continue;
      final version = first['version'];
      if (version is! String || version.isEmpty) continue;
      return StoreRelease(
        version: version,
        newer: (compareVersions(installed.version, version) ?? 0) < 0,
        storeUrl: first['trackViewUrl'] is String
            ? first['trackViewUrl'] as String
            : null,
      );
    }
    return null;
  }
}
