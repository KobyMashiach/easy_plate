import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/features/features_flags.dart';
import '../../domain/entities/recipe_ingredient_entity.dart';

/// The small heading above a run of ingredients for one part of the dish
/// ("רוטב", "בצק"). A label over the lines, not a line of its own: nothing
/// that draws it ever hands it to a grocery list.
class IngredientSectionHeading extends StatelessWidget {
  final String title;

  /// Whether lines come before it, and so it needs room above.
  final bool spaced;

  const IngredientSectionHeading({
    super.key,
    required this.title,
    this.spaced = true,
  });

  /// The heading for `ingredients[index]`, or null when that line does not
  /// open a new section.
  static Widget? at(List<RecipeIngredientEntity> ingredients, int index) {
    if (!FeaturesFlags.ingredientSections.isEnabled) return null;
    final section = sectionStartingAt(ingredients, index);
    if (section == null) return null;
    return IngredientSectionHeading(title: section, spaced: index > 0);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Padding(
        padding: EdgeInsets.only(
          top: spaced ? AppSpacing.sm : 0,
          bottom: AppSpacing.xs,
        ),
        child: Text(
          title,
          style: AppTextStyles.labelMd.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
