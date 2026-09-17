import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../../../core/widgets/nutrition/nutrition_widgets.dart';
import '../../domain/nutrition_summary.dart';
import '../../../../core/walkthrough/app_walkthroughs.dart';
import '../../../../core/walkthrough/walkthrough.dart';

/// The selected day's plate, added up: a macro ring with the calories in it,
/// the grams beside it, and the way into the week's dashboard.
class DayNutritionCard extends StatelessWidget {
  final DayNutrition day;
  final VoidCallback onOpenDashboard;

  const DayNutritionCard({super.key, required this.day, required this.onOpenDashboard});

  @override
  Widget build(BuildContext context) {
    return ClayCard(
      radius: AppRadius.md,
      padding: const EdgeInsets.all(AppSpacing.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: ClaySectionHeader(title: t.nutrition.dayTotal)),
              WalkthroughTarget(
                id: WalkthroughIds.mealPlanDashboard,
                child: ClayIconButton(
                  icon: Icons.insights_rounded,
                  filled: true,
                  size: 40,
                  tooltip: t.nutrition.openDashboard,
                  onTap: onOpenDashboard,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (!day.hasData)
            Row(
              children: [
                MacroRing(
                  nutrition: day.total,
                  size: 88,
                  thickness: 10,
                  center: Icon(Icons.restaurant_rounded, color: AppColors.outline),
                ),
                const SizedBox(width: AppSpacing.gutter),
                Expanded(
                  child: Text(
                    t.nutrition.noPlanned,
                    style: AppTextStyles.labelMd.copyWith(color: AppColors.onSurfaceVariant),
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                MacroRing(nutrition: day.total, size: 104, thickness: 11),
                const SizedBox(width: AppSpacing.gutter),
                Expanded(child: MacroLegend(nutrition: day.total)),
              ],
            ),
          if (day.missingItems > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 14, color: AppColors.outline),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    t.nutrition.missingCount(count: day.missingItems),
                    style: AppTextStyles.labelSm.copyWith(color: AppColors.outline),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
