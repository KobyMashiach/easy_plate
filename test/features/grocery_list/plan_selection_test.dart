import 'package:easy_plate/core/constants/app_enums.dart';
import 'package:easy_plate/features/grocery_list/domain/entities/grocery_list_entity.dart';
import 'package:easy_plate/features/grocery_list/domain/usecases/build_aggregate_grocery_list_usecase.dart';
import 'package:easy_plate/features/meal_planner/domain/entities/meal_entity.dart';
import 'package:easy_plate/features/meal_planner/domain/entities/meal_item_entity.dart';
import 'package:easy_plate/features/meal_planner/domain/entities/meal_plan_entity.dart';
import 'package:easy_plate/features/my_recipes/domain/entities/recipe_entity.dart';
import 'package:easy_plate/features/my_recipes/domain/entities/recipe_ingredient_entity.dart';
import 'package:easy_plate/features/my_recipes/domain/repositories/recipes_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRecipesRepository implements RecipesRepository {
  final Map<String, RecipeEntity> recipes;
  _FakeRecipesRepository(this.recipes);

  @override
  Future<RecipeEntity?> getRecipeById(String id) async => recipes[id];

  @override
  noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

RecipeEntity buildRecipe(String id, String title, String ingredient) => RecipeEntity(
      id: id,
      title: title,
      ingredients: [
        RecipeIngredientEntity(name: ingredient, amount: 100, unit: MeasurementUnit.gram),
      ],
      steps: const [],
      createdAt: DateTime(2026, 1, 1),
    );

MealPlanEntity buildPlan(String id, String name, String recipeId) => MealPlanEntity(
      id: id,
      name: name,
      meals: [
        MealEntity(
          id: 'm-$id',
          name: 'ארוחה',
          weekday: 1,
          order: 0,
          items: [MealItemEntity(id: 'i-$id', recipeId: recipeId)],
        ),
      ],
      createdAt: DateTime(2026, 1, 1),
    );

/// Mirrors the bloc's selection rule so the filtering contract is pinned
/// without standing a Hive-backed bloc up.
List<MealPlanEntity> applySelection(GroceryListEntity list, List<MealPlanEntity> plans) {
  if (list.includesAllPlans) return plans;
  return plans.where((p) => list.selectedPlanIds.contains(p.id)).toList();
}

GroceryListEntity buildList({List<String> selected = const []}) => GroceryListEntity(
      id: 'primary',
      name: 'רשימה',
      items: const [],
      selectedPlanIds: selected,
      createdAt: DateTime(2026, 1, 1),
    );

void main() {
  final recipes = _FakeRecipesRepository({
    'r1': buildRecipe('r1', 'שקשוקה', 'עגבניות'),
    'r2': buildRecipe('r2', 'סלט', 'מלפפון'),
  });
  final plans = [buildPlan('p1', 'תפריט א', 'r1'), buildPlan('p2', 'תפריט ב', 'r2')];
  final useCase = BuildAggregateGroceryListUseCase(recipes);

  test('an empty selection means every menu', () async {
    final list = buildList();
    expect(list.includesAllPlans, isTrue);

    final items = await useCase(applySelection(list, plans));
    expect(items.map((i) => i.name), containsAll(['עגבניות', 'מלפפון']));
  });

  test('a narrowed selection aggregates only the chosen menu', () async {
    final list = buildList(selected: ['p1']);
    final items = await useCase(applySelection(list, plans));

    expect(items.map((i) => i.name), ['עגבניות']);
  });

  test('an id whose menu was deleted is simply skipped', () async {
    final list = buildList(selected: ['p1', 'deleted-plan']);
    final items = await useCase(applySelection(list, plans));

    expect(items.map((i) => i.name), ['עגבניות']);
  });

  test('copyWith can widen a narrowed list back to every menu', () {
    final narrowed = buildList(selected: ['p1']);
    expect(narrowed.includesAllPlans, isFalse);

    final widened = narrowed.copyWith(selectedPlanIds: const []);
    expect(widened.includesAllPlans, isTrue);
    expect(applySelection(widened, plans), hasLength(2));
  });
}
