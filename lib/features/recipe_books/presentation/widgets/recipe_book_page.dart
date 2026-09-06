import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/duration_label.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../../../core/widgets/dietary_chip_selector.dart';
import '../../../../core/widgets/measurement_unit_label.dart';
import '../../../my_recipes/domain/entities/recipe_entity.dart';
import 'book_page_surface.dart';

/// One recipe rendered as a printed book page.
class RecipeBookPage extends StatelessWidget {
  final RecipeEntity recipe;
  final int pageNumber;

  const RecipeBookPage({super.key, required this.recipe, required this.pageNumber});

  @override
  Widget build(BuildContext context) {
    return BookPageSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (recipe.imageFileName != null) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 160,
                      child: ClayImage(
                        fileName: recipe.imageFileName,
                        radius: AppRadius.md,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.gutter),
                  ],
                  Text(recipe.title, style: AppTextStyles.headlineLgMobile),
                  const SizedBox(height: AppSpacing.sm),
                  // Topics sit above the times, right under the title, so what kind
                  // of dish it is reads before how long it takes.
                  if (recipe.dietaryTags.isNotEmpty) ...[
                    Wrap(
                      spacing: AppSpacing.base,
                      runSpacing: AppSpacing.base,
                      children: [
                        for (final tag in recipe.dietaryTags)
                          if (dietaryColors(tag) case (final background, final foreground))
                            ClayTag(
                              label: dietaryLabel(tag),
                              icon: dietaryIcon(tag),
                              background: background,
                              foreground: foreground,
                            ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  Wrap(
                    spacing: AppSpacing.base,
                    runSpacing: AppSpacing.base,
                    children: [
                      ClayTag(
                        label: '${t.recipe.prepTime} · ${optionalDurationLabel(recipe.prepTimeMinutes)}',
                        icon: Icons.timer_rounded,
                      ),
                      ClayTag(
                        label: '${t.recipe.cookTime} · ${optionalDurationLabel(recipe.cookTimeMinutes)}',
                        icon: Icons.local_fire_department_rounded,
                        background: AppColors.secondaryContainer,
                        foreground: AppColors.onSecondaryContainer,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _PageHeading(title: t.recipe.ingredients),
                  const SizedBox(height: AppSpacing.base),
                  ...recipe.ingredients.map((ingredient) {
                    final amount = ingredient.isAmountMissing
                        ? kMissingInfoPlaceholder
                        : ingredient.amount.toString();
                    final unit = measurementUnitLabel(ingredient.unit);
                    final line =
                        [amount, unit, ingredient.name].where((s) => s.isNotEmpty).join(' ');

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 7),
                            child: Icon(Icons.circle, size: 6, color: AppColors.primary),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(child: Text(line, style: AppTextStyles.bodyMd)),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: AppSpacing.md),
                  _PageHeading(title: t.recipe.instructions),
                  const SizedBox(height: AppSpacing.base),
                  ...recipe.steps.asMap().entries.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.base),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 26,
                                height: 26,
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(
                                  color: AppColors.primaryFixed,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${entry.key + 1}',
                                  style: AppTextStyles.labelSm.copyWith(
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(entry.value, style: AppTextStyles.bodyMd),
                              ),
                            ],
                          ),
                        ),
                      ),
                ],
              ),
            ),
          ),
          Center(
            child: Text(
              '$pageNumber',
              style: AppTextStyles.labelSm.copyWith(color: AppColors.outline),
            ),
          ),
        ],
      ),
    );
  }


}

class _PageHeading extends StatelessWidget {
  final String title;

  const _PageHeading({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: AppSpacing.base),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.primaryFixed, width: 2)),
      ),
      child: Text(
        title,
        style: AppTextStyles.headlineMd.copyWith(color: AppColors.primary),
      ),
    );
  }
}
