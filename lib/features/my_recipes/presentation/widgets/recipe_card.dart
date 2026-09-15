import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/duration_label.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../../../core/widgets/dietary_chip_selector.dart';
import '../../../../core/widgets/nutrition/nutrition_widgets.dart';
import '../../domain/entities/recipe_entity.dart';

/// A recipe as a photo card: the dish fills the top, the time and calories
/// float on it, the title sits under it. Two of these side by side make the
/// recipe grid.
///
/// Fixed height ([height]) so a grid can lay them out without measuring;
/// everything inside is sized to fit it.
class RecipeCard extends StatelessWidget {
  final RecipeEntity recipe;
  final VoidCallback onTap;

  /// Present only for recipes this account may share — its own, unshared or
  /// owned. Members of someone else's recipe do not get to invite others.
  final VoidCallback? onShare;

  /// Present for a copy saved from the community: takes it out of My Recipes.
  /// The feed only ever adds; this is the one place a saved recipe leaves.
  final VoidCallback? onRemove;

  const RecipeCard({
    super.key,
    required this.recipe,
    required this.onTap,
    this.onShare,
    this.onRemove,
  });

  static const height = 248.0;
  static const _imageHeight = 136.0;

  @override
  Widget build(BuildContext context) {
    final totalMinutes = (recipe.prepTimeMinutes ?? 0) + (recipe.cookTimeMinutes ?? 0);
    final calories = recipe.nutrition?.calories;

    return SizedBox(
      height: height,
      child: ClayCard(
        radius: AppRadius.md,
        padding: const EdgeInsets.all(AppSpacing.base),
        onTap: onTap,
        onLongPress: onShare,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: _imageHeight,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClayImage(
                      fileName: recipe.imageFileName,
                      remotePath: recipe.imageStoragePath,
                      radius: AppRadius.std,
                      fallbackIconSize: 40,
                    ),
                  ),
                  if (calories != null)
                    PositionedDirectional(
                      top: AppSpacing.base,
                      end: AppSpacing.base,
                      child: _Badge(
                        icon: Icons.bolt_rounded,
                        label: '${kcalNumber(calories)} ${t.nutrition.kcal}',
                        color: AppColors.warmAccent,
                        foreground: AppColors.onWarmAccent,
                      ),
                    ),
                  if (totalMinutes > 0)
                    PositionedDirectional(
                      bottom: AppSpacing.base,
                      start: AppSpacing.base,
                      child: _Badge(
                        icon: Icons.timer_rounded,
                        label: durationLabel(totalMinutes),
                        color: AppColors.surfaceContainerLowest.withValues(alpha: 0.9),
                        foreground: AppColors.onSurface,
                      ),
                    ),
                  if (onRemove case final remove?)
                    PositionedDirectional(
                      top: AppSpacing.xs,
                      start: AppSpacing.xs,
                      child: IconButton(
                        tooltip: t.community.removeSaved,
                        visualDensity: VisualDensity.compact,
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.surfaceContainerLowest.withValues(alpha: 0.9),
                        ),
                        icon: Icon(Icons.bookmark_remove_rounded, size: 18, color: AppColors.error),
                        onPressed: remove,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: Text(
                recipe.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyMd.copyWith(
                  fontWeight: FontWeight.w700,
                  fontVariations: const [FontVariation('wght', 700)],
                  height: 1.25,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.base),
            // One line of context: the collab role or the pending flag
            // outranks a diet tag, since it says whether the recipe is usable.
            SizedBox(
              height: 26,
              child: _MetaRow(recipe: recipe),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final RecipeEntity recipe;

  const _MetaRow({required this.recipe});

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];
    if (recipe.pendingAnalysis) {
      chips.add(ClayTag(
        label: t.recipe.pendingAnalysis,
        icon: Icons.hourglass_top_rounded,
        background: AppColors.secondaryContainer,
        foreground: AppColors.onSecondaryContainer,
      ));
    } else if (recipe.collabRole case final role?) {
      chips.add(ClayTag(
        label: switch (role) {
          CollabRole.owner => t.sharing.ownerTag,
          CollabRole.editor => t.sharing.editorTag,
          CollabRole.viewer => t.sharing.viewerTag,
        },
        icon: Icons.group_rounded,
        background: AppColors.secondaryContainer,
        foreground: AppColors.onSecondaryContainer,
      ));
    }
    for (final tag in recipe.dietaryTags) {
      if (chips.length >= 2) break;
      final (background, foreground) = dietaryColors(tag);
      chips.add(ClayTag(
        label: dietaryLabel(tag),
        icon: dietaryIcon(tag),
        background: background,
        foreground: foreground,
      ));
    }
    if (chips.isEmpty) {
      chips.add(ClayTag(
        label: t.recipe.ingredientsCount(count: recipe.ingredients.length),
        icon: Icons.list_alt_rounded,
        background: AppColors.surfaceContainerLow,
        foreground: AppColors.tertiary,
      ));
    }
    // Clipped rather than wrapped: the card's height is fixed, and a second
    // row of chips would push the title out.
    return ClipRect(
      child: OverflowBox(
        alignment: AlignmentDirectional.centerStart,
        maxWidth: double.infinity,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < chips.length; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.xs),
              chips[i],
            ],
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color foreground;

  const _Badge({
    required this.icon,
    required this.label,
    required this.color,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: AppSpacing.xs),
      decoration: ShapeDecoration(color: color, shape: const StadiumBorder()),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: foreground),
          const SizedBox(width: 3),
          Text(
            label,
            style: AppTextStyles.labelSm.copyWith(
              color: foreground,
              fontWeight: FontWeight.w800,
              fontVariations: const [FontVariation('wght', 800)],
            ),
          ),
        ],
      ),
    );
  }
}
