import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../constants/ads_config.dart';
import 'rewarded_ad_service.dart';

/// Boots the Mobile Ads SDK: consent first, then initialisation, then the
/// first rewarded video is fetched so it is ready before anyone asks.
///
/// Consent goes through Google's User Messaging Platform. Outside the regions
/// that require it nothing is shown; inside them the form appears once and the
/// answer is remembered by the SDK. Ads are only requested once
/// `canRequestAds()` says so, which is also true when a previous answer is on
/// file and the network is down.
class AdsService {
  static final AdsService _instance = AdsService._internal();
  factory AdsService() => _instance;
  AdsService._internal();

  bool _initialized = false;

  bool get isInitialized => _initialized;

  /// Never awaited from `main`: a slow consent lookup must not delay the
  /// first frame, and an ad that arrives a second late costs nothing.
  Future<void> init() async {
    if (!AdsConfig.supported || _initialized) return;
    try {
      // An SDK that never calls back would otherwise hold this forever;
      // past the limit there is no consent answer, so ads stay off for this
      // session and the next launch asks again.
      if (!await withinConsentTimeout(_gatherConsent)) {
        debugPrint('Ads: consent lookup timed out, ads off this session');
        return;
      }
      if (!await ConsentInformation.instance.canRequestAds()) {
        debugPrint('Ads: consent not given, SDK left uninitialised');
        return;
      }
      await MobileAds.instance.initialize();
      _initialized = true;
      unawaited(RewardedAdService().preload());
    } catch (e) {
      debugPrint('Ads init failed: $e');
    }
  }

  /// How long the consent lookup (and the form, when one is shown) may take.
  static const consentTimeout = Duration(seconds: 15);

  /// Runs [gather], true when it finished within [timeout]. A gather that
  /// failed counts as finished: the SDK's own answer decides afterwards.
  @visibleForTesting
  static Future<bool> withinConsentTimeout(
    Future<void> Function() gather, {
    Duration timeout = consentTimeout,
  }) async {
    try {
      await gather().timeout(timeout);
      return true;
    } on TimeoutException {
      return false;
    }
  }

  Future<void> _gatherConsent() async {
    final updated = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () => updated.complete(),
      (error) {
        debugPrint(
          'Consent info update failed: ${error.errorCode} ${error.message}',
        );
        updated.complete();
      },
    );
    await updated.future;

    final shown = Completer<void>();
    ConsentForm.loadAndShowConsentFormIfRequired((error) {
      if (error != null) {
        debugPrint('Consent form failed: ${error.errorCode} ${error.message}');
      }
      shown.complete();
    });
    await shown.future;
  }
}
