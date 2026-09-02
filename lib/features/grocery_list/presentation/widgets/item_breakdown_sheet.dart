import 'package:flutter/material.dart';

import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/measurement_unit_label.dart';
import '../../domain/entities/grocery_item_entity.dart';

/// Drill-down for one aggregated line: which recipe contributed how much,
/// with per-source adjustment and a free buffer amount (spec §6.2).
Future<void> showItemBreakdownSheet(
  BuildContext context,
  GroceryItemEntity item, {
  required void Function(int sourceIndex, double amount) onAdjustSource,
  required void Function(double amount) onAddBuffer,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) {
      final bufferController = TextEditingController();
      final unit = measurementUnitLabel(item.unit);
      return Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.name, style: AppTextStyles.pageHeading),
            Text(
              '${t.groceryList.breakdownTitle} · ${item.totalAmount} $unit'.trim(),
              style: AppTextStyles.caption,
            ),
            const Divider(height: 24),
            ...item.sources.asMap().entries.map((entry) {
              final controller = TextEditingController(text: entry.value.amount.toString());
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(child: Text(entry.value.label, style: AppTextStyles.body)),
                    SizedBox(
                      width: 90,
                      child: TextField(
                        controller: controller,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(isDense: true),
                        onSubmitted: (value) {
                          final amount = double.tryParse(value);
                          if (amount != null) onAdjustSource(entry.key, amount);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(unit, style: AppTextStyles.caption),
                  ],
                ),
              );
            }),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: bufferController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: t.groceryList.buffer),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: () {
                    final amount = double.tryParse(bufferController.text);
                    if (amount != null) onAddBuffer(amount);
                    Navigator.of(sheetContext).pop();
                  },
                  child: Text(t.common.add),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      );
    },
  );
}
