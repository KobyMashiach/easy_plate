import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/clay/clay.dart';
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

  const MealCard({super.key, required this.meal, required this.recipeTitles});

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
                child: ClayTag(label: meal.name, icon: Icons.restaurant_rounded),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 20),
                color: AppColors.outline,
                tooltip: t.common.delete,
                onPressed: () => bloc.add(.removeMeal(meal.id)),
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
                  onTap: item.recipeId != null
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
                                  ? (recipeTitles[item.recipeId] ?? t.common.missingInfo)
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
                      GestureDetector(
                        onTap: () => bloc.add(.removeItem(meal.id, item.id)),
                        behavior: HitTestBehavior.opaque,
                        child: const Padding(
                          padding: EdgeInsets.all(AppSpacing.xs),
                          child: Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: AppColors.outline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          const Divider(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  icon: const Icon(Icons.restaurant_menu_rounded, size: 18),
                  label: Text(t.mealPlanner.pickRecipe),
                  onPressed: () async {
                    final recipe = await showRecipePickerSheet(context);
                    if (recipe != null) bloc.add(.addRecipeItem(meal.id, recipe.id));
                  },
                ),
              ),
              Expanded(
                child: TextButton.icon(
                  icon: const Icon(Icons.edit_note_rounded, size: 18),
                  label: Text(t.mealPlanner.quickEntry),
                  onPressed: () => _showQuickEntryDialog(context, bloc, meal.id),
                ),
              ),
            ],
          ),
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
    bloc.add(.updateFreeTextItem(meal.id, item.id, result.text, result.ingredients));
  }
}
