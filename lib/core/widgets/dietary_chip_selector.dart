import 'package:flutter/material.dart';

import '../../core/utils/i18n/strings.g.dart';
import '../constants/app_colors.dart';
import '../constants/app_enums.dart';
import '../constants/app_spacing.dart';
import '../constants/app_text_styles.dart';

String dietaryLabel(DietaryPreference preference) => switch (preference) {
      DietaryPreference.meat => t.dietary.meat,
      DietaryPreference.dairy => t.dietary.dairy,
      DietaryPreference.vegetarian => t.dietary.vegetarian,
      DietaryPreference.vegan => t.dietary.vegan,
      DietaryPreference.kosher => t.dietary.kosher,
      DietaryPreference.glutenFree => t.dietary.glutenFree,
      DietaryPreference.allergy => t.dietary.allergy,
    };

IconData dietaryIcon(DietaryPreference preference) => switch (preference) {
      DietaryPreference.meat => Icons.set_meal_rounded,
      DietaryPreference.dairy => Icons.egg_alt_rounded,
      DietaryPreference.vegetarian => Icons.eco_rounded,
      DietaryPreference.vegan => Icons.spa_rounded,
      DietaryPreference.kosher => Icons.verified_rounded,
      DietaryPreference.glutenFree => Icons.block_rounded,
      DietaryPreference.allergy => Icons.warning_amber_rounded,
    };

/// Colour pair (background, foreground) for a dietary tag.
(Color, Color) dietaryColors(DietaryPreference preference) =>
    AppColors.dietaryTagColors[preference.name] ??
    (AppColors.primaryFixed, AppColors.primary);

/// Pill-shaped dietary filters. Selected pills take their dietary tag colour;
/// unselected ones stay a soft lavender-white with indigo text.
class DietaryChipSelector extends StatelessWidget {
  final List<DietaryPreference> selected;
  final ValueChanged<DietaryPreference> onToggle;

  const DietaryChipSelector({super.key, required this.selected, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.base,
      runSpacing: AppSpacing.base,
      children: DietaryPreference.values.map((preference) {
        final isSelected = selected.contains(preference);
        final (background, foreground) = dietaryColors(preference);

        return GestureDetector(
          onTap: () => onToggle(preference),
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.base,
            ),
            decoration: ShapeDecoration(
              color: isSelected ? background : AppColors.surfaceContainerLow,
              shape: StadiumBorder(
                side: BorderSide(
                  color: isSelected ? background : AppColors.outlineVariant,
                ),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  dietaryIcon(preference),
                  size: 16,
                  color: isSelected ? foreground : AppColors.tertiary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  dietaryLabel(preference),
                  style: AppTextStyles.labelMd.copyWith(
                    color: isSelected ? foreground : AppColors.tertiary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
