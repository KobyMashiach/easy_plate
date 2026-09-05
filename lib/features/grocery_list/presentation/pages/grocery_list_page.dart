import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/account_avatar_button.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../../../core/widgets/error_retry_view.dart';
import '../../../../core/widgets/measurement_unit_label.dart';
import '../../domain/entities/grocery_list_entity.dart';
import '../bloc/grocery_list_bloc.dart';
import '../../../meal_planner/domain/entities/meal_plan_entity.dart';
import '../widgets/grocery_progress_card.dart';
import '../widgets/meal_plan_filter_card.dart';
import '../widgets/grocery_section.dart';

class GroceryListPage extends StatelessWidget {
  const GroceryListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GroceryListBloc.fromContext(context),
      child: Builder(
        builder: (context) => ClayScaffold(
          appBar: ClayTopAppBar(
            title: t.appName,
            leading: const AccountAvatarButton(),
            actions: [
              IconButton(
                icon: const Icon(Icons.autorenew_rounded, color: AppColors.primary),
                onPressed: () =>
                    context.read<GroceryListBloc>().add(const GroceryListEvent.regenerate()),
              ),
              IconButton(
                icon: const Icon(Icons.add_rounded, color: AppColors.primary),
                onPressed: () => showAddGroceryItemSheet(context),
              ),
            ],
          ),
          body: BlocBuilder<GroceryListBloc, GroceryListState>(
            builder: (context, state) {
              return switch (state) {
                GroceryListLoading() => const Center(child: CircularProgressIndicator()),
                GroceryListLoaded(list: final list, plans: final plans) =>
                  _ListBody(list: list, plans: plans),
                GroceryListError(error: final error) => ErrorRetryView(
                    error: error,
                    onRetry: () =>
                        context.read<GroceryListBloc>().add(const GroceryListEvent.init()),
                  ),
              };
            },
          ),
        ),
      ),
    );
  }
}

class _ListBody extends StatelessWidget {
  final GroceryListEntity list;
  final List<MealPlanEntity> plans;

  const _ListBody({required this.list, required this.plans});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<GroceryListBloc>();

    if (list.items.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.marginMobile,
          AppSpacing.md,
          AppSpacing.marginMobile,
          ClayNavDock.reservedHeight,
        ),
        children: [
          ClayPageHeader(title: t.groceryList.title),
          const SizedBox(height: AppSpacing.lg),
          MealPlanFilterCard(list: list, plans: plans),
          const SizedBox(height: AppSpacing.lg),
          ClayEmptyState(
            icon: Icons.shopping_basket_rounded,
            message: t.groceryList.empty,
            action: ClayButton(
              label: t.groceryList.aggregated,
              icon: Icons.autorenew_rounded,
              onPressed: () => bloc.add(const GroceryListEvent.regenerate()),
            ),
          ),
        ],
      );
    }

    final unchecked = list.items.where((i) => !i.isChecked).toList();
    final checked = list.items.where((i) => i.isChecked).toList();
    final allChecked = unchecked.isEmpty;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.marginMobile,
        AppSpacing.md,
        AppSpacing.marginMobile,
        ClayNavDock.reservedHeight,
      ),
      children: [
        ClayPageHeader(title: t.groceryList.title),
        const SizedBox(height: AppSpacing.lg),
        MealPlanFilterCard(list: list, plans: plans),
        const SizedBox(height: AppSpacing.gutter),
        GroceryProgressCard(collected: checked.length, total: list.items.length),
        const SizedBox(height: AppSpacing.gutter),
        Row(
          children: [
            Expanded(
              child: _BulkAction(
                icon: allChecked
                    ? Icons.remove_done_rounded
                    : Icons.done_all_rounded,
                label: allChecked ? t.groceryList.clearAll : t.groceryList.selectAll,
                onTap: () => bloc.add(.setAllChecked(!allChecked)),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _BulkAction(
                icon: Icons.delete_sweep_rounded,
                label: t.groceryList.deleteChecked,
                isDestructive: true,
                onTap: checked.isEmpty
                    ? null
                    : () => bloc.add(const GroceryListEvent.deleteCheckedItems()),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        GrocerySection(title: t.groceryList.uncheckedSection, items: unchecked),
        const SizedBox(height: AppSpacing.lg),
        GrocerySection(
          title: t.groceryList.checkedSection,
          items: checked,
          // Collected lines are done with — kept out of the way by default.
          initiallyExpanded: false,
        ),
      ],
    );
  }
}

class _BulkAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isDestructive;

  const _BulkAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final color = !enabled
        ? AppColors.outlineVariant
        : isDestructive
            ? AppColors.error
            : AppColors.primary;

    return ClayCard(
      radius: AppRadius.full,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: AppSpacing.base),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelMd.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

/// Adds a free-text line. It captures a quantity and unit up front so the new
/// item behaves exactly like one that came from a recipe.
Future<void> showAddGroceryItemSheet(BuildContext context) {
  final bloc = context.read<GroceryListBloc>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => _AddItemForm(
      onSubmit: (name, amount, unit) => bloc.add(.addAdHocItem(name, amount, unit)),
    ),
  );
}

class _AddItemForm extends StatefulWidget {
  final void Function(String name, double amount, MeasurementUnit unit) onSubmit;

  const _AddItemForm({required this.onSubmit});

  @override
  State<_AddItemForm> createState() => _AddItemFormState();
}

class _AddItemFormState extends State<_AddItemForm> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController(text: '1');
  MeasurementUnit _unit = MeasurementUnit.unit;

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  /// Drives the add button's enabled state, so an empty name reads as a
  /// disabled button rather than a tap that silently does nothing.
  bool get _canSubmit => _nameController.text.trim().isNotEmpty;

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final amount = double.tryParse(_amountController.text.trim()) ?? 1;
    widget.onSubmit(name, amount, _unit);
    Navigator.of(context).pop();
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
            Text(t.groceryList.addItem, style: AppTextStyles.headlineMd),
            const SizedBox(height: AppSpacing.gutter),
            TextField(
              controller: _nameController,
              autofocus: true,
              style: AppTextStyles.bodyMd,
              decoration: InputDecoration(labelText: t.groceryList.itemName),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: AppTextStyles.bodyMd,
              decoration: InputDecoration(labelText: t.groceryList.amount),
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
                  onTap: () => setState(() => _unit = unit),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
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
                        color: isSelected ? AppColors.onPrimary : AppColors.tertiary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.lg),
            ClayButton(
              label: t.common.add,
              icon: Icons.add_rounded,
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
