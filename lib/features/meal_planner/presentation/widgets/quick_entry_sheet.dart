import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../../../core/widgets/measurement_unit_label.dart';
import '../../../my_recipes/domain/entities/recipe_ingredient_entity.dart';

/// Result of the quick-entry sheet: the item's name plus the products it is
/// made of (possibly empty).
typedef QuickEntryResult = ({String text, List<RecipeIngredientEntity> ingredients});

/// Creates or edits a free-text meal item. Listing products here is what lets
/// a quick entry like "omelette" contribute eggs, milk and oil to the grocery
/// list instead of a single opaque line.
Future<QuickEntryResult?> showQuickEntrySheet(
  BuildContext context, {
  String? initialText,
  List<RecipeIngredientEntity> initialIngredients = const [],
}) {
  return showModalBottomSheet<QuickEntryResult>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => _QuickEntryForm(
      initialText: initialText,
      initialIngredients: initialIngredients,
    ),
  );
}

/// Editable row backing one product line while the sheet is open.
class _ProductDraft {
  final TextEditingController name;
  final TextEditingController amount;
  MeasurementUnit unit;

  _ProductDraft({String name = '', String amount = '', this.unit = MeasurementUnit.unit})
      : name = TextEditingController(text: name),
        amount = TextEditingController(text: amount);

  void dispose() {
    name.dispose();
    amount.dispose();
  }
}

class _QuickEntryForm extends StatefulWidget {
  final String? initialText;
  final List<RecipeIngredientEntity> initialIngredients;

  const _QuickEntryForm({this.initialText, required this.initialIngredients});

  @override
  State<_QuickEntryForm> createState() => _QuickEntryFormState();
}

class _QuickEntryFormState extends State<_QuickEntryForm> {
  late final _nameController = TextEditingController(text: widget.initialText ?? '');
  late final List<_ProductDraft> _products = [
    for (final ingredient in widget.initialIngredients)
      _ProductDraft(
        name: ingredient.name,
        amount: ingredient.amount?.toString() ?? '',
        unit: ingredient.unit,
      ),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    for (final product in _products) {
      product.dispose();
    }
    super.dispose();
  }

  bool get _canSubmit => _nameController.text.trim().isNotEmpty;

  void _submit() {
    final text = _nameController.text.trim();
    if (text.isEmpty) return;

    final ingredients = <RecipeIngredientEntity>[];
    for (final product in _products) {
      final name = product.name.text.trim();
      // Rows left blank are dropped rather than saved as empty products.
      if (name.isEmpty) continue;
      ingredients.add(
        RecipeIngredientEntity(
          name: name,
          amount: double.tryParse(product.amount.text.trim()),
          unit: product.unit,
        ),
      );
    }

    Navigator.of(context).pop((text: text, ingredients: ingredients));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.marginMobile,
        right: AppSpacing.marginMobile,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.marginMobile,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.initialText == null
                  ? t.mealPlanner.quickEntry
                  : t.mealPlanner.editItem,
              style: AppTextStyles.headlineMd,
            ),
            const SizedBox(height: AppSpacing.gutter),
            TextField(
              controller: _nameController,
              autofocus: widget.initialText == null,
              style: AppTextStyles.bodyMd,
              decoration: InputDecoration(labelText: t.mealPlanner.itemName),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: Text(t.mealPlanner.products, style: AppTextStyles.labelMd),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(t.mealPlanner.addProduct),
                  onPressed: () => setState(() => _products.add(_ProductDraft())),
                ),
              ],
            ),
            if (_products.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.base),
                child: Text(
                  t.mealPlanner.noProducts,
                  style: AppTextStyles.labelSm.copyWith(color: AppColors.outline),
                ),
              ),
            ..._products.asMap().entries.map((entry) {
              final product = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.base),
                child: ClayCard(
                  radius: AppRadius.md,
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: product.name,
                              style: AppTextStyles.bodyMd,
                              decoration: InputDecoration(
                                labelText: t.mealPlanner.productName,
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.base),
                          SizedBox(
                            width: 76,
                            child: TextField(
                              controller: product.amount,
                              keyboardType:
                                  const TextInputType.numberWithOptions(decimal: true),
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodyMd,
                              decoration: InputDecoration(
                                labelText: t.groceryList.amount,
                                isDense: true,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            color: AppColors.error,
                            onPressed: () => setState(() {
                              _products.removeAt(entry.key).dispose();
                            }),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.base),
                      SizedBox(
                        height: 36,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            for (final unit in MeasurementUnit.values)
                              Padding(
                                padding: const EdgeInsets.only(right: AppSpacing.base),
                                child: GestureDetector(
                                  onTap: () => setState(() => product.unit = unit),
                                  behavior: HitTestBehavior.opaque,
                                  child: Container(
                                    alignment: Alignment.center,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.sm,
                                    ),
                                    decoration: ShapeDecoration(
                                      color: product.unit == unit
                                          ? AppColors.primary
                                          : AppColors.surfaceContainerLow,
                                      shape: StadiumBorder(
                                        side: BorderSide(
                                          color: product.unit == unit
                                              ? AppColors.primary
                                              : AppColors.outlineVariant,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      measurementUnitPickerLabel(unit),
                                      style: AppTextStyles.labelMd.copyWith(
                                        color: product.unit == unit
                                            ? AppColors.onPrimary
                                            : AppColors.tertiary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: AppSpacing.gutter),
            ClayButton(
              label: t.common.save,
              icon: Icons.check_rounded,
              expanded: true,
              onPressed: _canSubmit ? _submit : null,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}
