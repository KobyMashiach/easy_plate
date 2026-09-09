import 'dart:io';

import 'package:flutter/foundation.dart';

/// AdMob configuration.
///
/// Ad *unit* ids arrive through `--dart-define-from-file=dart_defines/dev.json`
/// so the real ones never sit in source. The *App* ids (the ones written with a
/// tilde) are a different thing: the SDK reads them from `AndroidManifest.xml`
/// and `Info.plist` at startup, and they have to be edited there.
///
/// Only two formats are used, on purpose: native cards inside the community
/// feeds, and rewarded video behind the daily quotas. No banners, no
/// interstitials, no app-open ads — every ad is either content-shaped or the
/// price of something the user chose to unlock.
abstract class AdsConfig {
  static const _nativeAndroid = String.fromEnvironment('ADMOB_NATIVE_AD_UNIT_ANDROID');
  static const _nativeIos = String.fromEnvironment('ADMOB_NATIVE_AD_UNIT_IOS');
  static const _rewardedAndroid = String.fromEnvironment('ADMOB_REWARDED_AD_UNIT_ANDROID');
  static const _rewardedIos = String.fromEnvironment('ADMOB_REWARDED_AD_UNIT_IOS');

  /// `true`/`false` to force; blank follows the build mode.
  static const _testAdsDefine = String.fromEnvironment('ADMOB_TEST_ADS');

  /// Google's sample units. They always fill, and — unlike a real unit — a
  /// developer tapping them cannot get the account flagged for invalid traffic.
  static const testNativeAndroid = 'ca-app-pub-3940256099942544/2247696110';
  static const testNativeIos = 'ca-app-pub-3940256099942544/3986624511';
  static const testRewardedAndroid = 'ca-app-pub-3940256099942544/5224354917';
  static const testRewardedIos = 'ca-app-pub-3940256099942544/1712485313';

  /// The id the native factories are registered under on both platforms.
  static const nativeFactoryId = 'easyPlateCard';

  /// Debug builds serve test ads unless told otherwise: clicks on a live unit
  /// from a developer's phone are exactly what AdMob suspends accounts for.
  static bool get useTestAds => resolveUseTestAds(_testAdsDefine, debug: kDebugMode);

  @visibleForTesting
  static bool resolveUseTestAds(String define, {required bool debug}) => switch (define) {
        'true' => true,
        'false' => false,
        _ => debug,
      };

  static bool get _isIos => !kIsWeb && Platform.isIOS;

  static String get nativeAdUnitId => resolveUnit(
        configured: _isIos ? _nativeIos : _nativeAndroid,
        test: _isIos ? testNativeIos : testNativeAndroid,
        useTest: useTestAds,
      );

  static String get rewardedAdUnitId => resolveUnit(
        configured: _isIos ? _rewardedIos : _rewardedAndroid,
        test: _isIos ? testRewardedIos : testRewardedAndroid,
        useTest: useTestAds,
      );

  /// A blank define falls back to the test unit rather than to an empty id,
  /// which the SDK would reject with a load error on every card — the iOS
  /// units, in particular, are not created yet.
  @visibleForTesting
  static String resolveUnit({
    required String configured,
    required String test,
    required bool useTest,
  }) =>
      useTest || configured.trim().isEmpty ? test : configured.trim();

  /// Ads only exist on the two mobile platforms; everywhere else (tests,
  /// desktop) the whole layer is a no-op.
  static bool get supported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);
}
