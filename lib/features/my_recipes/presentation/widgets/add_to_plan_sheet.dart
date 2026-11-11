import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/features/feature_gate.dart';
import '../../../../core/hive/user_scope.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../../../core/widgets/weekday_selector.dart';
import '../../../collab_containers/domain/container_sharing_service.dart';
import '../../../meal_planner/data/datasources/planner_memory_store.dart';
import '../../../meal_planner/domain/entities/meal_entity.dart';
import '../../../meal_planner/domain/entities/meal_item_entity.dart';
import '../../../meal_planner/domain/entities/meal_plan_entity.dart';
import '../../../meal_planner/domain/repositories/meal_plans_repository.dart';
import '../../domain/entities/recipe_entity.dart';

/// Where in a plan a recipe goes: which plan, which day, which meal.
typedef PlanSlot = ({MealPlanEntity plan, int weekday, String mealName});

/// [plan] with [recipeId] appended to the meal named [mealName] on
/// [weekday], the meal created at the day's end when the day has none by
/// that name. The same shape the planner and the assistant write.
MealPlanEntity planWithRecipe(
  MealPlanEntity plan, {
  required int weekday,
  required String mealName,
  required String recipeId,
  required String Function() newId,
}) {
  final meals = [...plan.meals];
  var meal = plan
      .mealsForWeekday(weekday)
      .where((m) => m.name == mealName)
      .firstOrNull;
  if (meal == null) {
    meal = MealEntity(
      id: newId(),
      weekday: weekday,
      name: mealName,
      order: plan.mealsForWeekday(weekday).length,
      items: const [],
    );
    meals.add(meal);
  }
  final at = meals.indexWhere((m) => m.id == meal!.id);
  meals[at] = meal.copyWith(
    items: [
      ...meal.items,
      MealItemEntity(id: newId(), recipeId: recipeId),
    ],
  );
  return plan.copyWith(meals: meals);
}

/// "Add to meal plan" from a recipe card: picks a plan, a day and a meal,
/// then writes the item the way the planner does — saved, and published to
/// the members of a shared plan. Plans this account may only view are not
/// offered. Gated by the meal-plans flag like every other way into plans.
Future<void> addRecipeToPlan(BuildContext context, RecipeEntity recipe) async {
  if (!guardFeature(context, FeaturesFlags.mealPlans)) return;
  final repository = context.read<MealPlansRepository>();
  final sharing = context.read<ContainerSharingService>();
  final List<MealPlanEntity> plans;
  try {
    plans = [
      for (final p in await repository.getPlans())
        if (p.canEdit) p,
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  } catch (e) {
    debugPrint('Plans for the add-to-plan sheet failed: $e');
    if (context.mounted) {
      AppDialog.error(message: t.common.loadFailed).show(context);
    }
    return;
  }
  if (!context.mounted) return;
  if (plans.isEmpty) {
    AppDialog.info(message: t.recipe.noPlanToAdd).notify(context);
    return;
  }
  // The day last planned on comes first; today otherwise.
  final initialWeekday = FeaturesFlags.rememberLastChoices.isEnabled
      ? await PlannerMemoryStore.instance.lastWeekday()
      : null;
  if (!context.mounted) return;
  final slot = await showModalBottomSheet<PlanSlot>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _AddToPlanSheet(
      plans: plans,
      initialWeekday: initialWeekday,
    ),
  );
  if (slot == null || !context.mounted) return;
  const uuid = Uuid();
  try {
    await AppDialog.busy(context, () async {
      // From the plan as stored now, not the copy read before the sheet:
      // an edit landing meanwhile must not be written over.
      final stored = await repository.getPlanById(slot.plan.id) ?? slot.plan;
      final updated = planWithRecipe(
        stored,
        weekday: slot.weekday,
        mealName: slot.mealName,
        recipeId: recipe.id,
        newId: uuid.v4,
      );
      await repository.savePlan(updated);
      if (FeaturesFlags.rememberLastChoices.isEnabled) {
        unawaited(PlannerMemoryStore.instance.rememberWeekday(slot.weekday));
      }
      final uid = UserScope().uid;
      if (updated.isShared && uid != null) {
        // Best effort, as in the planner: the local save stands.
        try {
          await sharing.plans.publish(updated, uid: uid);
        } catch (e) {
          debugPrint('Shared plan publish failed: $e');
        }
      }
    });
  } catch (e) {
    debugPrint('Adding the recipe to a plan failed: $e');
    if (context.mounted) AppDialog.error(message: t.common.error).show(context);
    return;
  }
  if (!context.mounted) return;
  AppDialog.success(
    message: t.recipe.addedToPlan(
      day: weekdayLabel(ShoppingDay.values[slot.weekday]),
      meal: slot.mealName,
    ),
  ).notify(context);
}

class _AddToPlanSheet extends StatefulWidget {
  final List<MealPlanEntity> plans;
  final int? initialWeekday;

  const _AddToPlanSheet({required this.plans, this.initialWeekday});

  @override
  State<_AddToPlanSheet> createState() => _AddToPlanSheetState();
}

class _AddToPlanSheetState extends State<_AddToPlanSheet> {
  late MealPlanEntity _plan = widget.plans.first;

  /// The remembered day, else today — in the plan's Sunday-first week.
  late int _weekday = widget.initialWeekday ?? DateTime.now().weekday % 7;
  String? _meal;

  /// The meals offered for the chosen day: that day's own, then any other
  /// meal name the plan uses, then the three defaults for a plan that has
  /// none — a recipe always has somewhere to go.
  List<String> get _mealNames {
    final names = <String>[
      for (final m in _plan.mealsForWeekday(_weekday)) m.name,
    ];
    for (final m in _plan.meals) {
      if (!names.contains(m.name)) names.add(m.name);
    }
    if (names.isEmpty) {
      names.addAll([
        t.mealPlanner.breakfast,
        t.mealPlanner.lunch,
        t.mealPlanner.dinner,
      ]);
    }
    return names;
  }

  @override
  Widget build(BuildContext context) {
    final meals = _mealNames;
    final meal = meals.contains(_meal) ? _meal : null;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.marginMobile,
          AppSpacing.md,
          AppSpacing.marginMobile,
          AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(t.recipe.addToPlan, style: AppTextStyles.headlineMd),
            if (widget.plans.length > 1) ...[
              const SizedBox(height: AppSpacing.gutter),
              _Label(t.recipe.planLabel),
              Wrap(
                spacing: AppSpacing.base,
                runSpacing: AppSpacing.base,
                children: [
                  for (final plan in widget.plans)
                    ChoiceChip(
                      label: Text(plan.name),
                      selected: plan.id == _plan.id,
                      onSelected: (_) => setState(() => _plan = plan),
                    ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.gutter),
            _Label(t.recipe.dayLabel),
            WeekdaySelector(
              selected: ShoppingDay.values[_weekday],
              onSelect: (day) => setState(() => _weekday = day.index),
            ),
            const SizedBox(height: AppSpacing.gutter),
            _Label(t.recipe.mealLabel),
            Wrap(
              spacing: AppSpacing.base,
              runSpacing: AppSpacing.base,
              children: [
                for (final name in meals)
                  ChoiceChip(
                    label: Text(name),
                    selected: name == meal,
                    onSelected: (_) => setState(() => _meal = name),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            ClayButton(
              label: t.common.add,
              icon: Icons.add_rounded,
              expanded: true,
              onPressed: meal == null
                  ? null
                  : () => Navigator.of(
                      context,
                    ).pop((plan: _plan, weekday: _weekday, mealName: meal)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;

  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.base),
    child: Text(
      text,
      style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant),
    ),
  );
}
