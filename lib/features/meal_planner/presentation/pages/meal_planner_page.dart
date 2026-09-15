import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/account_avatar_button.dart';
import '../../../../core/widgets/notification_bell_button.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../../../core/widgets/error_retry_view.dart';
import '../../../../core/widgets/weekday_selector.dart';
import '../../domain/entities/meal_plan_entity.dart';
import '../bloc/meal_planner_bloc.dart';
import '../widgets/meal_card.dart';
import '../widgets/day_nutrition_card.dart';
import '../../domain/nutrition_summary.dart';
import '../../../my_recipes/domain/entities/recipe_entity.dart';
import '../../../../core/utils/routing/routing.dart';
import 'nutrition_dashboard_page.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/walkthrough/walkthrough.dart';
import '../../../../core/walkthrough/app_walkthroughs.dart';
import '../../../collab_containers/presentation/widgets/container_share_sheets.dart';

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
            actions: const [NotificationBellButton()],
          ),
          body: BlocBuilder<MealPlannerBloc, MealPlannerState>(
            builder: (context, state) {
              return switch (state) {
                MealPlannerLoading() => const Center(
                  child: CircularProgressIndicator(),
                ),
                MealPlannerLoaded(
                  plans: final plans,
                  selectedPlan: final selected,
                  recipeTitles: final titles,
                  recipes: final recipes,
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
                      : _PlanBoard(
                          plans: plans,
                          plan: selected,
                          recipeTitles: titles,
                          recipes: recipes,
                        ),
                MealPlannerError(error: final error) => ErrorRetryView(
                  error: error,
                  onRetry: () => context.read<MealPlannerBloc>().add(
                    const MealPlannerEvent.init(),
                  ),
                ),
              };
            },
          ),
        ),
      ),
    );
  }
}

/// Top level rather than a method: the board's header reaches it too.
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

  ({String label, String hint, IconData icon}) _describe(
    MealPlanTemplate template,
  ) => switch (template) {
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
        bottom:
            MediaQuery.of(context).viewInsets.bottom + AppSpacing.marginMobile,
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
                        Icon(
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
  final Map<String, RecipeEntity> recipes;

  const _PlanBoard({
    required this.plans,
    required this.plan,
    required this.recipeTitles,
    required this.recipes,
  });

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
    final nutrition = PlanNutrition.of(widget.plan, widget.recipes);

    // The plan's name floats away as the board scrolls and returns on the
    // first scroll back up; the actions stay in their corner throughout.
    return ClayFloatingHeaderView(
      title: widget.plan.name,
      subtitle: t.mealPlanner.title,
      bottomGap: 0,
      trailingWidth: widget.plan.isMine ? 48 * 2 + AppSpacing.base : 48,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Only the owner hands a plan on; a member cannot share it further.
          if (widget.plan.isMine) ...[
            ClayIconButton(
              icon: Icons.person_add_alt_1_rounded,
              size: 48,
              tooltip: t.sharing.sharePlan,
              onTap: () async {
                final sent = await showPlanShareSheet(context, widget.plan);
                if (sent == true && context.mounted) {
                  AppDialog.success(message: t.sharing.sent).notify(context);
                  // The share tags the plan with its collab id.
                  bloc.add(.selectPlan(widget.plan.id));
                }
              },
            ),
            const SizedBox(width: AppSpacing.base),
          ],
          WalkthroughTarget(
            id: WalkthroughIds.mealPlanAdd,
            child: ClayIconButton(
              icon: Icons.playlist_add_rounded,
              filled: true,
              size: 48,
              tooltip: t.mealPlanner.newPlan,
              onTap: () => _showCreatePlanDialog(context),
            ),
          ),
        ],
      ),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.only(bottom: ClayNavDock.bottomPadding(context)),
          sliver: SliverList.list(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.marginMobile,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.plan.isShared) ...[
                      const SizedBox(height: AppSpacing.base),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: ClayTag(
                          label: switch (widget.plan.collabRole) {
                            CollabRole.owner => t.sharing.ownerTag,
                            CollabRole.editor => t.sharing.editorTag,
                            _ => t.sharing.viewerTag,
                          },
                          icon: Icons.group_rounded,
                          background: AppColors.secondaryContainer,
                          foreground: AppColors.onSecondaryContainer,
                        ),
                      ),
                    ],
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
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.tertiary,
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
                  for (var i = 0; i < days.length; i++)
                    widget.plan.mealsForWeekday(i).length,
                ],
                selectedIndex: _weekday,
                onSelected: (index) => setState(() => _weekday = index),
              ),
              const SizedBox(height: AppSpacing.gutter),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.marginMobile,
                ),
                child: DayNutritionCard(
                  day: nutrition.day(_weekday),
                  onOpenDashboard: () => context.pushNamed(
                    Routing.nutritionDashboard,
                    extra: NutritionDashboardArgs(
                      plan: widget.plan,
                      recipes: widget.recipes,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.gutter),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.marginMobile,
                ),
                child: Column(
                  children: [
                    for (final meal in meals)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: MealCard(
                          meal: meal,
                          recipeTitles: widget.recipeTitles,
                          readOnly: !widget.plan.canEdit,
                        ),
                      ),
                    if (widget.plan.canEdit)
                      ClayDashedCard(
                        label: t.mealPlanner.addMeal,
                        description: t.mealPlanner.addMealHint,
                        onTap: () =>
                            _showAddMealDialog(context, bloc, _weekday),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showAddMealDialog(
    BuildContext context,
    MealPlannerBloc bloc,
    int weekday,
  ) async {
    final name = await AppDialog.prompt(
      context,
      title: t.mealPlanner.addMeal,
      icon: Icons.restaurant_rounded,
      hint: t.mealPlanner.mealName,
      confirmLabel: t.common.add,
    );
    if (name != null) bloc.add(.addMeal(weekday, name));
  }
}
