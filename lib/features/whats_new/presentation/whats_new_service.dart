import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/features/features_flags.dart';
import '../../../core/services/auth_session_service.dart';
import '../../../core/utils/routing/routing.dart';
import '../../user_profile/domain/entities/user_preferences_entity.dart';
import '../../user_profile/domain/repositories/user_preferences_repository.dart';
import '../data/whats_new_repository.dart';
import '../domain/entities/whats_new_release.dart';
import '../domain/whats_new_delta.dart';

/// What the book route is opened with: the pages to show and the build the
/// acknowledgement stamps.
class WhatsNewArgs {
  final List<WhatsNewPage> pages;
  final int build;

  const WhatsNewArgs({required this.pages, required this.build});
}

/// Decides, once per account per process, whether the returning account is
/// owed a "what's new" book, and opens it over the home screen. The
/// onboarding stamps the build a new account arrives on, so a fresh install
/// never sees the book; a returning account sees every published release
/// between the build it last acknowledged and the one running.
class WhatsNewService {
  static final WhatsNewService _instance = WhatsNewService._internal();
  factory WhatsNewService() => _instance;
  WhatsNewService._internal();

  /// Replaceable for tests; the Firestore one otherwise.
  WhatsNewRepository repository = FirestoreWhatsNewRepository();

  /// For tests, in place of the package's build number.
  @visibleForTesting
  int? buildOverride;

  int? _build;

  /// The account the book was offered to in this process, so a locale
  /// change — which rebuilds the home screen — does not offer it twice.
  String? _offeredTo;

  /// The running build number (`+12` in pubspec), or null when the package
  /// cannot be read — then there is no honest comparison and nothing is
  /// shown or stamped.
  Future<int?> currentBuild() async {
    if (buildOverride != null) return buildOverride;
    if (_build != null) return _build;
    try {
      final info = await PackageInfo.fromPlatform();
      return _build = int.tryParse(info.buildNumber.trim());
    } catch (e) {
      debugPrint('Package build read failed: $e');
      return null;
    }
  }

  /// Whether a feature's page may be drawn for this account: on, or
  /// Premium-only (drawn with a tag) — hidden and "coming soon" are not.
  /// A key that names no flag of ours is shown as it is.
  static bool isFeatureShown(String featureKey) {
    for (final flag in FeaturesFlags.values) {
      if (flag.key != featureKey) continue;
      final access = flag.access;
      return access.isEnabled || access.isLocked;
    }
    return true;
  }

  /// Shows the book if one is due. Called from the home screen once it is
  /// up, after the first-run tour has had its chance.
  Future<void> offer(
    BuildContext context,
    UserPreferencesRepository preferences,
  ) async {
    final uid = AuthSessionService().user?.uid;
    if (uid == null || _offeredTo == uid) return;
    // Switched off in the console: the pointer is left alone, so the day
    // the flag comes back the account is shown what it missed.
    if (!FeaturesFlags.whatsNew.isEnabled) return;
    _offeredTo = uid;

    final build = await currentBuild();
    if (build == null) return;
    final UserPreferencesEntity current;
    try {
      current = await preferences.getPreferences();
    } catch (e) {
      // Not "nothing new": next launch asks again.
      debugPrint('What\'s new preferences read failed: $e');
      _offeredTo = null;
      return;
    }
    if (!current.onboardingComplete) return;
    final lastSeen = current.whatsNewSeenBuild;
    if (!whatsNewMayBeDue(currentBuild: build, lastSeenBuild: lastSeen)) {
      return;
    }

    final releases = await repository.getReleasesBetween(
      lastSeen ?? build - 1,
      build,
    );
    // A failed read is not "nothing new": next launch asks again.
    if (releases == null) {
      _offeredTo = null;
      return;
    }
    final pages = computeWhatsNewPages(
      releases: releases,
      currentBuild: build,
      lastSeenBuild: lastSeen,
      isFeatureShown: isFeatureShown,
    );
    // Nothing to show yet: the pointer is left alone. An early updater may
    // be ahead of the release the admin has not published yet, and a
    // stamp now would skip it for good.
    if (pages.isEmpty) return;
    if (!context.mounted) return;
    await context.pushNamed(
      Routing.whatsNew,
      extra: WhatsNewArgs(pages: pages, build: build),
    );
  }

  /// Opens the newest published release again, from the support screen.
  Future<bool> openLatest(
    BuildContext context, {
    int? build,
  }) async {
    final current = build ?? await currentBuild();
    if (current == null) return false;
    final release = await repository.latestPublished(current);
    if (release == null) return false;
    final pages = computeWhatsNewPages(
      releases: [release],
      currentBuild: release.versionCode,
      lastSeenBuild: release.versionCode - 1,
      isFeatureShown: isFeatureShown,
    );
    if (pages.isEmpty || !context.mounted) return false;
    // Stamped with the release shown, not the running build: a replay must
    // not mark releases the launch offer never got to show as seen.
    await context.pushNamed(
      Routing.whatsNew,
      extra: WhatsNewArgs(pages: pages, build: release.versionCode),
    );
    return true;
  }

  /// Stamps [build] as acknowledged. Never moves the pointer backwards: a
  /// replay from the support screen on an older build changes nothing.
  Future<void> acknowledge(
    UserPreferencesRepository preferences,
    int build,
  ) async {
    try {
      final latest = await preferences.getPreferences();
      if ((latest.whatsNewSeenBuild ?? -1) >= build) return;
      await preferences.savePreferences(
        latest.copyWith(whatsNewSeenBuild: build),
      );
    } catch (e) {
      debugPrint('What\'s new acknowledge failed: $e');
    }
  }

  /// For tests: forget which account was offered the book.
  @visibleForTesting
  void reset() {
    _offeredTo = null;
    _build = null;
    buildOverride = null;
  }
}
