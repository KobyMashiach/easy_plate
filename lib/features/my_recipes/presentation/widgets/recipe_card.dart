import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../../../core/widgets/dietary_chip_selector.dart';
import '../../domain/entities/recipe_entity.dart';

/// Horizontal recipe card matching the Stitch "Recently Added" bento tile:
/// a soft thumbnail block, tag row, title and supporting line.
///
/// Recipes carry no imagery in this app, so the thumbnail is a tinted
/// medallion rather than a photo.
class RecipeCard extends StatelessWidget {
  final RecipeEntity recipe;
  final VoidCallback onTap;

  const RecipeCard({super.key, required this.recipe, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final totalMinutes = (recipe.prepTimeMinutes ?? 0) + (recipe.cookTimeMinutes ?? 0);

    return ClayCard(
      radius: AppRadius.md,
      padding: const EdgeInsets.all(AppSpacing.sm),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            height: 88,
            child: ClayImage(
              fileName: recipe.imageFileName,
              fallbackIconSize: 40,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    if (totalMinutes > 0)
                      ClayTag(
                        label: t.recipe.minutes(count: totalMinutes),
                        icon: Icons.timer_rounded,
                      ),
                    ClayTag(
                      label: t.recipe.ingredientsCount(count: recipe.ingredients.length),
                      icon: Icons.list_alt_rounded,
                      background: AppColors.surfaceContainerLow,
                      foreground: AppColors.tertiary,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.base),
                Text(
                  recipe.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyLg.copyWith(
                    fontWeight: FontWeight.w700,
                    fontVariations: const [FontVariation('wght', 700)],
                  ),
                ),
                if (recipe.dietaryTags.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.base),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: recipe.dietaryTags.map((tag) {
                      final (background, foreground) = dietaryColors(tag);
                      return ClayTag(
                        label: dietaryLabel(tag),
                        icon: dietaryIcon(tag),
                        background: background,
                        foreground: foreground,
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
