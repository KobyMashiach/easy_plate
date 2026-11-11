import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/features/feature_gate.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../../user_profile/domain/entities/user_preferences_entity.dart';
import '../../../user_profile/domain/usecases/get_user_preferences_usecase.dart';
import '../../domain/entities/meal_plan_entity.dart';
import '../../domain/plan_fill.dart';
import '../bloc/meal_planner_bloc.dart';

/// The planner's whole-week shortcuts: fill the empty meals from the
/// account's recipes, copy an earlier plan's dishes, clear one day. Each is
/// made at once and offered back through the undo notice, and each goes
/// through [MealPlannerBloc.editPlan] — the same write, re-applied on the
/// stored plan and published to a shared plan's members, as a tap on the
/// board.

const _uuid = Uuid();

MealPlannerLoaded? _loaded(MealPlannerBloc bloc) {
  final state = bloc.state;
  return state is MealPlannerLoaded ? state : null;
}

Future<void> fillWeek(
  BuildContext context,
  MealPlannerBloc bloc,
  MealPlanEntity plan,
) async {
  final loaded = _loaded(bloc);
  if (loaded == null || !plan.canEdit) return;
  UserPreferencesEntity? prefs;
  try {
    prefs = await GetUserPreferencesUseCase(context.read())();
  } catch (e) {
    // Without the preferences nothing is ruled out by diet; the recipes'
    // own tags still keep the week varied.
    debugPrint('Preferences for the week fill failed: $e');
  }
  if (!context.mounted) return;
  final fill = WeekAutofill.plan(
    plan,
    loaded.recipes.values.toList(),
    newId: _uuid.v4,
    diet: prefs?.dietaryPreferences ?? const [],
    allergens: prefs?.activeAllergens ?? const [],
    usage: WeekAutofill.usageIn(loaded.plans.where((p) => p.id != plan.id)),
  );
  if (fill.emptySlots == 0) {
    AppDialog.info(message: t.mealPlanner.fillWeekNothing).notify(context);
    return;
  }
  if (fill.isEmpty) {
    AppDialog.warning(message: t.mealPlanner.fillWeekNoRecipes).notify(context);
    return;
  }
  bloc.editPlan(plan.id, fill.apply);
  AppDialog.undo(
    context,
    message: fill.filled < fill.emptySlots
        ? t.mealPlanner.fillWeekPartial(
            filled: fill.filled,
            total: fill.emptySlots,
          )
        : t.mealPlanner.fillWeekDone(count: fill.filled),
    icon: Icons.auto_awesome_rounded,
    onUndo: () => bloc.editPlan(plan.id, fill.undo),
  );
}

Future<void> copyWeek(
  BuildContext context,
  MealPlannerBloc bloc,
  MealPlanEntity plan,
) async {
  final loaded = _loaded(bloc);
  if (loaded == null || !plan.canEdit) return;
  final previous = WeekCopy.previous(plan, loaded.plans);
  if (previous == null) {
    AppDialog.info(message: t.mealPlanner.copyWeekNoSource).notify(context);
    return;
  }
  final others = [
    for (final p in loaded.plans)
      if (p.id != plan.id && p.meals.any((m) => m.items.isNotEmpty)) p,
  ];
  // One earlier plan: copied straight away. Several: the likely one first,
  // a tap away, the rest under it.
  final source = others.length == 1
      ? previous
      : await _pickSource(context, [
          previous,
          for (final p in others)
            if (p.id != previous.id) p,
        ]);
  if (source == null || !context.mounted) return;
  final fill = WeekCopy.plan(plan, source, newId: _uuid.v4);
  if (fill.isEmpty) {
    AppDialog.info(message: t.mealPlanner.copyWeekNothing).notify(context);
    return;
  }
  bloc.editPlan(plan.id, fill.apply);
  AppDialog.undo(
    context,
    message: t.mealPlanner.copyWeekDone(count: fill.filled, name: source.name),
    icon: Icons.content_copy_rounded,
    onUndo: () => bloc.editPlan(plan.id, fill.undo),
  );
}

Future<MealPlanEntity?> _pickSource(
  BuildContext context,
  List<MealPlanEntity> plans,
) {
  return showModalBottomSheet<MealPlanEntity>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.7,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.marginMobile,
            0,
            AppSpacing.marginMobile,
            AppSpacing.marginMobile,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.mealPlanner.copyWeekPick, style: AppTextStyles.headlineMd),
              const SizedBox(height: AppSpacing.gutter),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: plans.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.base),
                  itemBuilder: (_, index) {
                    final p = plans[index];
                    return ClayCard(
                      radius: AppRadius.md,
                      padding: const EdgeInsets.all(AppSpacing.gutter),
                      isActive: index == 0,
                      onTap: () => Navigator.of(sheetContext).pop(p),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_month_rounded,
                            color: index == 0
                                ? AppColors.onPrimaryContainer
                                : AppColors.primary,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              p.name,
                              style: AppTextStyles.bodyMd.copyWith(
                                color: index == 0
                                    ? AppColors.onPrimaryContainer
                                    : AppColors.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Takes every dish off [weekday], keeping its meals; Undo puts them back.
/// Only offered with the undo flag on — there was no "clear" before, and
/// without an undo it would be a destructive tap with no way back.
void clearDay(
  BuildContext context,
  MealPlannerBloc bloc,
  MealPlanEntity plan,
  int weekday,
) {
  if (!plan.canEdit) return;
  final before = plan.mealsForWeekday(weekday);
  if (before.every((m) => m.items.isEmpty)) return;
  bloc.editPlan(plan.id, (p) => PlanRestore.clearDay(p, weekday));
  AppDialog.undo(
    context,
    message: t.mealPlanner.dayCleared,
    onUndo: () => bloc.editPlan(plan.id, (p) => PlanRestore.meals(p, before)),
  );
}

/// One row of the plan's options sheet.
class PlanActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? hint;
  final VoidCallback onTap;

  const PlanActionRow({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return ClayCard(
      radius: AppRadius.md,
      padding: const EdgeInsets.all(AppSpacing.gutter),
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: AppTextStyles.bodyMd),
                if (hint != null)
                  Text(
                    hint!,
                    style: AppTextStyles.labelMd.copyWith(
                      color: AppColors.outline,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown while no meal of the plan has a dish yet: the two ways to fill the
/// week in one tap, each behind its own flag.
class EmptyWeekCard extends StatelessWidget {
  final MealPlanEntity plan;

  const EmptyWeekCard({super.key, required this.plan});

  static bool showsFor(MealPlanEntity plan) =>
      plan.canEdit &&
      plan.meals.every((m) => m.items.isEmpty) &&
      (FeaturesFlags.planAutofill.isVisible ||
          FeaturesFlags.planCopyWeek.isVisible);

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<MealPlannerBloc>();
    return ClayCard(
      radius: AppRadius.md,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t.mealPlanner.emptyWeek, style: AppTextStyles.bodyLg),
          const SizedBox(height: AppSpacing.xs),
          Text(
            t.mealPlanner.emptyWeekHint,
            style: AppTextStyles.labelMd.copyWith(color: AppColors.outline),
          ),
          const SizedBox(height: AppSpacing.gutter),
          // A free plan has no meals to fill yet; copying can still bring
          // an earlier week's meals in whole.
          if (plan.meals.isNotEmpty)
            FeatureGate(
              feature: FeaturesFlags.planAutofill,
              gapAfter: AppSpacing.base,
              child: ClayButton(
                label: t.mealPlanner.fillWeek,
                icon: Icons.auto_awesome_rounded,
                expanded: true,
                onPressed: () => fillWeek(context, bloc, plan),
              ),
            ),
          FeatureGate(
            feature: FeaturesFlags.planCopyWeek,
            child: TextButton.icon(
              icon: const Icon(Icons.content_copy_rounded, size: 18),
              label: Text(t.mealPlanner.copyWeek),
              onPressed: () => copyWeek(context, bloc, plan),
            ),
          ),
        ],
      ),
    );
  }
}
