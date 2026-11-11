import 'package:easy_plate/features/meal_planner/domain/entities/meal_entity.dart';
import 'package:easy_plate/features/meal_planner/domain/entities/meal_plan_entity.dart';
import 'package:easy_plate/features/my_recipes/data/datasources/recipes_ui_store.dart';
import 'package:easy_plate/features/my_recipes/domain/entities/recipe_entity.dart';
import 'package:easy_plate/features/my_recipes/presentation/widgets/add_to_plan_sheet.dart';
import 'package:flutter_test/flutter_test.dart';

RecipeEntity recipe(String id) => RecipeEntity(
  id: id,
  title: id,
  ingredients: const [],
  steps: const [],
  createdAt: DateTime(2026),
);

void main() {
  group('cook history', () {
    test('withCook counts and stamps, and trims to the newest', () {
      var history = <String, CookRecord>{};
      history = withCook(history, 'a', DateTime(2026, 1, 1));
      history = withCook(history, 'a', DateTime(2026, 1, 3));
      history = withCook(history, 'b', DateTime(2026, 1, 2));
      expect(history['a']!.count, 2);
      expect(history['a']!.lastAt, DateTime(2026, 1, 3));
      expect(history['b']!.count, 1);

      final trimmed = withCook(history, 'c', DateTime(2026, 1, 4), keep: 2);
      expect(trimmed.keys, unorderedEquals(['a', 'c']));
    });

    test('a record survives its JSON round trip; a broken one is dropped', () {
      final record = CookRecord('a', count: 3, lastAt: DateTime(2026, 5, 1));
      final back = CookRecord.fromJson('a', record.toJson())!;
      expect(back.count, 3);
      expect(back.lastAt, DateTime(2026, 5, 1));
      expect(CookRecord.fromJson('a', {'count': 0, 'lastAt': 1}), isNull);
      expect(CookRecord.fromJson('a', 'junk'), isNull);
    });

    test('recently cooked: newest first, deleted recipes ignored', () {
      final history = {
        'a': CookRecord('a', count: 1, lastAt: DateTime(2026, 1, 1)),
        'b': CookRecord('b', count: 5, lastAt: DateTime(2026, 1, 3)),
        'gone': CookRecord('gone', count: 9, lastAt: DateTime(2026, 1, 9)),
      };
      final recipes = [recipe('a'), recipe('b')];
      expect(recentlyCooked(history, recipes).map((r) => r.id), ['b', 'a']);
      expect(recentlyCooked(history, recipes, limit: 1).map((r) => r.id), [
        'b',
      ]);
    });

    test('most cooked: twice or more, most first, recent breaks a tie', () {
      final history = {
        'once': CookRecord('once', count: 1, lastAt: DateTime(2026, 2, 1)),
        'x': CookRecord('x', count: 3, lastAt: DateTime(2026, 1, 1)),
        'y': CookRecord('y', count: 3, lastAt: DateTime(2026, 1, 5)),
        'z': CookRecord('z', count: 7, lastAt: DateTime(2025, 1, 1)),
      };
      final recipes = [recipe('once'), recipe('x'), recipe('y'), recipe('z')];
      expect(mostCooked(history, recipes).map((r) => r.id), ['z', 'y', 'x']);
      expect(mostCooked(const {}, recipes), isEmpty);
    });
  });

  group('planWithRecipe', () {
    var n = 0;
    String newId() => 'id${n++}';
    final plan = MealPlanEntity(
      id: 'p',
      name: 'Week',
      createdAt: DateTime(2026),
      meals: const [
        MealEntity(id: 'm1', weekday: 2, name: 'Dinner', order: 0, items: []),
      ],
    );

    test('appends to the named meal of that day', () {
      final updated = planWithRecipe(
        plan,
        weekday: 2,
        mealName: 'Dinner',
        recipeId: 'r',
        newId: newId,
      );
      expect(updated.meals, hasLength(1));
      expect(updated.meals.single.items.single.recipeId, 'r');
    });

    test('creates the meal at the end of a day that lacks it', () {
      final updated = planWithRecipe(
        plan,
        weekday: 4,
        mealName: 'Dinner',
        recipeId: 'r',
        newId: newId,
      );
      final thursday = updated.mealsForWeekday(4).single;
      expect(thursday.name, 'Dinner');
      expect(thursday.order, 0);
      expect(thursday.items.single.recipeId, 'r');
      // The other day is untouched.
      expect(updated.mealsForWeekday(2).single.items, isEmpty);
    });
  });
}
