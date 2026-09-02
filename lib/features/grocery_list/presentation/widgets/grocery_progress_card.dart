import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/clay/clay.dart';

/// Collection progress panel: percentage, recessed progress groove, and the
/// collected/total count.
class GroceryProgressCard extends StatelessWidget {
  final int collected;
  final int total;

  const GroceryProgressCard({super.key, required this.collected, required this.total});

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : collected / total;

    return ClayCard(
      radius: AppRadius.xl,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(t.groceryList.collectionProgress, style: AppTextStyles.labelMd),
              ),
              Text(
                '${(ratio * 100).round()}%',
                style: AppTextStyles.headlineMd.copyWith(color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClayProgressBar(value: ratio),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Text(
              t.groceryList.itemsCollected(collected: collected, total: total),
              style: AppTextStyles.labelSm.copyWith(color: AppColors.outline),
            ),
          ),
        ],
      ),
    );
  }
}
