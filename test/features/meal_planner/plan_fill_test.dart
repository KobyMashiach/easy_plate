import 'dart:math';

import 'package:easy_plate/core/constants/app_enums.dart';
import 'package:easy_plate/features/meal_planner/domain/entities/meal_entity.dart';
import 'package:easy_plate/features/meal_planner/domain/entities/meal_item_entity.dart';
import 'package:easy_plate/features/meal_planner/domain/entities/meal_plan_entity.dart';
import 'package:easy_plate/features/meal_planner/domain/plan_fill.dart';
import 'package:easy_plate/features/my_recipes/domain/entities/recipe_entity.dart';
import 'package:flutter_test/flutter_test.dart';

RecipeEntity recipe(
  String id, {
  List<DietaryPreference> tags = const [],
  List<Allergen> allergens = const [],
  List<Allergen> mayContain = const [],
  bool pending = false,
}) => RecipeEntity(
  id: id,
  title: 'R $id',
  ingredients: const [],
  steps: const [],
  createdAt: DateTime(2026),
  dietaryTags: tags,
  allergens: allergens,
  mayContain: mayContain,
  pendingAnalysis: pending,
);

MealEntity meal(
  String id,
  int day,
  String name,
  int order, [
  List<MealItemEntity> items = const [],
]) => MealEntity(id: id, weekday: day, name: name, order: order, items: items);

MealPlanEntity planOf(
  List<MealEntity> meals, {
  String id = 'p',
  DateTime? created,
}) => MealPlanEntity(
  id: id,
  name: id,
  meals: meals,
  createdAt: created ?? DateTime(2026, 1, 10),
);

/// Three meals a day, all empty.
MealPlanEntity threeMeals({String id = 'p', DateTime? created}) => planOf(
  [
    for (var d = 0; d < 7; d++) ...[
      meal('$id-$d-b', d, 'Breakfast', 0),
      meal('$id-$d-l', d, 'Lunch', 1),
      meal('$id-$d-d', d, 'Dinner', 2),
    ],
  ],
  id: id,
  created: created,
);

void main() {
  var n = 0;
  String newId() => 'new${n++}';
  setUp(() => n = 0);

  group('WeekAutofill.suits', () {
    test('untagged recipes are left in', () {
      expect(
        WeekAutofill.suits(
          recipe('a'),
          diet: const [DietaryPreference.vegan],
          allergens: const [Allergen.peanuts],
        ),
        isTrue,
      );
    });

    test('a vegetarian does not get a meat recipe', () {
      expect(
        WeekAutofill.suits(
          recipe('a', tags: const [DietaryPreference.meat]),
          diet: const [DietaryPreference.vegetarian],
        ),
        isFalse,
      );
    });

    test('a vegan does not get dairy or egg recipes', () {
      const vegan = [DietaryPreference.vegan];
      expect(
        WeekAutofill.suits(
          recipe('a', tags: const [DietaryPreference.dairy]),
          diet: vegan,
        ),
        isFalse,
      );
      expect(
        WeekAutofill.suits(
          recipe('b', allergens: const [Allergen.eggs]),
          diet: vegan,
        ),
        isFalse,
      );
      expect(
        WeekAutofill.suits(
          recipe('c', tags: const [DietaryPreference.vegan]),
          diet: vegan,
        ),
        isTrue,
      );
    });

    test('gluten free skips recipes containing gluten', () {
      expect(
        WeekAutofill.suits(
          recipe('a', allergens: const [Allergen.gluten]),
          diet: const [DietaryPreference.glutenFree],
        ),
        isFalse,
      );
    });

    test('allergens count traces too', () {
      expect(
        WeekAutofill.suits(
          recipe('a', mayContain: const [Allergen.treeNuts]),
          allergens: const [Allergen.treeNuts],
        ),
        isFalse,
      );
      expect(
        WeekAutofill.suits(
          recipe('b', allergens: const [Allergen.sesame]),
          allergens: const [Allergen.treeNuts],
        ),
        isTrue,
      );
    });
  });

  group('WeekAutofill.plan', () {
    test('fills every empty slot with no repeats when there are enough', () {
      final plan = threeMeals();
      final recipes = [for (var i = 0; i < 30; i++) recipe('r$i')];
      final fill = WeekAutofill.plan(
        plan,
        recipes,
        newId: newId,
        random: Random(1),
      );
      expect(fill.filled, 21);
      expect(fill.emptySlots, 21);
      final ids = [
        for (final items in fill.items.values) items.single.recipeId,
      ];
      expect(ids.toSet().length, 21);
    });

    test('leaves filled slots alone and does not reuse what the week has', () {
      final plan = planOf([
        meal('a', 0, 'Lunch', 0, [
          const MealItemEntity(id: 'i', recipeId: 'r1'),
        ]),
        meal('b', 1, 'Lunch', 0),
        meal('c', 2, 'Lunch', 0),
      ]);
      final fill = WeekAutofill.plan(
        plan,
        [recipe('r1'), recipe('r2'), recipe('r3')],
        newId: newId,
        random: Random(2),
      );
      expect(fill.items.keys, unorderedEquals(['b', 'c']));
      expect(
        fill.items.values.map((l) => l.single.recipeId),
        unorderedEquals(['r2', 'r3']),
      );
    });

    test('fewer recipes than slots fills what it can', () {
      final fill = WeekAutofill.plan(
        threeMeals(),
        [recipe('r1'), recipe('r2')],
        newId: newId,
      );
      expect(fill.filled, 2);
      expect(fill.emptySlots, 21);
    });

    test('skips pending templates and recipes the diet rules out', () {
      final fill = WeekAutofill.plan(
        planOf([meal('a', 0, 'Lunch', 0), meal('b', 1, 'Lunch', 0)]),
        [
          recipe('meat', tags: const [DietaryPreference.meat]),
          recipe('raw', pending: true),
          recipe('ok'),
        ],
        newId: newId,
        diet: const [DietaryPreference.vegetarian],
      );
      expect(fill.filled, 1);
      expect(fill.items.values.single.single.recipeId, 'ok');
    });

    test('prefers recipes used least in other plans', () {
      final fill = WeekAutofill.plan(
        planOf([meal('a', 0, 'Lunch', 0)]),
        [recipe('often'), recipe('fresh')],
        newId: newId,
        usage: const {'often': 3},
        random: Random(3),
      );
      expect(fill.items['a']!.single.recipeId, 'fresh');
    });

    test('nothing to fill in a plan with no meals', () {
      final fill = WeekAutofill.plan(planOf(const []), [
        recipe('a'),
      ], newId: newId);
      expect(fill.isEmpty, isTrue);
      expect(fill.emptySlots, 0);
    });
  });

  group('PlanFill apply / undo', () {
    test('apply skips a slot filled meanwhile, undo removes only ours', () {
      final screen = planOf([
        meal('a', 0, 'Lunch', 0),
        meal('b', 1, 'Lunch', 0),
      ]);
      final fill = WeekAutofill.plan(
        screen,
        [recipe('r1'), recipe('r2')],
        newId: newId,
        random: Random(4),
      );
      // Someone else filled meal b before the write landed.
      final stored = planOf([
        meal('a', 0, 'Lunch', 0),
        meal('b', 1, 'Lunch', 0, [
          const MealItemEntity(id: 'theirs', freeText: 'Soup'),
        ]),
      ]);
      final applied = fill.apply(stored);
      expect(applied.meals.firstWhere((m) => m.id == 'a').items, hasLength(1));
      expect(
        applied.meals.firstWhere((m) => m.id == 'b').items.single.id,
        'theirs',
      );
      // And they add a second dish to a after the fill.
      final later = applied.copyWith(
        meals: [
          for (final m in applied.meals)
            m.id == 'a'
                ? m.copyWith(
                    items: [
                      ...m.items,
                      const MealItemEntity(id: 'extra', freeText: 'Salad'),
                    ],
                  )
                : m,
        ],
      );
      final undone = fill.undo(later);
      expect(
        undone.meals.firstWhere((m) => m.id == 'a').items.single.id,
        'extra',
      );
      expect(
        undone.meals.firstWhere((m) => m.id == 'b').items.single.id,
        'theirs',
      );
    });
  });

  group('WeekCopy', () {
    test('previous picks the newest plan made before the target', () {
      final filled = [
        meal('x', 0, 'Lunch', 0, [
          const MealItemEntity(id: 'i', freeText: 'a'),
        ]),
      ];
      final old = planOf(filled, id: 'old', created: DateTime(2026, 1, 1));
      final last = planOf(filled, id: 'last', created: DateTime(2026, 1, 5));
      final newer = planOf(filled, id: 'newer', created: DateTime(2026, 1, 20));
      final target = threeMeals(id: 't', created: DateTime(2026, 1, 10));
      expect(WeekCopy.previous(target, [old, last, newer, target])?.id, 'last');
      expect(WeekCopy.previous(target, [newer, target])?.id, 'newer');
      expect(WeekCopy.previous(target, [target]), isNull);
    });

    test('copies by meal name into empty slots, keeps filled ones', () {
      final source = planOf([
        meal('s0b', 0, 'Breakfast', 0, [
          const MealItemEntity(id: 'x1', recipeId: 'eggs'),
        ]),
        meal('s0d', 0, 'Dinner', 1, [
          const MealItemEntity(id: 'x2', freeText: 'Pasta'),
        ]),
      ], id: 's');
      final target = planOf([
        meal('t0d', 0, 'dinner', 0),
        meal('t0b', 0, 'Breakfast', 1, [
          const MealItemEntity(id: 'mine', freeText: 'Toast'),
        ]),
      ], id: 't');
      final fill = WeekCopy.plan(target, source, newId: newId);
      expect(fill.items.keys, ['t0d']);
      expect(fill.items['t0d']!.single.freeText, 'Pasta');
      expect(fill.items['t0d']!.single.id, isNot('x2'));
      final applied = fill.apply(target);
      expect(
        applied.meals.firstWhere((m) => m.id == 't0b').items.single.id,
        'mine',
      );
    });

    test('falls back to the meal in the same place when names differ', () {
      final source = planOf([
        meal('s', 2, 'ארוחת צהריים', 0, [
          const MealItemEntity(id: 'x', recipeId: 'r'),
        ]),
      ], id: 's');
      final target = planOf([meal('t', 2, 'Lunch', 0)], id: 't');
      final fill = WeekCopy.plan(target, source, newId: newId);
      expect(fill.items['t']!.single.recipeId, 'r');
    });

    test(
      'a day with no meals takes the source meals whole; undo removes them',
      () {
        final source = planOf([
          meal('s', 3, 'Dinner', 0, [
            const MealItemEntity(id: 'x', recipeId: 'r'),
          ]),
          meal('e', 3, 'Snack', 1),
        ], id: 's');
        final target = planOf(const [], id: 't');
        final fill = WeekCopy.plan(target, source, newId: newId);
        expect(fill.newMeals, hasLength(1));
        expect(fill.newMeals.single.name, 'Dinner');
        final applied = fill.apply(target);
        expect(applied.mealsForWeekday(3).single.items.single.recipeId, 'r');
        expect(fill.undo(applied).meals, isEmpty);
      },
    );
  });

  group('PlanRestore', () {
    test('meal and item come back once, in place', () {
      final m = meal('a', 0, 'Lunch', 0, [
        const MealItemEntity(id: 'i1', freeText: 'x'),
        const MealItemEntity(id: 'i2', freeText: 'y'),
      ]);
      final without = planOf(const []);
      expect(PlanRestore.meal(without, m).meals.single.id, 'a');
      expect(PlanRestore.meal(planOf([m]), m).meals, hasLength(1));

      final removed = planOf([
        meal('a', 0, 'Lunch', 0, [
          const MealItemEntity(id: 'i2', freeText: 'y'),
        ]),
      ]);
      final back = PlanRestore.item(
        removed,
        'a',
        const MealItemEntity(id: 'i1', freeText: 'x'),
        0,
      );
      expect(back.meals.single.items.map((i) => i.id), ['i1', 'i2']);
      expect(
        PlanRestore.item(
          back,
          'a',
          const MealItemEntity(id: 'i1'),
          0,
        ).meals.single.items,
        hasLength(2),
      );
    });

    test('clear a day and undo it, keeping dishes added meanwhile', () {
      final plan = planOf([
        meal('a', 1, 'Lunch', 0, [
          const MealItemEntity(id: 'i1', freeText: 'x'),
        ]),
        meal('b', 1, 'Dinner', 1, [
          const MealItemEntity(id: 'i2', freeText: 'y'),
        ]),
        meal('c', 2, 'Dinner', 0, [
          const MealItemEntity(id: 'i3', freeText: 'z'),
        ]),
      ]);
      final before = plan.mealsForWeekday(1);
      final cleared = PlanRestore.clearDay(plan, 1);
      expect(cleared.mealsForWeekday(1).every((m) => m.items.isEmpty), isTrue);
      expect(cleared.mealsForWeekday(2).single.items, hasLength(1));
      final meanwhile = cleared.copyWith(
        meals: [
          for (final m in cleared.meals)
            m.id == 'b'
                ? m.copyWith(
                    items: const [MealItemEntity(id: 'new', freeText: 'n')],
                  )
                : m,
        ],
      );
      final undone = PlanRestore.meals(meanwhile, before);
      expect(undone.meals.firstWhere((m) => m.id == 'a').items.single.id, 'i1');
      expect(
        undone.meals.firstWhere((m) => m.id == 'b').items.single.id,
        'new',
      );
    });
  });
}
