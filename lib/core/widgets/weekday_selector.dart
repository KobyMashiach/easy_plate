import 'package:flutter/material.dart';

import '../../core/utils/i18n/strings.g.dart';
import '../constants/app_colors.dart';
import '../constants/app_enums.dart';
import '../constants/app_spacing.dart';
import '../constants/app_text_styles.dart';

String weekdayLabel(ShoppingDay day) => switch (day) {
      ShoppingDay.sunday => t.weekday.sunday,
      ShoppingDay.monday => t.weekday.monday,
      ShoppingDay.tuesday => t.weekday.tuesday,
      ShoppingDay.wednesday => t.weekday.wednesday,
      ShoppingDay.thursday => t.weekday.thursday,
      ShoppingDay.friday => t.weekday.friday,
      ShoppingDay.saturday => t.weekday.saturday,
    };

/// Pill day picker: the active day takes the Lavender Glow fill with white
/// text, inactive days a lavender-white fill with indigo text.
class WeekdaySelector extends StatelessWidget {
  final ShoppingDay selected;
  final ValueChanged<ShoppingDay> onSelect;

  const WeekdaySelector({super.key, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.base,
      runSpacing: AppSpacing.base,
      children: ShoppingDay.values.map((day) {
        final isSelected = selected == day;
        return GestureDetector(
          onTap: () => onSelect(day),
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.gutter,
              vertical: AppSpacing.base,
            ),
            decoration: ShapeDecoration(
              color: isSelected ? AppColors.primary : AppColors.surfaceContainerLow,
              shape: StadiumBorder(
                side: BorderSide(
                  color: isSelected ? AppColors.primary : AppColors.outlineVariant,
                ),
              ),
            ),
            child: Text(
              weekdayLabel(day),
              style: AppTextStyles.labelMd.copyWith(
                color: isSelected ? AppColors.onPrimary : AppColors.tertiary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
