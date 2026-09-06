import 'package:easy_plate/core/constants/app_enums.dart';
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
  noSuchMethod(Invocation invocation) => throw UnimplementedError();

  @override
  Future<RecipeEntity?> getRecipeById(String id) async => recipes[id];

  @override
  Future<List<RecipeEntity>> getRecipes() async => recipes.values.toList();

  @override
  Future<void> deleteRecipe(String id) async {}

  @override
  Future<void> saveRecipe(RecipeEntity recipe) async {}
}

RecipeEntity _recipe(String id, String title, List<RecipeIngredientEntity> ingredients) {
  return RecipeEntity(
    id: id,
    title: title,
    ingredients: ingredients,
    steps: const [],
    createdAt: DateTime(2026),
  );
}

MealPlanEntity _planWith(List<MealItemEntity> items) {
  return MealPlanEntity(
    id: 'plan',
    name: 'שבוע רגיל',
    meals: [MealEntity(id: 'meal', weekday: 0, name: 'ערב', order: 0, items: items)],
    createdAt: DateTime(2026),
  );
}

void main() {
  test('sums identical ingredients across recipes and keeps each source', () async {
    final repository = _FakeRecipesRepository({
      'a': _recipe('a', 'מתכון א', const [
        RecipeIngredientEntity(name: 'קמח', amount: 200, unit: MeasurementUnit.gram),
      ]),
      'b': _recipe('b', 'מתכון ב', const [
        RecipeIngredientEntity(name: 'קמח', amount: 300, unit: MeasurementUnit.gram),
      ]),
    });

    final items = await BuildAggregateGroceryListUseCase(repository)([
      _planWith(const [
        MealItemEntity(id: '1', recipeId: 'a'),
        MealItemEntity(id: '2', recipeId: 'b'),
      ]),
    ]);

    expect(items, hasLength(1));
    expect(items.single.totalAmount, 500);
    expect(items.single.sources.map((s) => s.label), ['מתכון א', 'מתכון ב']);
    expect(items.single.sources.map((s) => s.amount), [200, 300]);
  });

  test('keeps the same ingredient separate when the unit differs', () async {
    final repository = _FakeRecipesRepository({
      'a': _recipe('a', 'מתכון א', const [
        RecipeIngredientEntity(name: 'חלב', amount: 1, unit: MeasurementUnit.liter),
      ]),
      'b': _recipe('b', 'מתכון ב', const [
        RecipeIngredientEntity(name: 'חלב', amount: 250, unit: MeasurementUnit.milliliter),
      ]),
    });

    final items = await BuildAggregateGroceryListUseCase(repository)([
      _planWith(const [
        MealItemEntity(id: '1', recipeId: 'a'),
        MealItemEntity(id: '2', recipeId: 'b'),
      ]),
    ]);

    expect(items, hasLength(2));
  });

  test('treats a missing amount as zero without dropping the ingredient', () async {
    final repository = _FakeRecipesRepository({
      'a': _recipe('a', 'מתכון א', const [
        RecipeIngredientEntity(name: 'מלח', amount: null),
      ]),
    });

    final items = await BuildAggregateGroceryListUseCase(repository)([
      _planWith(const [MealItemEntity(id: '1', recipeId: 'a')]),
    ]);

    expect(items.single.name, 'מלח');
    expect(items.single.totalAmount, 0);
  });

  test('free-text meal items become ad-hoc lines', () async {
    final items = await BuildAggregateGroceryListUseCase(_FakeRecipesRepository({}))([
      _planWith(const [MealItemEntity(id: '1', freeText: 'טוסט וביצים')]),
    ]);

    expect(items.single.name, 'טוסט וביצים');
    expect(items.single.isAdHoc, isTrue);
  });

  test('a free-text item with products shops for the products, not the item', () async {
    final items = await BuildAggregateGroceryListUseCase(_FakeRecipesRepository({}))([
      _planWith(const [
        MealItemEntity(
          id: '1',
          freeText: 'חביתה',
          ingredients: [
            RecipeIngredientEntity(name: 'ביצים', amount: 2, unit: MeasurementUnit.unit),
            RecipeIngredientEntity(name: 'חלב', amount: 50, unit: MeasurementUnit.milliliter),
          ],
        ),
      ]),
    ]);

    expect(items.map((i) => i.name), ['ביצים', 'חלב']);
    // The entry itself is not shopped for — only what it is made of.
    expect(items.any((i) => i.name == 'חביתה'), isFalse);
    // Each line is credited to the entry that asked for it.
    expect(items.first.sources.single.label, 'חביתה');
  });

  test('quick-entry products merge with matching recipe ingredients', () async {
    final repository = _FakeRecipesRepository({
      'a': _recipe('a', 'שקשוקה', const [
        RecipeIngredientEntity(name: 'ביצים', amount: 4, unit: MeasurementUnit.unit),
      ]),
    });

    final items = await BuildAggregateGroceryListUseCase(repository)([
      _planWith(const [
        MealItemEntity(id: '1', recipeId: 'a'),
        MealItemEntity(
          id: '2',
          freeText: 'חביתה',
          ingredients: [
            RecipeIngredientEntity(name: 'ביצים', amount: 2, unit: MeasurementUnit.unit),
          ],
        ),
      ]),
    ]);

    expect(items, hasLength(1));
    expect(items.single.totalAmount, 6);
    expect(items.single.sources.map((s) => s.label), ['שקשוקה', 'חביתה']);
  });
}
