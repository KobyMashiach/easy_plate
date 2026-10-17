import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';
import 'package:in_app_review/in_app_review.dart';

import '../features/features_flags.dart';

/// Asks the store for its own "rate this app" sheet at a good moment.
///
/// The sheet is the one Apple and Google draw themselves (SKStoreReviewController,
/// Play In-App Review), so the user never leaves the app and the rating lands
/// on the listing. Both platforms throttle how often the sheet actually shows,
/// and neither reports whether it did, so this service keeps its own, stricter
/// pacing: the second saved recipe is the first ask, then no more than once
/// every [cooldown], and never more than [maxAsks] in the life of the install.
///
/// Device-wide, not user-scoped: a second account on the same phone is the
/// same person holding the same store account.
class StoreReviewService {
  static final StoreReviewService _instance = StoreReviewService._internal();
  factory StoreReviewService() => _instance;
  StoreReviewService._internal();

  static const boxName = 'storeReviewBox';
  static const _successesKey = 'successes';
  static const _asksKey = 'asks';
  static const _lastAskKey = 'lastAskMillis';

  /// Saved recipes before the first ask: one may be a test, two is a habit.
  static const successesBeforeFirstAsk = 2;
  static const cooldown = Duration(days: 120);
  static const maxAsks = 3;

  /// Overrides for tests; null uses the real plugin and the real clock.
  @visibleForTesting
  static Future<bool> Function()? requestOverride;
  @visibleForTesting
  static DateTime Function() now = DateTime.now;

  Future<Box<int>> _open() => Hive.openBox<int>(boxName);

  /// Call after the user finished something worth being proud of (a recipe
  /// saved, for now). Decides on its own whether to ask, so callers never do.
  Future<void> onSuccessMoment() async {
    if (!FeaturesFlags.storeReview.isEnabled) return;
    try {
      final box = await _open();
      final successes = (box.get(_successesKey) ?? 0) + 1;
      await box.put(_successesKey, successes);
      if (!shouldAsk(
        successes: successes,
        asks: box.get(_asksKey) ?? 0,
        lastAskMillis: box.get(_lastAskKey),
      )) {
        return;
      }
      await box.put(_asksKey, (box.get(_asksKey) ?? 0) + 1);
      await box.put(_lastAskKey, now().millisecondsSinceEpoch);
      await _request();
    } catch (e) {
      debugPrint('Store review request failed: $e');
    }
  }

  /// The pacing rule on its own, for tests.
  static bool shouldAsk({
    required int successes,
    required int asks,
    required int? lastAskMillis,
  }) {
    if (asks >= maxAsks) return false;
    if (successes < successesBeforeFirstAsk) return false;
    if (lastAskMillis == null) return true;
    final last = DateTime.fromMillisecondsSinceEpoch(lastAskMillis);
    return now().difference(last) >= cooldown;
  }

  Future<bool> _request() async {
    final override = requestOverride;
    if (override != null) return override();
    final review = InAppReview.instance;
    if (!await review.isAvailable()) return false;
    await review.requestReview();
    return true;
  }
}
