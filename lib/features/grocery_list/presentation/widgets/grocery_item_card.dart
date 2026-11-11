import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/features/features_flags.dart';
import '../../../../core/utils/amount_format.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../../../core/widgets/measurement_unit_label.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../domain/entities/grocery_item_entity.dart';
import '../../domain/grocery_list_edits.dart';
import '../bloc/grocery_list_bloc.dart';
import 'item_breakdown_sheet.dart';
import 'package:provider/provider.dart';
import '../../../price_book/presentation/price_book_service.dart';
import '../../../price_book/presentation/widgets/price_widgets.dart';
import '../../../price_book/presentation/widgets/add_price_dialog.dart';
import '../../../../core/constants/app_motion.dart';

/// One aggregated grocery line: a pressable clay card with a book spine, a
/// bouncy checkbox, and an accordion revealing which recipe contributed what.
/// How far an open disclosure chevron turns: a quarter clockwise in a
/// left-to-right layout. `chevron_right` is mirrored under RTL (it points
/// left), so there it turns a quarter the other way — clockwise would leave
/// an open row pointing up.
double disclosureOpenTurns(BuildContext context) =>
    Directionality.of(context) == TextDirection.rtl ? -0.25 : 0.25;

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
    final amountLabel = '${formatAmount(item.totalAmount)} $unit'.trim();
    final hasSources = item.sources.isNotEmpty;

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        HapticFeedback.mediumImpact();
        // Its place in the list, taken before it goes, for the undo.
        final state = bloc.state;
        final list = state is GroceryListLoaded ? state.list : null;
        final removed = list == null
            ? const <(int, GroceryItemEntity)>[]
            : GroceryListEdits.positionsOf(list, (i) => i.id == item.id);
        bloc.add(.removeItem(item.id));
        if (list == null ||
            removed.isEmpty ||
            !FeaturesFlags.undoInsteadOfConfirm.isEnabled) {
          return;
        }
        AppDialog.undo(
          context,
          message: t.groceryList.itemRemoved,
          onUndo: () => bloc.editList(
            list.id,
            (l) => GroceryListEdits.restore(l, removed),
          ),
        );
      },
      background: Container(
        decoration: BoxDecoration(
          color: AppColors.errorContainer,
          borderRadius: BorderRadius.circular(AppRadius.std),
        ),
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsetsDirectional.only(end: AppSpacing.marginMobile),
        child: Icon(Icons.delete_rounded, color: AppColors.onErrorContainer),
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
                    // The chevron mirrors itself under RTL (it points left there), so
                    // it turns the other way to land pointing down.
                    AnimatedRotation(
                      turns: _expanded ? disclosureOpenTurns(context) : 0,
                      duration: AppMotion.standard,
                      curve: AppMotion.easeOut,
                      child: Icon(
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
                            decoration: item.isChecked
                                ? TextDecoration.lineThrough
                                : null,
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
                  // What this line is likely to cost, from past receipts —
                  // only while the console has both the price book (whose
                  // records it reads and whose dialog it opens) and the
                  // cost estimate on. Hidden, coming soon or locked, the
                  // line shows no chip: the cost card under the list
                  // carries the tag, not every row.
                  ListenableBuilder(
                    listenable: FeaturesFlags.listenable,
                    builder: (context, child) =>
                        FeaturesFlags.priceBook.isEnabled &&
                            FeaturesFlags.groceryCost.isEnabled
                        ? child!
                        : const SizedBox.shrink(),
                    child: Consumer<PriceBookService>(
                      builder: (context, prices, _) => Padding(
                        padding: const EdgeInsetsDirectional.only(
                          end: AppSpacing.base,
                        ),
                        child: Builder(
                          builder: (context) {
                            final estimate = prices.estimateFor(item);
                            return InkWell(
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                              // A tap records a price by hand — the way in
                              // without a receipt, and the way to correct one.
                              onTap: () async {
                                final saved = await showAddPriceDialog(
                                  context,
                                  name: item.name,
                                  price: estimate.unitPrice,
                                  unit: estimate.unit,
                                );
                                if (saved) await prices.load();
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.xs),
                                child: PriceChip(
                                  estimate: estimate,
                                  multiplier: PriceBookService.multiplierFor(
                                    item,
                                    estimate,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  BouncyCheckbox(
                    value: item.isChecked,
                    onChanged: (_) => bloc.add(.toggleItem(item.id)),
                    semanticLabel: item.name,
                  ),
                ],
              ),
            ),
            AnimatedCrossFade(
              duration: AppMotion.standard,
              sizeCurve: AppMotion.easeOut,
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
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
                    '${formatAmount(source.amount)} $unit'.trim(),
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
                onAdjustSource: (sourceIndex, source, amount) {
                  if (bloc.isClosed) return;
                  bloc.add(
                    .adjustSource(
                      item.id,
                      sourceIndex,
                      amount,
                      recipeId: source.recipeId,
                      label: source.label,
                    ),
                  );
                },
                onRemoveSource: (sourceIndex, source) {
                  if (bloc.isClosed) return;
                  bloc.add(
                    .removeSource(
                      item.id,
                      sourceIndex,
                      recipeId: source.recipeId,
                      label: source.label,
                    ),
                  );
                },
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
