import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../../../core/widgets/nutrition/nutrition_widgets.dart';
import '../../domain/entities/nutrition_entity.dart';

/// The per-serving nutrition of a recipe: the ring, the three macro bars, and
/// — before anything has been estimated — the button that asks the model.
class NutritionFactsCard extends StatelessWidget {
  final NutritionEntity? nutrition;
  final int? servings;
  final bool estimating;

  /// Null hides the estimate action (read-only, or nothing to estimate from).
  final VoidCallback? onEstimate;

  const NutritionFactsCard({
    super.key,
    required this.nutrition,
    required this.servings,
    required this.estimating,
    required this.onEstimate,
  });

  @override
  Widget build(BuildContext context) {
    final n = nutrition;
    return ClayCard(
      radius: AppRadius.md,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: ClaySectionHeader(title: t.nutrition.title, underline: true)),
              if (n != null)
                Text(
                  t.nutrition.perServing,
                  style: AppTextStyles.labelMd.copyWith(color: AppColors.onSurfaceVariant),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.gutter),
          if (n == null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: AppColors.primaryFixed, shape: BoxShape.circle),
                  child: Icon(Icons.auto_awesome_rounded, color: AppColors.primary),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.nutrition.none, style: AppTextStyles.bodyMd),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        t.nutrition.noneHint,
                        style: AppTextStyles.labelMd.copyWith(color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (onEstimate != null) ...[
              const SizedBox(height: AppSpacing.gutter),
              ClayButton(
                label: estimating ? t.nutrition.estimating : t.nutrition.estimate,
                icon: Icons.auto_awesome_rounded,
                expanded: true,
                onPressed: estimating ? null : onEstimate,
              ),
            ],
          ] else ...[
            Row(
              children: [
                MacroRing(nutrition: n, size: 120, thickness: 12),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    children: [
                      for (final macro in Macro.values) ...[
                        MacroBar(macro: macro, nutrition: n),
                        if (macro != Macro.values.last) const SizedBox(height: AppSpacing.sm),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (onEstimate != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton.icon(
                  onPressed: estimating ? null : onEstimate,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: Text(estimating ? t.nutrition.estimating : t.nutrition.estimate),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
