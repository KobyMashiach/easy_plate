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

/// What the day's AI link extractions cost, and how many are left.
///
/// Sits above the analyse button on the link and video channels. Two states:
/// a play icon with "2/2 left today" while extractions remain, and a lock
/// once they are spent. Hidden for premium accounts and when ads are off.
class AiQuotaIndicator extends StatefulWidget {
  const AiQuotaIndicator({super.key});

  @override
  State<AiQuotaIndicator> createState() => _AiQuotaIndicatorState();
}

class _AiQuotaIndicatorState extends State<AiQuotaIndicator> {
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

        final limits = MonetizationConfig.limits;
        final remaining = DailyQuotaPolicy.remainingAiExtractions(
          DailyUsageService().aiExtractionsToday,
          limits,
        );
        final blocked = remaining == 0;
        final foreground = blocked ? AppColors.onSurfaceVariant : AppColors.primary;

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.base,
            ),
            decoration: ShapeDecoration(
              color: blocked ? AppColors.surfaceContainerHighest : AppColors.primaryFixed,
              shape: const StadiumBorder(),
            ),
            child: Row(
              children: [
                Icon(
                  blocked ? Icons.lock_outline_rounded : Icons.play_circle_outline_rounded,
                  size: 16,
                  color: foreground,
                ),
                const SizedBox(width: AppSpacing.base),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        blocked
                            ? t.ads.aiQuotaReached
                            : t.ads.aiQuotaLeft(
                                remaining: remaining,
                                total: limits.rewardedAiExtractions,
                              ),
                        style: AppTextStyles.labelSm.copyWith(color: foreground),
                      ),
                      if (!blocked)
                        Text(
                          t.ads.aiLockedHint,
                          style: AppTextStyles.labelSm.copyWith(
                            color: AppColors.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
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
