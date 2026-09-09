import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../constants/ads_config.dart';
import '../utils/i18n/strings.g.dart';

/// One native ad position in a feed, loading itself once.
class NativeAdSlot extends ChangeNotifier {
  NativeAd? _ad;
  bool _loaded = false;
  bool _failed = false;
  bool _disposed = false;

  bool get isLoaded => _loaded;
  bool get isFailed => _failed;
  NativeAd? get ad => _loaded ? _ad : null;

  void load() {
    if (_ad != null || !AdsConfig.supported) return;
    _ad = NativeAd(
      adUnitId: AdsConfig.nativeAdUnitId,
      factoryId: AdsConfig.nativeFactoryId,
      request: const AdRequest(),
      // Read by both native factories: the badge and the text direction
      // follow the app's language rather than the device's, since the card is
      // a platform view and cannot see the Flutter Directionality above it.
      customOptions: {
        'badge': t.ads.badge,
        'rtl': _isRtl(LocaleSettings.currentLocale.languageCode),
      },
      nativeAdOptions: NativeAdOptions(
        adChoicesPlacement: AdChoicesPlacement.topRightCorner,
        mediaAspectRatio: MediaAspectRatio.landscape,
      ),
      listener: NativeAdListener(
        onAdLoaded: (_) {
          if (_disposed) return;
          _loaded = true;
          notifyListeners();
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Native ad failed to load: ${error.code} ${error.message}');
          ad.dispose();
          if (_disposed) return;
          _ad = null;
          _failed = true;
          notifyListeners();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _disposed = true;
    _ad?.dispose();
    _ad = null;
    super.dispose();
  }
}

bool _isRtl(String languageCode) => languageCode == 'he' || languageCode == 'ar';

/// The native ads of one feed, by position, owned by the feed's state.
///
/// Held outside the list builder so scrolling, liking and filtering rebuild
/// the rows without re-requesting the ads: each slot is loaded once and
/// stays loaded until the feed goes away.
class FeedAdPool {
  /// Ads per feed are capped — past this many, further ad positions render
  /// nothing. A long feed does not need a fresh request every five rows.
  static const maxAds = 8;

  final Map<int, NativeAdSlot> _slots = {};

  /// The slot for the [adIndex]-th ad, loading it on first request; null past
  /// [maxAds].
  NativeAdSlot? slot(int adIndex) {
    if (adIndex >= maxAds) return null;
    return _slots.putIfAbsent(adIndex, () => NativeAdSlot()..load());
  }

  void dispose() {
    for (final slot in _slots.values) {
      slot.dispose();
    }
    _slots.clear();
  }
}
