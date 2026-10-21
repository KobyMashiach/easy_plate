import 'package:easy_plate/core/constants/app_enums.dart';
import 'package:easy_plate/core/utils/i18n/strings.g.dart';
import 'package:easy_plate/features/meal_planner/domain/entities/meal_entity.dart';
import 'package:easy_plate/features/meal_planner/domain/entities/meal_plan_entity.dart';
import 'package:easy_plate/features/meal_planner/domain/repositories/meal_plans_repository.dart';
import 'package:easy_plate/features/meal_planner/domain/usecases/delete_meal_plan_usecase.dart';
import 'package:easy_plate/features/meal_planner/domain/usecases/get_meal_plans_usecase.dart';
import 'package:easy_plate/features/meal_planner/domain/usecases/save_meal_plan_usecase.dart';
import 'package:easy_plate/features/meal_planner/presentation/bloc/meal_planner_bloc.dart';
import 'package:easy_plate/features/my_recipes/domain/entities/recipe_entity.dart';
import 'package:easy_plate/features/my_recipes/domain/repositories/recipes_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _Plans implements MealPlansRepository {
  final store = <String, MealPlanEntity>{};

  @override
  Future<List<MealPlanEntity>> getPlans() async => store.values.toList();

  @override
  Stream<List<MealPlanEntity>> watchPlans() => const Stream.empty();

  @override
  Future<MealPlanEntity?> getPlanById(String id) async => store[id];

  Duration delay = Duration.zero;

  @override
  Future<void> savePlan(
    MealPlanEntity plan, {
    bool stampLanguage = true,
  }) async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    store[plan.id] = plan;
  }

  @override
  Future<void> deletePlan(String id) async => store.remove(id);
}

class _Recipes implements RecipesRepository {
  final recipes = <RecipeEntity>[];
  int reads = 0;

  @override
  Future<List<RecipeEntity>> getRecipes() async {
    reads++;
    return recipes;
  }

  @override
  noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  setUpAll(() => LocaleSettings.setLocale(AppLocale.en));

  late _Plans plans;
  late _Recipes recipes;

  MealPlannerBloc build() => MealPlannerBloc(
    getMealPlansUseCase: GetMealPlansUseCase(plans),
    saveMealPlanUseCase: SaveMealPlanUseCase(plans),
    deleteMealPlanUseCase: DeleteMealPlanUseCase(plans),
    recipesRepository: recipes,
  );

  /// The next loaded state the bloc emits.
  Future<MealPlannerLoaded> loaded(MealPlannerBloc bloc) async =>
      await bloc.stream.firstWhere((s) => s is MealPlannerLoaded)
          as MealPlannerLoaded;

  setUp(() {
    plans = _Plans()
      ..store['p'] = MealPlanEntity(
        id: 'p',
        name: 'Week',
        meals: const [],
        createdAt: DateTime(2026),
      );
    recipes = _Recipes()
      ..recipes.add(
        RecipeEntity(
          id: 'r1',
          title: 'Shakshuka',
          ingredients: const [],
          steps: const [],
          createdAt: DateTime(2026),
        ),
      );
  });

  test('opening reads the recipes once for the titles', () async {
    final bloc = build();
    final state = await loaded(bloc);
    expect(state.selectedPlan?.id, 'p');
    expect(state.recipeTitles, {'r1': 'Shakshuka'});
    expect(recipes.reads, 1);
    await bloc.close();
  });

  test('an edit to the plan reuses the loaded recipes', () async {
    final bloc = build();
    await loaded(bloc);

    bloc.add(const MealPlannerEvent.addMeal(2, 'Lunch'));
    var state = await loaded(bloc);
    expect(state.selectedPlan!.mealsForWeekday(2).single.name, 'Lunch');
    // Shown first, written after (onto the stored plan, behind the queue).
    await pumpEventQueue();
    expect(plans.store['p']!.meals, hasLength(1), reason: 'persisted');

    final mealId = state.selectedPlan!.meals.single.id;
    bloc.add(MealPlannerEvent.addRecipeItem(mealId, 'r1'));
    state = await loaded(bloc);
    expect(state.selectedPlan!.meals.single.items.single.recipeId, 'r1');

    bloc.add(MealPlannerEvent.removeMeal(mealId));
    state = await loaded(bloc);
    expect(state.selectedPlan!.meals, isEmpty);

    // Three edits, no second read: the titles and nutrition map on screen
    // are the ones the edit started from.
    expect(recipes.reads, 1);
    expect(state.recipeTitles, {'r1': 'Shakshuka'});
    expect(state.recipes.keys, ['r1']);
    await bloc.close();
  });

  test('switching plans reads the recipes again', () async {
    plans.store['q'] = MealPlanEntity(
      id: 'q',
      name: 'Other',
      meals: [
        const MealEntity(
          id: 'm',
          weekday: 0,
          name: 'Dinner',
          order: 0,
          items: [],
        ),
      ],
      createdAt: DateTime(2026, 2),
    );
    final bloc = build();
    await loaded(bloc);
    bloc.add(const MealPlannerEvent.selectPlan('q'));
    final state = await loaded(bloc);
    expect(state.selectedPlan?.id, 'q');
    expect(recipes.reads, 2);
    await bloc.close();
  });

  test('a template plan seeds every weekday', () async {
    final bloc = build();
    await loaded(bloc);
    bloc.add(
      const MealPlannerEvent.createPlan('Six', MealPlanTemplate.sixMeals),
    );
    final state = await loaded(bloc);
    expect(state.selectedPlan?.name, 'Six');
    expect(state.selectedPlan!.meals, hasLength(6 * ShoppingDay.values.length));
    await bloc.close();
  });

  test('two quick edits both survive a slow save', () async {
    plans.store['p'] = MealPlanEntity(
      id: 'p',
      name: 'Week',
      meals: const [
        MealEntity(id: 'a', weekday: 0, name: 'Lunch', order: 0, items: []),
        MealEntity(id: 'b', weekday: 0, name: 'Dinner', order: 1, items: []),
      ],
      createdAt: DateTime(2026),
    );
    final bloc = build();
    await loaded(bloc);
    plans.delay = const Duration(milliseconds: 30);
    bloc
      ..add(const MealPlannerEvent.removeMeal('a'))
      ..add(const MealPlannerEvent.removeMeal('b'));
    await Future<void>.delayed(const Duration(milliseconds: 150));
    expect(plans.store['p']!.meals, isEmpty);
    expect((bloc.state as MealPlannerLoaded).selectedPlan!.meals, isEmpty);
    await bloc.close();
  });

  test('pass 7: an edit keeps a meal the website added meanwhile', () async {
    final bloc = build();
    await loaded(bloc);
    // Written by the website after the board read the plan.
    plans.store['p'] = MealPlanEntity(
      id: 'p',
      name: 'Week',
      meals: const [
        MealEntity(id: 'web', weekday: 1, name: 'Brunch', order: 0, items: []),
      ],
      createdAt: DateTime(2026),
    );

    bloc.add(const MealPlannerEvent.addMeal(2, 'Lunch'));
    await Future<void>.delayed(const Duration(milliseconds: 20));

    final stored = plans.store['p']!;
    expect(stored.meals.map((m) => m.name), ['Brunch', 'Lunch']);
    // The board shows what was written, with the same id it showed first.
    final shown = (bloc.state as MealPlannerLoaded).selectedPlan!;
    expect(shown.meals.map((m) => m.id), stored.meals.map((m) => m.id));
    await bloc.close();
  });

  test(
    'pass 7: an edit to a plan deleted elsewhere does not revive it',
    () async {
      final bloc = build();
      await loaded(bloc);
      plans.store.remove('p');

      bloc.add(const MealPlannerEvent.addMeal(2, 'Lunch'));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(plans.store.containsKey('p'), isFalse);
      await bloc.close();
    },
  );

  test(
    'pass 9: a queued edit does not flicker back on an earlier reload',
    () async {
      plans.store['p'] = MealPlanEntity(
        id: 'p',
        name: 'Week',
        meals: const [
          MealEntity(id: 'a', weekday: 0, name: 'Lunch', order: 0, items: []),
          MealEntity(id: 'b', weekday: 0, name: 'Dinner', order: 1, items: []),
        ],
        createdAt: DateTime(2026),
      );
      final bloc = build();
      await loaded(bloc);
      final shown = <List<String>>[];
      final sub = bloc.stream.listen((s) {
        if (s is MealPlannerLoaded) {
          shown.add([for (final m in s.selectedPlan!.meals) m.id]);
        }
      });
      plans.delay = const Duration(milliseconds: 30);
      bloc
        ..add(const MealPlannerEvent.removeMeal('a'))
        ..add(const MealPlannerEvent.removeMeal('b'));
      await Future<void>.delayed(const Duration(milliseconds: 150));
      await sub.cancel();
      final goneAt = shown.indexWhere((ids) => !ids.contains('b'));
      expect(goneAt, isNot(-1));
      for (final ids in shown.skip(goneAt)) {
        expect(ids, isNot(contains('b')));
      }
      await bloc.close();
    },
  );
}
