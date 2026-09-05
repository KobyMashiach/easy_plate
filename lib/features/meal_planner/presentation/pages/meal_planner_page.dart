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
import '../../../../core/widgets/weekday_selector.dart';
import '../../domain/entities/meal_plan_entity.dart';
import '../bloc/meal_planner_bloc.dart';
import '../widgets/meal_card.dart';

class MealPlannerPage extends StatelessWidget {
  const MealPlannerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MealPlannerBloc.fromContext(context),
      child: Builder(
        builder: (context) => ClayScaffold(
          appBar: ClayTopAppBar(
            title: t.appName,
            leading: const AccountAvatarButton(),
            actions: [
              IconButton(
                icon: const Icon(Icons.playlist_add_rounded, color: AppColors.primary),
                onPressed: () => _showCreatePlanDialog(context),
              ),
            ],
          ),
          body: BlocBuilder<MealPlannerBloc, MealPlannerState>(
            builder: (context, state) {
              return switch (state) {
                MealPlannerLoading() => const Center(child: CircularProgressIndicator()),
                MealPlannerLoaded(
                  plans: final plans,
                  selectedPlan: final selected,
                  recipeTitles: final titles,
                ) =>
                  selected == null
                      ? ClayEmptyState(
                          icon: Icons.calendar_month_rounded,
                          message: t.mealPlanner.noPlans,
                          action: ClayButton(
                            label: t.mealPlanner.newPlan,
                            icon: Icons.add_rounded,
                            onPressed: () => _showCreatePlanDialog(context),
                          ),
                        )
                      : _PlanBoard(plans: plans, plan: selected, recipeTitles: titles),
                MealPlannerError(error: final error) => ErrorRetryView(
                    error: error,
                    onRetry: () =>
                        context.read<MealPlannerBloc>().add(const MealPlannerEvent.init()),
                  ),
              };
            },
          ),
        ),
      ),
    );
  }

  void _showCreatePlanDialog(BuildContext context) {
    final bloc = context.read<MealPlannerBloc>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _CreatePlanForm(
        onSubmit: (name, template) => bloc.add(.createPlan(name, template)),
      ),
    );
  }
}

/// Name plus a starting template. The template only seeds meals across the
/// week — everything stays editable afterwards.
class _CreatePlanForm extends StatefulWidget {
  final void Function(String name, MealPlanTemplate template) onSubmit;

  const _CreatePlanForm({required this.onSubmit});

  @override
  State<_CreatePlanForm> createState() => _CreatePlanFormState();
}

class _CreatePlanFormState extends State<_CreatePlanForm> {
  final _nameController = TextEditingController();
  MealPlanTemplate _template = MealPlanTemplate.threeMeals;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  ({String label, String hint, IconData icon}) _describe(MealPlanTemplate template) =>
      switch (template) {
        MealPlanTemplate.free => (
            label: t.mealPlanner.templateFree,
            hint: t.mealPlanner.templateFreeHint,
            icon: Icons.tune_rounded,
          ),
        MealPlanTemplate.threeMeals => (
            label: t.mealPlanner.templateThree,
            hint: t.mealPlanner.templateThreeHint,
            icon: Icons.restaurant_rounded,
          ),
        MealPlanTemplate.sixMeals => (
            label: t.mealPlanner.templateSix,
            hint: t.mealPlanner.templateSixHint,
            icon: Icons.local_cafe_rounded,
          ),
      };

  /// Drives the save button's enabled state, so an empty name reads as a
  /// disabled button rather than a tap that silently does nothing.
  bool get _canSubmit => _nameController.text.trim().isNotEmpty;

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    widget.onSubmit(name, _template);
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
            Text(t.mealPlanner.newPlan, style: AppTextStyles.headlineMd),
            const SizedBox(height: AppSpacing.gutter),
            TextField(
              controller: _nameController,
              autofocus: true,
              style: AppTextStyles.bodyMd,
              decoration: InputDecoration(
                labelText: t.mealPlanner.planName,
                helperText: _canSubmit ? null : t.mealPlanner.nameRequired,
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(t.mealPlanner.template, style: AppTextStyles.labelMd),
            const SizedBox(height: AppSpacing.base),
            ...MealPlanTemplate.values.map((template) {
              final info = _describe(template);
              final isSelected = template == _template;

              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.base),
                child: ClayCard(
                  radius: AppRadius.md,
                  padding: const EdgeInsets.all(AppSpacing.gutter),
                  isActive: isSelected,
                  onTap: () => setState(() => _template = template),
                  child: Row(
                    children: [
                      Icon(
                        info.icon,
                        color: isSelected
                            ? AppColors.onPrimaryContainer
                            : AppColors.primary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              info.label,
                              style: AppTextStyles.bodyMd.copyWith(
                                color: isSelected
                                    ? AppColors.onPrimaryContainer
                                    : AppColors.onSurface,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              info.hint,
                              style: AppTextStyles.labelMd.copyWith(
                                color: isSelected
                                    ? AppColors.primaryFixed
                                    : AppColors.outline,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.onPrimaryContainer,
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

/// The board shows one weekday at a time, selected through the pill row —
/// the day is view state only, so no bloc event is involved.
class _PlanBoard extends StatefulWidget {
  final List<MealPlanEntity> plans;
  final MealPlanEntity plan;
  final Map<String, String> recipeTitles;

  const _PlanBoard({required this.plans, required this.plan, required this.recipeTitles});

  @override
  State<_PlanBoard> createState() => _PlanBoardState();
}

class _PlanBoardState extends State<_PlanBoard> {
  int _weekday = 0;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<MealPlannerBloc>();
    final meals = widget.plan.mealsForWeekday(_weekday);
    final days = ShoppingDay.values;

    return ListView(
      padding: const EdgeInsets.only(bottom: ClayNavDock.reservedHeight),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.marginMobile),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.md),
              ClayPageHeader(title: widget.plan.name, subtitle: t.mealPlanner.title),
              if (widget.plans.length > 1) ...[
                const SizedBox(height: AppSpacing.gutter),
                Wrap(
                  spacing: AppSpacing.base,
                  runSpacing: AppSpacing.base,
                  children: widget.plans.map((p) {
                    final isSelected = p.id == widget.plan.id;
                    return GestureDetector(
                      onTap: () => bloc.add(.selectPlan(p.id)),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.gutter,
                          vertical: AppSpacing.base,
                        ),
                        decoration: ShapeDecoration(
                          color: isSelected
                              ? AppColors.primaryFixed
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
                          p.name,
                          style: AppTextStyles.labelMd.copyWith(
                            color: isSelected ? AppColors.primary : AppColors.tertiary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
        ClayDaySelector(
          labels: [for (final day in days) weekdayLabel(day)],
          counts: [
            for (var i = 0; i < days.length; i++) widget.plan.mealsForWeekday(i).length,
          ],
          selectedIndex: _weekday,
          onSelected: (index) => setState(() => _weekday = index),
        ),
        const SizedBox(height: AppSpacing.lg),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.marginMobile),
          child: Column(
            children: [
              for (final meal in meals)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: MealCard(meal: meal, recipeTitles: widget.recipeTitles),
                ),
              ClayDashedCard(
                label: t.mealPlanner.addMeal,
                description: t.mealPlanner.addMealHint,
                onTap: () => _showAddMealDialog(context, bloc, _weekday),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showAddMealDialog(BuildContext context, MealPlannerBloc bloc, int weekday) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.mealPlanner.addMeal),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: t.mealPlanner.mealName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(t.common.cancel),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                bloc.add(.addMeal(weekday, controller.text.trim()));
              }
              Navigator.of(dialogContext).pop();
            },
            child: Text(t.common.add),
          ),
        ],
      ),
    );
  }
}
