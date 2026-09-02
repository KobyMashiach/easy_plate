import '../../../../core/constants/app_enums.dart';
import '../../../meal_planner/domain/entities/meal_plan_entity.dart';
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
            final recipe = await recipesRepository.getRecipeById(item.recipeId!);
            if (recipe == null) continue;

            for (final ingredient in recipe.ingredients) {
              final key = '${ingredient.name.trim().toLowerCase()}|${ingredient.unit.name}';
              final source = GroceryItemSourceEntity(
                recipeId: recipe.id,
                label: recipe.title,
                amount: ingredient.amount ?? 0,
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
          } else if (item.freeText != null && item.freeText!.trim().isNotEmpty) {
            final key = 'freeText|${item.id}';
            aggregated[key] = GroceryItemEntity(
              id: key,
              name: item.freeText!,
              unit: MeasurementUnit.unspecified,
              sources: [GroceryItemSourceEntity(recipeId: null, label: meal.name, amount: 1)],
              category: 'כללי',
              isAdHoc: true,
            );
          }
        }
      }
    }

    return aggregated.values.toList();
  }
}
