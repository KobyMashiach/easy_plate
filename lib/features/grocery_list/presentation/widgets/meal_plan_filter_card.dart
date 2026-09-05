import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../../meal_planner/domain/entities/meal_plan_entity.dart';
import '../../domain/entities/grocery_list_entity.dart';
import '../bloc/grocery_list_bloc.dart';

/// Which menus feed the aggregation: a drawer that reads "all menus" until the
/// shopper narrows it, and the button that opens the picker.
class MealPlanFilterCard extends StatefulWidget {
  final GroceryListEntity list;
  final List<MealPlanEntity> plans;

  const MealPlanFilterCard({super.key, required this.list, required this.plans});

  @override
  State<MealPlanFilterCard> createState() => _MealPlanFilterCardState();
}

class _MealPlanFilterCardState extends State<MealPlanFilterCard> {
  bool _expanded = false;

  /// The plans actually feeding the list. An id whose plan has since been
  /// deleted simply drops out.
  List<MealPlanEntity> get _included {
    if (widget.list.includesAllPlans) return widget.plans;
    return widget.plans.where((p) => widget.list.selectedPlanIds.contains(p.id)).toList();
  }

  String get _summary {
    if (widget.list.includesAllPlans) return t.groceryList.planFilter;
    final count = _included.length;
    if (count == 1) return t.groceryList.onePlanSelected;
    return t.groceryList.plansSelected(count: count);
  }

  @override
  Widget build(BuildContext context) {
    return ClayCard(
      radius: AppRadius.md,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                const Icon(Icons.filter_list_rounded, size: 20, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_summary, style: AppTextStyles.bodyLg),
                      Text(
                        widget.list.includesAllPlans
                            ? t.groceryList.allPlansHint
                            : _included.map((p) => p.name).join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.labelMd
                            .copyWith(color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.tertiary,
                  ),
                ),
              ],
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState:
                _expanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            firstChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.sm),
                if (_included.isEmpty)
                  Text(
                    t.groceryList.noPlansToPick,
                    style: AppTextStyles.labelMd.copyWith(color: AppColors.onSurfaceVariant),
                  )
                else
                  Wrap(
                    spacing: AppSpacing.base,
                    runSpacing: AppSpacing.base,
                    children: [
                      for (final plan in _included)
                        ClayTag(label: plan.name, icon: Icons.calendar_today_rounded),
                    ],
                  ),
              ],
            ),
            secondChild: const SizedBox(width: double.infinity),
          ),
          const SizedBox(height: AppSpacing.md),
          ClayButton(
            label: t.groceryList.choosePlans,
            icon: Icons.checklist_rounded,
            expanded: true,
            onPressed: widget.plans.isEmpty ? null : () => _openPicker(context),
          ),
        ],
      ),
    );
  }

  Future<void> _openPicker(BuildContext context) async {
    final bloc = context.read<GroceryListBloc>();
    final selected = await showMealPlanPickerSheet(
      context,
      plans: widget.plans,
      // "All" is stored as an empty list, but the sheet ticks every row so the
      // shopper sees what is actually included.
      initiallySelected: widget.list.includesAllPlans
          ? widget.plans.map((p) => p.id).toSet()
          : widget.list.selectedPlanIds.toSet(),
    );
    if (selected == null) return;

    // Everything ticked collapses back to "all", so a plan added later is
    // picked up instead of being silently excluded by a frozen id list.
    final everything = selected.length == widget.plans.length;
    bloc.add(GroceryListEvent.selectPlans(everything ? const [] : selected.toList()));
  }
}

/// Returns the chosen plan ids, or null when the sheet was dismissed.
Future<Set<String>?> showMealPlanPickerSheet(
  BuildContext context, {
  required List<MealPlanEntity> plans,
  required Set<String> initiallySelected,
}) {
  return showModalBottomSheet<Set<String>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceContainerLowest,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.md)),
    ),
    builder: (sheetContext) => _MealPlanPickerSheet(
      plans: plans,
      initiallySelected: initiallySelected,
    ),
  );
}

class _MealPlanPickerSheet extends StatefulWidget {
  final List<MealPlanEntity> plans;
  final Set<String> initiallySelected;

  const _MealPlanPickerSheet({required this.plans, required this.initiallySelected});

  @override
  State<_MealPlanPickerSheet> createState() => _MealPlanPickerSheetState();
}

class _MealPlanPickerSheetState extends State<_MealPlanPickerSheet> {
  late final Set<String> _selected = {...widget.initiallySelected};

  bool get _allSelected => _selected.length == widget.plans.length;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.md,
          right: AppSpacing.md,
          top: AppSpacing.md,
          bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClaySectionHeader(title: t.groceryList.selectPlansTitle, underline: true),
            const SizedBox(height: AppSpacing.sm),
            _row(
              label: t.groceryList.selectAllPlans,
              checked: _allSelected,
              onChanged: (checked) => setState(() {
                _selected
                  ..clear()
                  ..addAll(checked ? widget.plans.map((p) => p.id) : const <String>[]);
              }),
              emphasised: true,
            ),
            const Divider(color: AppColors.outlineVariant),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final plan in widget.plans)
                    _row(
                      label: plan.name,
                      checked: _selected.contains(plan.id),
                      onChanged: (checked) => setState(() {
                        if (checked) {
                          _selected.add(plan.id);
                        } else {
                          _selected.remove(plan.id);
                        }
                      }),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ClayButton(
              label: t.groceryList.applySelection,
              icon: Icons.check_rounded,
              expanded: true,
              // An empty pick would aggregate nothing, so it cannot be applied.
              onPressed: _selected.isEmpty ? null : () => Navigator.of(context).pop(_selected),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row({
    required String label,
    required bool checked,
    required ValueChanged<bool> onChanged,
    bool emphasised = false,
  }) {
    return InkWell(
      onTap: () => onChanged(!checked),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.base),
        child: Row(
          children: [
            BouncyCheckbox(value: checked, onChanged: (_) => onChanged(!checked)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                label,
                style: emphasised ? AppTextStyles.bodyLg : AppTextStyles.bodyMd,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
