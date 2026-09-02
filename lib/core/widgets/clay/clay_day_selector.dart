import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../constants/app_text_styles.dart';
import 'clay_card.dart';

/// Horizontally scrolling row of 72x90 clay day tiles. The active day inverts
/// to the primary container fill, per the Stitch meal-plan screen.
class ClayDaySelector extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  /// Optional badge count per day (e.g. how many meals are planned).
  final List<int>? counts;

  const ClayDaySelector({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
    this.counts,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.marginMobile),
        itemCount: labels.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final isActive = index == selectedIndex;
          final count = counts?[index] ?? 0;
          final foreground = isActive ? AppColors.onPrimaryContainer : AppColors.primary;

          return SizedBox(
            width: 72,
            child: ClayCard(
              radius: AppRadius.md,
              isActive: isActive,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              onTap: () => onSelected(index),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    labels[index],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelSm.copyWith(
                      color: isActive ? AppColors.primaryFixed : AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '$count',
                    style: AppTextStyles.headlineMd.copyWith(color: foreground),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
