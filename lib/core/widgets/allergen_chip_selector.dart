import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_enums.dart';
import '../constants/app_spacing.dart';
import '../constants/app_text_styles.dart';
import '../utils/i18n/strings.g.dart';

String allergenLabel(Allergen allergen) => switch (allergen) {
      Allergen.gluten => t.allergens.gluten,
      Allergen.milk => t.allergens.milk,
      Allergen.eggs => t.allergens.eggs,
      Allergen.fish => t.allergens.fish,
      Allergen.shellfish => t.allergens.shellfish,
      Allergen.peanuts => t.allergens.peanuts,
      Allergen.treeNuts => t.allergens.treeNuts,
      Allergen.sesame => t.allergens.sesame,
      Allergen.soy => t.allergens.soy,
    };

/// Pill-shaped allergen picker, one pill per [Allergen]. Same shape as the
/// dietary chips it sits under, in the error colours a warning wears.
class AllergenChipSelector extends StatelessWidget {
  final List<Allergen> selected;
  final ValueChanged<Allergen> onToggle;

  const AllergenChipSelector({super.key, required this.selected, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.base,
      runSpacing: AppSpacing.base,
      children: Allergen.values.map((allergen) {
        final isSelected = selected.contains(allergen);
        return GestureDetector(
          onTap: () => onToggle(allergen),
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.base,
            ),
            decoration: ShapeDecoration(
              color: isSelected ? AppColors.errorContainer : AppColors.surfaceContainerLow,
              shape: StadiumBorder(
                side: BorderSide(
                  color: isSelected ? AppColors.errorContainer : AppColors.outlineVariant,
                ),
              ),
            ),
            child: Text(
              allergenLabel(allergen),
              style: AppTextStyles.labelMd.copyWith(
                color: isSelected ? AppColors.onErrorContainer : AppColors.tertiary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// "Contains: eggs, sesame" and "May contain: tree nuts", for a recipe that
/// has either. Draws nothing — not even its spacing — for one that has
/// neither, so callers can place it unconditionally.
class AllergenNotice extends StatelessWidget {
  final List<Allergen> allergens;
  final List<Allergen> mayContain;

  const AllergenNotice({super.key, required this.allergens, required this.mayContain});

  @override
  Widget build(BuildContext context) {
    if (allergens.isEmpty && mayContain.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (allergens.isNotEmpty) _line(t.allergens.contains, allergens),
          if (mayContain.isNotEmpty) _line(t.allergens.mayContain, mayContain),
        ],
      ),
    );
  }

  Widget _line(String label, List<Allergen> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.onErrorContainer),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              '$label: ${items.map(allergenLabel).join(', ')}',
              style: AppTextStyles.labelMd.copyWith(color: AppColors.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
