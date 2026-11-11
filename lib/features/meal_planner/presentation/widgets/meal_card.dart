import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/features/features_flags.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../data/datasources/planner_memory_store.dart';
import '../../domain/plan_fill.dart';
import '../../../my_recipes/presentation/widgets/recipe_picker_sheet.dart';
import '../../domain/entities/meal_entity.dart';
import '../../domain/entities/meal_item_entity.dart';
import '../bloc/meal_planner_bloc.dart';
import 'quick_entry_sheet.dart';

/// One meal slot of the selected day: a clay card with a book spine, the meal
/// name as a slot tag, its items, and the actions that fill it.
class MealCard extends StatelessWidget {
  final MealEntity meal;
  final Map<String, String> recipeTitles;

  /// A plan shared with this account for viewing: no removing, no adding.
  final bool readOnly;

  const MealCard({
    super.key,
    required this.meal,
    required this.recipeTitles,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<MealPlannerBloc>();

    return ClayCard(
      showSpine: true,
      padding: const EdgeInsets.all(AppSpacing.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: ClayTag(
                  label: meal.name,
                  icon: Icons.restaurant_rounded,
                ),
              ),
              if (!readOnly)
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                  color: AppColors.outline,
                  tooltip: t.common.delete,
                  onPressed: () => _removeMeal(context, bloc),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (meal.items.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.base),
              child: Text(
                t.mealPlanner.addMealHint,
                style: AppTextStyles.labelMd.copyWith(color: AppColors.outline),
              ),
            )
          else
            for (final item in meal.items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: GestureDetector(
                  // Quick entries stay editable so products can be added after
                  // the fact; recipe-backed items own their ingredients.
                  onTap: item.recipeId != null || readOnly
                      ? null
                      : () => _editQuickEntry(context, bloc, item),
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    children: [
                      Icon(
                        item.recipeId != null
                            ? Icons.menu_book_rounded
                            : Icons.edit_note_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: AppSpacing.base),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              item.recipeId != null
                                  ? (recipeTitles[item.recipeId] ??
                                        t.common.missingInfo)
                                  : (item.freeText ?? ''),
                              style: AppTextStyles.bodyMd,
                            ),
                            if (item.ingredients.isNotEmpty)
                              Text(
                                item.ingredients.map((i) => i.name).join(' · '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.labelSm.copyWith(
                                  color: AppColors.outline,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (!readOnly)
                        MinTapTarget(
                          child: Semantics(
                            button: true,
                            label: MaterialLocalizations.of(
                              context,
                            ).deleteButtonTooltip,
                            child: GestureDetector(
                              onTap: () => _removeItem(context, bloc, item),
                              behavior: HitTestBehavior.opaque,
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.xs),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 16,
                                  color: AppColors.outline,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          if (!readOnly) ...[
            const Divider(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    icon: const Icon(Icons.restaurant_menu_rounded, size: 18),
                    label: Text(t.mealPlanner.pickRecipe),
                    onPressed: () async {
                      final recipe = await showRecipePickerSheet(context);
                      if (recipe != null) {
                        bloc.add(.addRecipeItem(meal.id, recipe.id));
                        _remember();
                      }
                    },
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    icon: const Icon(Icons.edit_note_rounded, size: 18),
                    label: Text(t.mealPlanner.quickEntry),
                    onPressed: () =>
                        _showQuickEntryDialog(context, bloc, meal.id),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showQuickEntryDialog(
    BuildContext context,
    MealPlannerBloc bloc,
    String mealId,
  ) async {
    final result = await showQuickEntrySheet(context);
    if (result == null) return;
    bloc.add(.addFreeTextItem(mealId, result.text, result.ingredients));
    _remember();
  }

  /// The day a dish was last put on, so the board reopens there.
  void _remember() {
    if (FeaturesFlags.rememberLastChoices.isEnabled) {
      PlannerMemoryStore.instance.rememberWeekday(meal.weekday);
    }
  }

  String? _planId(MealPlannerBloc bloc) {
    final state = bloc.state;
    return state is MealPlannerLoaded ? state.selectedPlan?.id : null;
  }

  /// Gone at once, as before; with the undo flag on, the notice can put the
  /// meal back with its dishes — onto the plan as stored by then.
  void _removeMeal(BuildContext context, MealPlannerBloc bloc) {
    final planId = _planId(bloc);
    bloc.add(.removeMeal(meal.id));
    if (planId == null || !FeaturesFlags.undoInsteadOfConfirm.isEnabled) {
      return;
    }
    final removed = meal;
    AppDialog.undo(
      context,
      message: t.mealPlanner.mealRemoved,
      onUndo: () =>
          bloc.editPlan(planId, (plan) => PlanRestore.meal(plan, removed)),
    );
  }

  void _removeItem(
    BuildContext context,
    MealPlannerBloc bloc,
    MealItemEntity item,
  ) {
    final planId = _planId(bloc);
    final index = meal.items.indexWhere((i) => i.id == item.id);
    bloc.add(.removeItem(meal.id, item.id));
    if (planId == null || !FeaturesFlags.undoInsteadOfConfirm.isEnabled) {
      return;
    }
    final mealId = meal.id;
    AppDialog.undo(
      context,
      message: t.mealPlanner.dishRemoved,
      onUndo: () => bloc.editPlan(
        planId,
        (plan) => PlanRestore.item(plan, mealId, item, index),
      ),
    );
  }

  Future<void> _editQuickEntry(
    BuildContext context,
    MealPlannerBloc bloc,
    MealItemEntity item,
  ) async {
    final result = await showQuickEntrySheet(
      context,
      initialText: item.freeText ?? '',
      initialIngredients: item.ingredients,
    );
    if (result == null) return;
    bloc.add(
      .updateFreeTextItem(meal.id, item.id, result.text, result.ingredients),
    );
  }
}
