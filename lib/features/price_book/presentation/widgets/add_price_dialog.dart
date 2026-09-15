import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../domain/entities/price_record_entity.dart';
import '../../domain/entities/price_unit.dart';
import '../../domain/product_name.dart';
import '../../domain/repositories/price_book_repository.dart';

/// Records a price with no receipt behind it — one the user paid or simply
/// knows. Stored as a record under the `manual` receipt id, so it counts
/// like any other and can be told apart. Resolves true when saved.
Future<bool> showAddPriceDialog(
  BuildContext context, {
  String? name,
  double? price,
  PriceUnit unit = PriceUnit.unit,
}) async {
  final nameController = TextEditingController(text: name ?? '');
  final priceController = TextEditingController(
    text: price == null ? '' : price.toStringAsFixed(2),
  );
  var chosen = unit;
  final confirmed = await AppDialog.general(
    title: t.receipt.addPrice,
    message: t.receipt.addPriceHint,
    icon: Icons.sell_rounded,
    content: StatefulBuilder(
      builder: (context, setState) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameController,
            style: AppTextStyles.bodyMd,
            decoration: InputDecoration(labelText: t.receipt.itemName),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: priceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            style: AppTextStyles.bodyMd,
            decoration: InputDecoration(
              labelText: t.receipt.price,
              prefixText: '₪ ',
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              for (final u in PriceUnit.values) ...[
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => chosen = u),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.base,
                      ),
                      decoration: ShapeDecoration(
                        color: chosen == u
                            ? AppColors.primary
                            : AppColors.surfaceContainerLow,
                        shape: StadiumBorder(
                          side: BorderSide(
                            color: chosen == u
                                ? AppColors.primary
                                : AppColors.outlineVariant,
                          ),
                        ),
                      ),
                      child: Text(
                        priceUnitLabel(u),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.labelMd.copyWith(
                          color: chosen == u
                              ? AppColors.onPrimary
                              : AppColors.tertiary,
                        ),
                      ),
                    ),
                  ),
                ),
                if (u != PriceUnit.values.last)
                  const SizedBox(width: AppSpacing.base),
              ],
            ],
          ),
        ],
      ),
    ),
    confirmLabel: t.common.save,
    cancelLabel: t.common.cancel,
  ).show(context);
  final productName = nameController.text.trim();
  final value = double.tryParse(
    priceController.text.trim().replaceAll(',', '.'),
  );
  nameController.dispose();
  priceController.dispose();
  if (confirmed != true ||
      productName.isEmpty ||
      value == null ||
      value <= 0 ||
      !context.mounted) {
    return false;
  }
  await context.read<PriceBookRepository>().saveRecords([
    PriceRecordEntity(
      id: const Uuid().v4(),
      name: productName,
      normalizedName: normalizeProductName(productName),
      unitPrice: value,
      unit: chosen,
      quantity: 1,
      currency: 'ILS',
      store: null,
      purchasedAt: DateTime.now(),
      receiptId: PriceRecordEntity.manualReceiptId,
    ),
  ]);
  if (context.mounted) {
    AppDialog.success(message: t.receipt.priceSaved).notify(context);
  }
  return true;
}

String priceUnitLabel(PriceUnit unit) => switch (unit) {
  PriceUnit.unit => t.receipt.perUnit,
  PriceUnit.kg => t.receipt.perKg,
  PriceUnit.liter => t.receipt.perLiter,
};
