import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../constants/app_colors.dart';
import '../constants/app_shadows.dart';
import '../constants/app_spacing.dart';
import 'feed_ad_pool.dart';

/// A native ad drawn as a feed card.
///
/// The frame — white clay, `AppRadius.md` corners, the lavender lift — is the
/// same one `ClayCard` draws, so the card sits in the feed as one of its own.
/// The inside is a platform view built by the native factories (Android:
/// `EasyPlateNativeAdFactory.kt`, iOS: `EasyPlateNativeAdFactory.swift`),
/// which lay the ad's assets out in the same palette and type scale.
///
/// Collapses to nothing until the ad has loaded, and stays collapsed if it
/// never does: an empty frame waiting for an advertiser is not content.
class NativeAdCard extends StatelessWidget {
  final NativeAdSlot slot;

  /// Matches the native layout: 16dp padding, a 56dp icon row, two lines of
  /// body, and a 40dp call-to-action pill.
  static const height = 156.0;

  const NativeAdCard({super.key, required this.slot});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: slot,
      builder: (context, _) {
        final ad = slot.ad;
        if (ad == null) return const SizedBox.shrink();

        final radius = BorderRadius.circular(AppRadius.md);
        return DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: radius,
            border: Border.all(color: AppColors.surfaceContainerHighest),
            boxShadow: AppShadows.card,
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: SizedBox(height: height, child: AdWidget(ad: ad)),
          ),
        );
      },
    );
  }
}
