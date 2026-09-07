import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'device_locale_store.dart';
import 'firebase_service.dart';

/// What the running build owes the store, per Remote Config.
enum UpdateRequirement {
  /// Current, or the console has not been told otherwise.
  none,

  /// A newer build exists and the user may take it or leave it.
  optional,

  /// The running build is below `minimumVersion` and must not keep running.
  forced,
}

/// Decides whether this build has to be replaced, and takes the user to the
/// store when it does.
///
/// Two Remote Config parameters drive it. `minimumVersion` is the floor: below
/// it the app is blocked, which is the lever for a build that has to stop
/// talking to the backend — a broken write, a retired endpoint, a leaked
/// build. `latestVersion` is what is live in the stores; above the running
/// build it produces a dismissible prompt instead.
///
/// Both are compared against the app's own version name, so a release is
/// announced by editing the console — the store's own listing is never
/// scraped, and no build has to ship knowing what came after it.
class AppUpdateService {
  static final AppUpdateService _instance = AppUpdateService._internal();
  factory AppUpdateService() => _instance;
  AppUpdateService._internal();

  /// Shares [DeviceLocaleStore]'s device-wide box: a skipped update belongs to
  /// the install, not to whoever happens to be signed in, and it has to be
  /// readable before auth resolves.
  static const _skippedKey = 'skippedUpdateVersion';

  /// The gate widget listens; every activation of Remote Config re-publishes.
  final requirement = ValueNotifier<UpdateRequirement>(UpdateRequirement.none);

  String _current = '';
  String? _skipped;

  /// The version being offered, for the prompt's own copy.
  String get latestVersion => FirebaseService().remoteString(FirebaseService.latestVersionKey);

  /// Reads the running version and starts tracking the console. Safe to call
  /// before Firebase has finished starting: the first evaluation then uses the
  /// in-app defaults, and the listener re-runs it once a fetch activates.
  Future<void> init() async {
    _current = await _readCurrentVersion();
    _skipped = await _readSkipped();
    FirebaseService().configRevision.addListener(evaluate);
    evaluate();
  }

  /// Re-runs the decision against whatever Remote Config holds now.
  @visibleForTesting
  void evaluate() {
    final firebase = FirebaseService();
    requirement.value = decide(
      current: _current,
      minimum: firebase.remoteString(FirebaseService.minimumVersionKey),
      latest: firebase.remoteString(FirebaseService.latestVersionKey),
      skipped: _skipped,
    );
  }

  /// The whole rule, as a pure function so both branches can be exercised
  /// without a console or a package on disk.
  ///
  /// The forced check comes first and ignores [skipped] entirely — dismissing
  /// an optional prompt must not buy immunity from a floor that is raised
  /// afterwards.
  @visibleForTesting
  static UpdateRequirement decide({
    required String current,
    required String minimum,
    required String latest,
    String? skipped,
  }) {
    if ((compareVersions(current, minimum) ?? 0) < 0) return UpdateRequirement.forced;

    final behindStore = (compareVersions(current, latest) ?? 0) < 0;
    if (behindStore && compareVersions(skipped ?? '', latest) != 0) {
      return UpdateRequirement.optional;
    }
    return UpdateRequirement.none;
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

    for (var i = 0; i < (left.length > right.length ? left.length : right.length); i++) {
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

  /// Dismisses the optional prompt for [latestVersion] only. The next release
  /// asks again, and a raised floor overrides this outright.
  Future<void> skip() async {
    final latest = latestVersion;
    _skipped = latest;
    requirement.value = UpdateRequirement.none;
    try {
      await (await _box()).put(_skippedKey, latest);
    } catch (e) {
      // Losing the record only costs one extra prompt next launch.
      debugPrint('Skipped-update write failed: $e');
    }
  }

  /// The listing for this platform, or null when there is nothing to open —
  /// an iOS build before the App Store id has been set in the console.
  String? get storeUrl {
    if (Platform.isAndroid) {
      return 'https://play.google.com/store/apps/details?id=$androidPackageName';
    }
    if (Platform.isIOS) {
      final id = FirebaseService().remoteString(FirebaseService.iosAppStoreIdKey);
      return id.isEmpty ? null : 'https://apps.apple.com/app/id$id';
    }
    return null;
  }

  /// Matches `applicationId` in android/app/build.gradle.kts.
  static const androidPackageName = 'com.KHEasyDev.easy_plate';

  Future<void> openStore() async {
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

  Future<Box<String>> _box() => Hive.openBox<String>(DeviceLocaleStore.boxName);

  Future<String> _readCurrentVersion() async {
    try {
      return (await PackageInfo.fromPlatform()).version;
    } catch (e) {
      // Without a version to compare there is no honest verdict, and '' makes
      // every comparison return null — which reads as "no opinion".
      debugPrint('Package version read failed: $e');
      return '';
    }
  }

  Future<String?> _readSkipped() async {
    try {
      return (await _box()).get(_skippedKey);
    } catch (e) {
      debugPrint('Skipped-update read failed: $e');
      return null;
    }
  }
}
