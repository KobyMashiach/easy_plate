import 'package:flutter/material.dart';

import '../../core/utils/i18n/strings.g.dart';
import '../constants/app_enums.dart';

String weekdayLabel(ShoppingDay day) => switch (day) {
      ShoppingDay.sunday => t.weekday.sunday,
      ShoppingDay.monday => t.weekday.monday,
      ShoppingDay.tuesday => t.weekday.tuesday,
      ShoppingDay.wednesday => t.weekday.wednesday,
      ShoppingDay.thursday => t.weekday.thursday,
      ShoppingDay.friday => t.weekday.friday,
      ShoppingDay.saturday => t.weekday.saturday,
    };

class WeekdaySelector extends StatelessWidget {
  final ShoppingDay selected;
  final ValueChanged<ShoppingDay> onSelect;

  const WeekdaySelector({super.key, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ShoppingDay.values.map((day) {
        return ChoiceChip(
          label: Text(weekdayLabel(day)),
          selected: selected == day,
          onSelected: (_) => onSelect(day),
        );
      }).toList(),
    );
  }
}
