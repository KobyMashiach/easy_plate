import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../../../core/widgets/measurement_unit_label.dart';
import '../../domain/entities/grocery_item_entity.dart';
import '../bloc/grocery_list_bloc.dart';
import 'item_breakdown_sheet.dart';

/// One aggregated grocery line: a pressable clay card with a book spine, a
/// bouncy checkbox, and an accordion revealing which recipe contributed what.
class GroceryItemCard extends StatefulWidget {
  final GroceryItemEntity item;

  const GroceryItemCard({super.key, required this.item});

  @override
  State<GroceryItemCard> createState() => _GroceryItemCardState();
}

class _GroceryItemCardState extends State<GroceryItemCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<GroceryListBloc>();
    final item = widget.item;
    final unit = measurementUnitLabel(item.unit);
    // Ad-hoc lines carry a manual source too, so they show a quantity and open
    // the same breakdown sheet as recipe-derived ones.
    final amountLabel = '${item.totalAmount} $unit'.trim();
    final hasSources = item.sources.isNotEmpty;

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => bloc.add(.removeItem(item.id)),
      background: Container(
        decoration: BoxDecoration(
          color: AppColors.errorContainer,
          borderRadius: BorderRadius.circular(AppRadius.std),
        ),
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsetsDirectional.only(end: AppSpacing.marginMobile),
        child: const Icon(Icons.delete_rounded, color: AppColors.onErrorContainer),
      ),
      child: ClayCard(
        padding: EdgeInsets.zero,
        showSpine: true,
        onTap: hasSources ? () => setState(() => _expanded = !_expanded) : null,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.gutter),
              child: Row(
                children: [
                  if (hasSources)
                    AnimatedRotation(
                      turns: _expanded ? 0.25 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.outline,
                      ),
                    )
                  else
                    const SizedBox(width: AppSpacing.md),
                  const SizedBox(width: AppSpacing.base),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: AppTextStyles.bodyLg.copyWith(
                            decoration: item.isChecked ? TextDecoration.lineThrough : null,
                            color: item.isChecked
                                ? AppColors.outline
                                : AppColors.onSurface,
                          ),
                        ),
                        if (amountLabel.isNotEmpty)
                          Text(
                            amountLabel,
                            style: AppTextStyles.labelMd.copyWith(
                              color: AppColors.outlineVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  BouncyCheckbox(
                    value: item.isChecked,
                    onChanged: (_) => bloc.add(.toggleItem(item.id)),
                  ),
                ],
              ),
            ),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 300),
              sizeCurve: Curves.easeOut,
              crossFadeState:
                  _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              firstChild: const SizedBox(width: double.infinity),
              secondChild: _SourceBreakdown(item: item),
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceBreakdown extends StatelessWidget {
  final GroceryItemEntity item;

  const _SourceBreakdown({required this.item});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<GroceryListBloc>();
    final unit = measurementUnitLabel(item.unit);

    return Container(
      width: double.infinity,
      color: AppColors.surfaceContainerLow,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.gutter,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final source in item.sources)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      source.label,
                      style: AppTextStyles.labelMd.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Text(
                    '${source.amount} $unit'.trim(),
                    style: AppTextStyles.labelMd.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton.icon(
              icon: const Icon(Icons.tune_rounded, size: 16),
              label: Text(t.groceryList.adjustAmounts),
              onPressed: () => showItemBreakdownSheet(
                context,
                item,
                onAdjustSource: (sourceIndex, amount) =>
                    bloc.add(.adjustSource(item.id, sourceIndex, amount)),
                onRemoveSource: (sourceIndex) =>
                    bloc.add(.removeSource(item.id, sourceIndex)),
                onChangeUnit: (unit) => bloc.add(.changeUnit(item.id, unit)),
                onAddBuffer: (amount) => bloc.add(.addBuffer(item.id, amount)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
