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
      await _gatherConsent();
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

  Future<void> _gatherConsent() async {
    final updated = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () => updated.complete(),
      (error) {
        debugPrint('Consent info update failed: ${error.errorCode} ${error.message}');
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
