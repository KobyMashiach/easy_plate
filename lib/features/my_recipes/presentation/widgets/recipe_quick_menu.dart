import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/features/feature_gate.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../../recipe_books/presentation/widgets/add_to_book_prompt.dart';
import '../../domain/entities/recipe_entity.dart';
import '../cook_mode_entry.dart';
import '../recipe_actions.dart';
import 'add_to_plan_sheet.dart';

/// The long-press menu on a recipe card (flag `recipeQuickMenu`): the things
/// people open a recipe only to reach — a book, the plan, the grocery list,
/// sharing, cook mode, delete — one press away from the grid.
///
/// Every row is the same flow the rest of the app uses and keeps its own
/// flag: a hidden feature has no row, a gated one is drawn with its tag and
/// explains itself on a tap. [onDelete] is the caller's, since the list
/// decides between the undo notice and the confirm; null leaves the row out.
Future<void> showRecipeQuickMenu(
  BuildContext context,
  RecipeEntity recipe, {
  VoidCallback? onDelete,
}) {
  HapticFeedback.mediumImpact();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) {
      /// Closes the menu, then runs [action] on the page's context: the
      /// sheet's own is gone once it pops.
      VoidCallback run(void Function() action) => () {
        Navigator.of(sheetContext).pop();
        action();
      };

      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.marginMobile,
            AppSpacing.md,
            AppSpacing.marginMobile,
            AppSpacing.marginMobile,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                recipe.title,
                style: AppTextStyles.headlineMd,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.gutter),
              FeatureGate(
                feature: FeaturesFlags.books,
                gapAfter: AppSpacing.base,
                child: _Row(
                  icon: Icons.menu_book_rounded,
                  label: t.recipe.addToBook,
                  onTap: run(() => showAddToBookPicker(context, recipe.id)),
                ),
              ),
              FeatureGate(
                feature: FeaturesFlags.mealPlans,
                gapAfter: AppSpacing.base,
                child: _Row(
                  icon: Icons.calendar_month_rounded,
                  label: t.recipe.addToPlan,
                  onTap: run(() => addRecipeToPlan(context, recipe)),
                ),
              ),
              if (recipe.ingredients.isNotEmpty)
                FeatureGate(
                  feature: FeaturesFlags.groceryFromRecipe,
                  gapAfter: AppSpacing.base,
                  child: _Row(
                    icon: Icons.shopping_cart_rounded,
                    label: t.groceryList.createFromRecipe,
                    onTap: run(() {
                      if (!guardFeature(
                        context,
                        FeaturesFlags.groceryFromRecipe,
                      )) {
                        return;
                      }
                      createGroceryListFromRecipe(context, recipe);
                    }),
                  ),
                ),
              if (canShareRecipe(recipe))
                FeatureGate(
                  feature: FeaturesFlags.shareRecipes,
                  gapAfter: AppSpacing.base,
                  child: _Row(
                    icon: Icons.person_add_alt_1_rounded,
                    label: t.sharing.shareAction,
                    onTap: run(() => shareRecipe(context, recipe)),
                  ),
                ),
              if (recipe.steps.isNotEmpty)
                FeatureGate(
                  feature: FeaturesFlags.cookMode,
                  gapAfter: AppSpacing.base,
                  child: _Row(
                    icon: Icons.local_fire_department_rounded,
                    label: t.cookMode.start,
                    onTap: run(() {
                      if (!guardFeature(context, FeaturesFlags.cookMode)) {
                        return;
                      }
                      openCookMode(context, recipe);
                    }),
                  ),
                ),
              if (onDelete != null)
                FeatureGate(
                  feature: FeaturesFlags.deleteRecipe,
                  child: _Row(
                    icon: recipe.isSavedFromCommunity
                        ? Icons.bookmark_remove_rounded
                        : Icons.delete_outline_rounded,
                    label: recipe.isSavedFromCommunity
                        ? t.community.removeSaved
                        : t.recipe.delete,
                    destructive: true,
                    onTap: run(() {
                      if (!guardFeature(context, FeaturesFlags.deleteRecipe)) {
                        return;
                      }
                      onDelete();
                    }),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  const _Row({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.error : AppColors.primary;
    return ClayCard(
      radius: AppRadius.md,
      padding: const EdgeInsets.all(AppSpacing.gutter),
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodyMd.copyWith(
                color: destructive ? AppColors.error : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
