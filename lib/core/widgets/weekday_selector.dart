import 'package:flutter/material.dart';

import '../../core/utils/i18n/strings.g.dart';
import '../constants/app_colors.dart';
import '../constants/app_enums.dart';
import '../constants/app_spacing.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_motion.dart';

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
///
/// One day by default; [WeekdaySelector.multiple] lets several be on, a tap
/// toggling a day, and never lets the last one go.
class WeekdaySelector extends StatelessWidget {
  final List<ShoppingDay> selected;
  final ValueChanged<List<ShoppingDay>> _onChanged;
  final bool _multiple;

  WeekdaySelector({
    super.key,
    required ShoppingDay selected,
    required ValueChanged<ShoppingDay> onSelect,
  }) : selected = [selected],
       _onChanged = ((days) => onSelect(days.first)),
       _multiple = false;

  const WeekdaySelector.multiple({
    super.key,
    required this.selected,
    required ValueChanged<List<ShoppingDay>> onChanged,
  }) : _onChanged = onChanged,
       _multiple = true;

  void _tap(ShoppingDay day) {
    if (!_multiple) return _onChanged([day]);
    final isOn = selected.contains(day);
    if (isOn && selected.length == 1) return;
    _onChanged([
      for (final d in ShoppingDay.values)
        if (d == day ? !isOn : selected.contains(d)) d,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.base,
      runSpacing: AppSpacing.base,
      children: ShoppingDay.values.map((day) {
        final isSelected = selected.contains(day);
        return GestureDetector(
          onTap: () => _tap(day),
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: AppMotion.quick,
            curve: AppMotion.easeOut,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.gutter,
              vertical: AppSpacing.base,
            ),
            decoration: ShapeDecoration(
              color: isSelected
                  ? AppColors.primary
                  : AppColors.surfaceContainerLow,
              shape: StadiumBorder(
                side: BorderSide(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.outlineVariant,
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
