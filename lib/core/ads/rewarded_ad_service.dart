import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../constants/ads_config.dart';

/// How a rewarded video ended.
enum RewardOutcome {
  /// Watched through; the unlock is earned.
  earned,

  /// Closed before the reward point.
  dismissed,

  /// Nothing to show — no fill, offline, or the SDK refused.
  unavailable,
}

/// Keeps one rewarded video loaded and plays it on request.
///
/// A rewarded ad is loaded ahead of time because the load takes seconds, and
/// those seconds would otherwise sit between the user's tap and the video.
/// After each show the next one is fetched straight away.
class RewardedAdService {
  static final RewardedAdService _instance = RewardedAdService._internal();
  factory RewardedAdService() => _instance;
  RewardedAdService._internal();

  RewardedAd? _ad;
  Completer<void>? _loading;
  int _consecutiveFailures = 0;

  /// How long [show] waits for an in-flight load before giving up.
  static const loadTimeout = Duration(seconds: 8);

  /// Past this many failed loads in a row the service stops retrying on its
  /// own and waits for the next [show] to try again — a unit with no fill
  /// would otherwise poll AdMob for the whole session.
  static const maxAutoRetries = 3;

  bool get isReady => _ad != null;

  /// Fetches the next video unless one is loaded or loading already.
  Future<void> preload() {
    if (!AdsConfig.supported || _ad != null) return Future.value();
    final inFlight = _loading;
    if (inFlight != null) return inFlight.future;

    final completer = Completer<void>();
    _loading = completer;
    RewardedAd.load(
      adUnitId: AdsConfig.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _consecutiveFailures = 0;
          _loading = null;
          completer.complete();
        },
        onAdFailedToLoad: (error) {
          debugPrint('Rewarded ad failed to load: ${error.code} ${error.message}');
          _consecutiveFailures++;
          _loading = null;
          completer.complete();
        },
      ),
    );
    return completer.future;
  }

  /// Plays the loaded video and reports how it ended. Waits briefly for a
  /// load that is still in flight; a load that has not even started is kicked
  /// off and waited for the same way.
  Future<RewardOutcome> show() async {
    if (!AdsConfig.supported) return RewardOutcome.unavailable;

    if (_ad == null) {
      try {
        await preload().timeout(loadTimeout);
      } on TimeoutException {
        debugPrint('Rewarded ad not ready within $loadTimeout');
      }
    }

    final ad = _ad;
    if (ad == null) return RewardOutcome.unavailable;
    _ad = null;

    final outcome = Completer<RewardOutcome>();
    var earned = false;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (!outcome.isCompleted) {
          outcome.complete(earned ? RewardOutcome.earned : RewardOutcome.dismissed);
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('Rewarded ad failed to show: ${error.code} ${error.message}');
        ad.dispose();
        if (!outcome.isCompleted) outcome.complete(RewardOutcome.unavailable);
      },
    );

    try {
      await ad.show(onUserEarnedReward: (_, reward) => earned = true);
    } catch (e) {
      debugPrint('Rewarded ad show threw: $e');
      if (!outcome.isCompleted) outcome.complete(RewardOutcome.unavailable);
    }

    final result = await outcome.future;
    // The next one, so the following unlock has no wait. Bounded: after a run
    // of failures the next show() is what tries again.
    if (_consecutiveFailures < maxAutoRetries) unawaited(preload());
    return result;
  }
}
