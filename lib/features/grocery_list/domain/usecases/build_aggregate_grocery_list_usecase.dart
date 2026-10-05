import '../../../../core/constants/app_enums.dart';
import '../../../meal_planner/domain/entities/meal_plan_entity.dart';
import '../../../my_recipes/domain/entities/recipe_entity.dart';
import '../../../my_recipes/domain/entities/recipe_ingredient_entity.dart';
import '../../../my_recipes/domain/repositories/recipes_repository.dart';
import '../entities/grocery_item_entity.dart';
import '../entities/grocery_item_source_entity.dart';

/// Scans every active meal plan, resolves each recipe reference to its
/// ingredients, and sums identical ingredients (matched by normalized
/// name + unit) into a single aggregated line — see spec §6.1.
class BuildAggregateGroceryListUseCase {
  final RecipesRepository recipesRepository;
  BuildAggregateGroceryListUseCase(this.recipesRepository);

  Future<List<GroceryItemEntity>> call(List<MealPlanEntity> activePlans) async {
    final aggregated = <String, GroceryItemEntity>{};

    for (final plan in activePlans) {
      for (final meal in plan.meals) {
        for (final item in meal.items) {
          if (item.recipeId != null) {
            final recipe = await recipesRepository.getRecipeById(
              item.recipeId!,
            );
            if (recipe == null) continue;

            _addIngredients(
              aggregated,
              ingredients: recipe.ingredients,
              sourceLabel: recipe.title,
              recipeId: recipe.id,
            );
          } else if (item.freeText != null &&
              item.freeText!.trim().isNotEmpty) {
            if (item.ingredients.isNotEmpty) {
              // A quick entry that lists its products behaves like a recipe:
              // the products are what gets shopped for, credited to the entry.
              _addIngredients(
                aggregated,
                ingredients: item.ingredients,
                sourceLabel: item.freeText!,
                recipeId: null,
              );
            } else {
              final key = 'freeText|${item.id}';
              aggregated[key] = GroceryItemEntity(
                id: key,
                name: item.freeText!,
                unit: MeasurementUnit.unspecified,
                sources: [
                  GroceryItemSourceEntity(
                    recipeId: null,
                    label: meal.name,
                    amount: 1,
                  ),
                ],
                category: 'כללי',
                isAdHoc: true,
              );
            }
          }
        }
      }
    }

    return aggregated.values.toList();
  }

  /// The lines for one recipe made [scale] times over, read from the local
  /// recipes. Null when the recipe is no longer there — the caller keeps
  /// whatever the list already holds rather than emptying it.
  Future<List<GroceryItemEntity>?> forRecipe(
    String recipeId, {
    double scale = 1,
  }) async {
    final recipe = await recipesRepository.getRecipeById(recipeId);
    if (recipe == null) return null;
    return groceryItemsForRecipe(recipe, scale: scale);
  }

  /// Folds a set of ingredients into [aggregated], summing anything that
  /// matches an existing line by normalized name + unit.
  void _addIngredients(
    Map<String, GroceryItemEntity> aggregated, {
    required List<RecipeIngredientEntity> ingredients,
    required String sourceLabel,
    required String? recipeId,
  }) => addIngredientLines(
    aggregated,
    ingredients: ingredients,
    sourceLabel: sourceLabel,
    recipeId: recipeId,
  );
}

/// The shopping lines for [recipe] made [scale] times over: one line per
/// ingredient, two ingredients of the same name and unit summed. Pure, so a
/// recipe that is not on this device — a community post opened read-only —
/// can still become a list.
List<GroceryItemEntity> groceryItemsForRecipe(
  RecipeEntity recipe, {
  double scale = 1,
}) {
  final aggregated = <String, GroceryItemEntity>{};
  addIngredientLines(
    aggregated,
    ingredients: recipe.ingredients,
    sourceLabel: recipe.title,
    recipeId: recipe.id,
    scale: scale,
  );
  return aggregated.values.toList();
}

/// Folds [ingredients] into [aggregated], summing anything that matches an
/// existing line by normalized name + unit. Amounts are multiplied by
/// [scale].
void addIngredientLines(
  Map<String, GroceryItemEntity> aggregated, {
  required List<RecipeIngredientEntity> ingredients,
  required String sourceLabel,
  required String? recipeId,
  double scale = 1,
}) {
  for (final ingredient in ingredients) {
    final key =
        '${ingredient.name.trim().toLowerCase()}|${ingredient.unit.name}';
    final source = GroceryItemSourceEntity(
      recipeId: recipeId,
      label: sourceLabel,
      amount: (ingredient.amount ?? 0) * scale,
    );
    final existing = aggregated[key];
    aggregated[key] = existing == null
        ? GroceryItemEntity(
            id: key,
            name: ingredient.name,
            unit: ingredient.unit,
            sources: [source],
            category: 'כללי',
          )
        : existing.copyWith(sources: [...existing.sources, source]);
  }
}
