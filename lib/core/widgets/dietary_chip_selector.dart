import 'package:flutter/material.dart';

import '../../core/utils/i18n/strings.g.dart';
import '../constants/app_colors.dart';
import '../constants/app_enums.dart';

String dietaryLabel(DietaryPreference preference) => switch (preference) {
      DietaryPreference.meat => t.dietary.meat,
      DietaryPreference.dairy => t.dietary.dairy,
      DietaryPreference.vegetarian => t.dietary.vegetarian,
      DietaryPreference.vegan => t.dietary.vegan,
      DietaryPreference.kosher => t.dietary.kosher,
      DietaryPreference.glutenFree => t.dietary.glutenFree,
      DietaryPreference.allergy => t.dietary.allergy,
    };

class DietaryChipSelector extends StatelessWidget {
  final List<DietaryPreference> selected;
  final ValueChanged<DietaryPreference> onToggle;

  const DietaryChipSelector({super.key, required this.selected, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: DietaryPreference.values.map((preference) {
        final isSelected = selected.contains(preference);
        return FilterChip(
          label: Text(dietaryLabel(preference)),
          selected: isSelected,
          onSelected: (_) => onToggle(preference),
          selectedColor: (AppColors.dietaryChipColors[preference.name] ?? AppColors.accent)
              .withValues(alpha: 0.25),
          checkmarkColor: AppColors.ink,
        );
      }).toList(),
    );
  }
}
