import 'package:easy_plate/features/meal_planner/domain/entities/meal_entity.dart';
import 'package:easy_plate/features/meal_planner/domain/entities/meal_item_entity.dart';
import 'package:easy_plate/features/meal_planner/domain/entities/meal_plan_entity.dart';
import 'package:easy_plate/features/meal_planner/domain/nutrition_summary.dart';
import 'package:easy_plate/features/my_recipes/domain/entities/nutrition_entity.dart';
import 'package:easy_plate/features/my_recipes/domain/entities/recipe_entity.dart';
import 'package:flutter_test/flutter_test.dart';

RecipeEntity _recipe(String id, NutritionEntity? nutrition) => RecipeEntity(
      id: id,
      title: id,
      ingredients: const [],
      steps: const [],
      createdAt: DateTime(2026),
      nutrition: nutrition,
    );

MealItemEntity _item(String id, {String? recipeId, String? text}) =>
    MealItemEntity(id: id, recipeId: recipeId, freeText: text, ingredients: const []);

void main() {
  const oats = NutritionEntity(calories: 300, proteinGrams: 10, carbsGrams: 50, fatGrams: 6);
  const chicken = NutritionEntity(calories: 500, proteinGrams: 40, carbsGrams: 20, fatGrams: 25);
  final recipes = {
    'oats': _recipe('oats', oats),
    'chicken': _recipe('chicken', chicken),
    'mystery': _recipe('mystery', null),
  };

  MealPlanEntity plan(List<MealEntity> meals) =>
      MealPlanEntity(id: 'p', name: 'p', meals: meals, createdAt: DateTime(2026));

  test('a day adds one serving per recipe item and counts what it cannot add', () {
    final p = plan([
      MealEntity(id: 'b', weekday: 0, name: 'Breakfast', order: 0, items: [
        _item('1', recipeId: 'oats'),
        _item('2', text: 'coffee'),
      ]),
      MealEntity(id: 'd', weekday: 0, name: 'Dinner', order: 1, items: [
        _item('3', recipeId: 'chicken'),
        _item('4', recipeId: 'chicken'),
        _item('5', recipeId: 'mystery'),
      ]),
    ]);
    final day = PlanNutrition.of(p, recipes).day(0);
    expect(day.total.calories, 300 + 500 + 500);
    expect(day.total.proteinGrams, 10 + 40 + 40);
    expect(day.countedItems, 3);
    expect(day.missingItems, 2, reason: 'free text and an unestimated recipe');
    expect(day.meals.map((m) => m.total.calories), [300, 1000]);
  });

  test('the week averages over planned days only', () {
    final p = plan([
      MealEntity(id: 'a', weekday: 0, name: 'L', order: 0, items: [_item('1', recipeId: 'oats')]),
      MealEntity(id: 'b', weekday: 3, name: 'L', order: 0, items: [_item('2', recipeId: 'chicken')]),
      MealEntity(id: 'c', weekday: 5, name: 'L', order: 0, items: [_item('3', text: 'salad')]),
    ]);
    final week = PlanNutrition.of(p, recipes);
    expect(week.weekTotal.calories, 800);
    expect(week.plannedDays, 2, reason: 'a day of free text alone is not planned nutrition');
    expect(week.dailyAverage.calories, 400);
    expect(week.peakCalories, 500);
    expect(week.missingItems, 1);
  });

  test('an empty plan has no data and a safe peak', () {
    final week = PlanNutrition.of(plan(const []), recipes);
    expect(week.hasData, isFalse);
    expect(week.dailyAverage, NutritionEntity.zero);
    expect(week.peakCalories, 1);
  });

  test('macro shares split calories 4/4/9', () {
    const n = NutritionEntity(calories: 0, proteinGrams: 10, carbsGrams: 10, fatGrams: 10);
    final shares = n.macroShares;
    expect(shares.protein, closeTo(40 / 170, 1e-9));
    expect(shares.fat, closeTo(90 / 170, 1e-9));
    expect(NutritionEntity.zero.macroShares.carbs, 0);
  });
}
