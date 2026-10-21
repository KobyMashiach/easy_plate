import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/amount_format.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../../../core/widgets/measurement_unit_label.dart';
import '../../domain/entities/grocery_item_entity.dart';
import '../../../../core/constants/app_motion.dart';
import '../../domain/parse_amount.dart';

/// Drill-down for one line: which recipe contributed how much, with per-source
/// adjustment and removal, a unit picker, and a free buffer amount.
///
/// Ad-hoc lines carry a single manual source, so they land in exactly this
/// sheet and are edited the same way as recipe-derived ones.
///
/// Each source is reported with its position *and* who it is (recipe id and
/// label): the list can change under the open sheet (a rebuild, a remote
/// edit), and the bloc uses the identity to find the right source again.
typedef BreakdownSourceId = ({String? recipeId, String label});

Future<void> showItemBreakdownSheet(
  BuildContext context,
  GroceryItemEntity item, {
  required void Function(
    int sourceIndex,
    BreakdownSourceId source,
    double amount,
  )
  onAdjustSource,
  required void Function(int sourceIndex, BreakdownSourceId source)
  onRemoveSource,
  required void Function(MeasurementUnit unit) onChangeUnit,
  required void Function(double amount) onAddBuffer,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => _BreakdownBody(
      item: item,
      onAdjustSource: onAdjustSource,
      onRemoveSource: onRemoveSource,
      onChangeUnit: onChangeUnit,
      onAddBuffer: onAddBuffer,
    ),
  );
}

class _BreakdownBody extends StatefulWidget {
  final GroceryItemEntity item;
  final void Function(
    int sourceIndex,
    BreakdownSourceId source,
    double amount,
  )
  onAdjustSource;
  final void Function(int sourceIndex, BreakdownSourceId source) onRemoveSource;
  final void Function(MeasurementUnit unit) onChangeUnit;
  final void Function(double amount) onAddBuffer;

  const _BreakdownBody({
    required this.item,
    required this.onAdjustSource,
    required this.onRemoveSource,
    required this.onChangeUnit,
    required this.onAddBuffer,
  });

  @override
  State<_BreakdownBody> createState() => _BreakdownBodyState();
}

class _BreakdownBodyState extends State<_BreakdownBody> {
  final _bufferController = TextEditingController();

  /// Mirrored locally: the sheet sits on its own route and can't see the
  /// grocery bloc's rebuilt state, so edits have to show up here directly.
  late List<({String? recipeId, String label, double amount})> _sources = [
    for (final source in widget.item.sources)
      (recipeId: source.recipeId, label: source.label, amount: source.amount),
  ];

  static BreakdownSourceId _idOf(
    ({String? recipeId, String label, double amount}) s,
  ) => (recipeId: s.recipeId, label: s.label);
  late MeasurementUnit _unit = widget.item.unit;

  /// One per source, owned here for the sheet's life. Creating them in
  /// build — as this once did — made a new, never-disposed controller for
  /// every row on every rebuild, and lost the text being typed with each.
  late final List<TextEditingController> _amountControllers = [
    for (final source in _sources)
      TextEditingController(text: formatAmount(source.amount)),
  ];

  /// The text each field was last filled with or committed at. The field
  /// shows at most two decimals, so 1.125 reads "1.13": comparing the parsed
  /// text with the stored amount rewrote (and published) every such amount
  /// on close though nothing was touched. Only a changed text is an edit.
  late final List<String> _committedText;

  @override
  void initState() {
    super.initState();
    // Read now, not lazily: a lazy read on close would see the typed text.
    _committedText = [
      for (final controller in _amountControllers) controller.text,
    ];
  }

  /// The amount typed into field [i], or null when it is unchanged or not
  /// a number.
  double? _editedAmount(int i, String text) {
    if (text.trim() == _committedText[i].trim()) return null;
    final typed = parseAmount(text);
    if (typed == null || typed == _sources[i].amount) return null;
    _committedText[i] = text;
    return typed;
  }

  /// An amount typed but never submitted (the sheet swiped away, or "Add"
  /// tapped with the field still open) used to be lost; it is committed on
  /// the way out instead.
  void _commitPending() {
    for (var i = 0; i < _sources.length && i < _amountControllers.length; i++) {
      final typed = _editedAmount(i, _amountControllers[i].text);
      if (typed == null) continue;
      widget.onAdjustSource(i, _idOf(_sources[i]), typed);
    }
  }

  @override
  void dispose() {
    _commitPending();
    _bufferController.dispose();
    for (final controller in _amountControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  double get _total => _sources.fold(0, (sum, s) => sum + s.amount);

  void _removeSource(int index) {
    if (_sources.length <= 1) return;
    final controller = _amountControllers.removeAt(index);
    _committedText.removeAt(index);
    final removed = _sources[index];
    setState(() => _sources = [..._sources]..removeAt(index));
    widget.onRemoveSource(index, _idOf(removed));
    // After the frame that drops its field, so the field is not torn down
    // while still bound to it.
    WidgetsBinding.instance.addPostFrameCallback((_) => controller.dispose());
  }

  @override
  Widget build(BuildContext context) {
    final unitLabel = measurementUnitLabel(_unit);
    // The final source can be edited but not deleted — an item with no sources
    // would silently lose its quantity.
    final canRemove = _sources.length > 1;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.marginMobile,
        right: AppSpacing.marginMobile,
        bottom:
            MediaQuery.of(context).viewInsets.bottom + AppSpacing.marginMobile,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.item.name, style: AppTextStyles.headlineMd),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${t.groceryList.breakdownTitle} · ${formatAmount(_total)} $unitLabel'
                  .trim(),
              style: AppTextStyles.labelMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.gutter),
            Text(t.groceryList.unit, style: AppTextStyles.labelMd),
            const SizedBox(height: AppSpacing.base),
            Wrap(
              spacing: AppSpacing.base,
              runSpacing: AppSpacing.base,
              children: MeasurementUnit.values.map((unit) {
                final isSelected = unit == _unit;
                return GestureDetector(
                  onTap: () {
                    setState(() => _unit = unit);
                    widget.onChangeUnit(unit);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: AppMotion.quick,
                    curve: AppMotion.easeOut,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
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
                      measurementUnitPickerLabel(unit),
                      style: AppTextStyles.labelMd.copyWith(
                        color: isSelected
                            ? AppColors.onPrimary
                            : AppColors.tertiary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const Divider(height: AppSpacing.lg),
            Text(t.groceryList.amount, style: AppTextStyles.labelMd),
            const SizedBox(height: AppSpacing.base),
            ..._sources.asMap().entries.map((entry) {
              final controller = _amountControllers[entry.key];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.value.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyMd,
                      ),
                    ),
                    SizedBox(
                      width: 88,
                      child: TextField(
                        controller: controller,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.labelMd,
                        decoration: const InputDecoration(isDense: true),
                        onSubmitted: (value) {
                          final amount = _editedAmount(entry.key, value);
                          if (amount == null) return;
                          setState(() {
                            _sources = [..._sources];
                            _sources[entry.key] = (
                              recipeId: entry.value.recipeId,
                              label: entry.value.label,
                              amount: amount,
                            );
                          });
                          widget.onAdjustSource(
                            entry.key,
                            _idOf(entry.value),
                            amount,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.base),
                    SizedBox(
                      width: 52,
                      child: Text(
                        unitLabel,
                        style: AppTextStyles.labelMd.copyWith(
                          color: AppColors.outline,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      color: canRemove
                          ? AppColors.error
                          : AppColors.outlineVariant,
                      tooltip: canRemove
                          ? t.common.delete
                          : t.groceryList.lastSource,
                      onPressed: canRemove
                          ? () => _removeSource(entry.key)
                          : null,
                    ),
                  ],
                ),
              );
            }),
            if (!canRemove)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  t.groceryList.lastSource,
                  style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.outline,
                  ),
                ),
              ),
            const Divider(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _bufferController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: AppTextStyles.bodyMd,
                    decoration: InputDecoration(
                      labelText: t.groceryList.buffer,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                ClayButton(
                  label: t.common.add,
                  onPressed: () {
                    final amount = parseAmount(_bufferController.text);
                    if (amount != null) widget.onAddBuffer(amount);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}
