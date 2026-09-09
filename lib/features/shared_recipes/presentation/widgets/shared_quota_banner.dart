import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/monetization/daily_quota_policy.dart';
import '../../../../core/monetization/daily_usage_service.dart';
import '../../../../core/monetization/entitlement_service.dart';
import '../../../../core/monetization/monetization_config.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/utils/i18n/strings.g.dart';

/// The day's shared-recipe allowance, in one line above the feed.
///
/// Three wordings, one per stage of the day: free openings left, then
/// video-unlocked openings left, then "come back tomorrow". Hidden entirely
/// for premium accounts and when ads are switched off — a counter for a
/// limit that does not apply would only raise questions.
class SharedQuotaBanner extends StatefulWidget {
  const SharedQuotaBanner({super.key});

  @override
  State<SharedQuotaBanner> createState() => _SharedQuotaBannerState();
}

/// One wording per stage of the day.
class _Stage {
  final IconData icon;
  final String text;
  final Color background;
  final Color foreground;

  const _Stage(this.icon, this.text, this.background, this.foreground);
}

_Stage _stageFor(int free, int rewarded) {
  if (free > 0) {
    return _Stage(
      Icons.lock_open_rounded,
      t.ads.freeViewsLeft(count: free),
      AppColors.primaryFixed,
      AppColors.primary,
    );
  }
  if (rewarded > 0) {
    return _Stage(
      Icons.play_circle_outline_rounded,
      t.ads.rewardedViewsLeft(count: rewarded),
      AppColors.tertiaryFixed,
      AppColors.onTertiaryFixedVariant,
    );
  }
  return _Stage(
    Icons.lock_clock_rounded,
    t.ads.sharedQuotaReached,
    AppColors.surfaceContainerHighest,
    AppColors.onSurfaceVariant,
  );
}

class _SharedQuotaBannerState extends State<SharedQuotaBanner> {
  late final Listenable _sources = Listenable.merge([
    DailyUsageService(),
    EntitlementService(),
    FirebaseService().configRevision,
  ]);

  @override
  void initState() {
    super.initState();
    DailyUsageService().ensureLoaded();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _sources,
      builder: (context, _) {
        if (MonetizationConfig.adFree) return const SizedBox.shrink();

        final usage = DailyUsageService();
        final limits = MonetizationConfig.limits;
        final viewed = usage.sharedViewsToday;
        final free = DailyQuotaPolicy.remainingFreeSharedViews(viewed, limits);
        final rewarded = DailyQuotaPolicy.remainingRewardedSharedViews(viewed, limits);

        final _Stage(:icon, :text, :background, :foreground) = _stageFor(free, rewarded);

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.base,
            ),
            decoration: ShapeDecoration(color: background, shape: const StadiumBorder()),
            child: Row(
              children: [
                Icon(icon, size: 16, color: foreground),
                const SizedBox(width: AppSpacing.base),
                Expanded(
                  child: Text(
                    text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelSm.copyWith(color: foreground),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
