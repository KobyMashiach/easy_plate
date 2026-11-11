import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/features/feature_gate.dart';
import '../../../core/navigation/main_tabs.dart';
import '../../../core/utils/i18n/strings.g.dart';
import '../../../core/utils/routing/routing.dart';
import '../../../core/utils/undoable_removals.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../grocery_list/data/datasources/active_grocery_list_store.dart';
import '../../grocery_list/domain/repositories/grocery_lists_repository.dart';
import '../../grocery_list/domain/usecases/create_recipe_grocery_list_usecase.dart';
import '../../grocery_list/presentation/widgets/grocery_lists_ui.dart';
import '../../recipe_sharing/presentation/widgets/recipe_share_sheet.dart';
import '../domain/entities/recipe_entity.dart';
import '../domain/repositories/recipes_repository.dart';

// The actions a recipe offers from more than one screen — the details page
// and the card's quick menu — written once so both behave the same.

/// A new shopping list holding [recipe]'s ingredients, scaled to how much is
/// being made — then, if the user wants, straight to it.
Future<void> createGroceryListFromRecipe(
  BuildContext context,
  RecipeEntity recipe,
) async {
  final options = await showRecipeGroceryListSheet(context, recipe);
  if (options == null || !context.mounted) return;
  final create = CreateRecipeGroceryListUseCase(
    context.read<GroceryListsRepository>(),
    HiveActiveGroceryListStore.instance,
  );
  try {
    final list = await AppDialog.busy(
      context,
      () => create(recipe, name: options.name, scale: options.scale),
    );
    if (!context.mounted) return;
    final open = await AppDialog.info(
      message: t.groceryList.listCreated(name: list.name),
      icon: Icons.shopping_cart_rounded,
      confirmLabel: t.groceryList.openList,
      cancelLabel: t.groceryList.stayHere,
    ).show(context);
    if (open != true || !context.mounted) return;
    // The groceries tab already opened the new list (it follows the
    // active-list store); this only takes the user there.
    MainTabs.index.value = MainTabs.groceries;
    context.goNamed(Routing.home);
  } catch (e) {
    debugPrint('Grocery list from recipe failed: $e');
    if (context.mounted) {
      AppDialog.error(message: t.common.error).show(context);
    }
  }
}

/// Whether [recipe] may be passed on from this account: only one it wrote —
/// a member of someone else's recipe cannot invite others, and a copy saved
/// from the community is not this account's to hand on.
bool canShareRecipe(RecipeEntity recipe) =>
    recipe.isMine && FeaturesFlags.shareRecipes.isVisible;

/// The share sheet for [recipe], behind its flag.
Future<void> shareRecipe(BuildContext context, RecipeEntity recipe) async {
  if (!guardFeature(context, FeaturesFlags.shareRecipes)) return;
  final sent = await showRecipeShareSheet(context, recipe);
  if (sent == true && context.mounted) {
    AppDialog.success(message: t.sharing.sent).notify(context);
  }
}

/// The key a recipe waiting out its undo window is hidden under; the lists
/// leave out every recipe whose key is pending.
String recipeRemovalKey(String id) => UndoableRemovals.keyFor('recipe', id);

/// The undo version of deleting [recipe] (flag `undoInsteadOfConfirm`): the
/// recipe leaves the lists at once and is only really deleted when the
/// notice goes without an undo — so its photo, its cloud copy, its
/// translations and its place in every book and plan are untouched until
/// then, and an undo puts back exactly what was there.
///
/// A recipe delete has no server effect beyond this account's own mirror —
/// a shared recipe stays with everyone else in the share — so no recipe
/// delete needs the confirm kept.
void deleteRecipeWithUndo(BuildContext context, RecipeEntity recipe) {
  final repository = context.read<RecipesRepository>();
  UndoableRemovals.instance.remove(
    context,
    key: recipeRemovalKey(recipe.id),
    message: recipe.isSavedFromCommunity
        ? t.recipe.savedRemoved
        : t.recipe.deleted,
    icon: recipe.isSavedFromCommunity
        ? Icons.bookmark_remove_rounded
        : Icons.delete_outline_rounded,
    commit: () => repository.deleteRecipe(recipe.id),
  );
}
