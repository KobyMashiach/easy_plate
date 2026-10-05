import 'dart:async';

import 'package:easy_plate/core/constants/app_enums.dart';
import 'package:easy_plate/features/grocery_list/data/datasources/active_grocery_list_store.dart';
import 'package:easy_plate/features/grocery_list/domain/entities/grocery_item_entity.dart';
import 'package:easy_plate/features/grocery_list/domain/entities/grocery_item_source_entity.dart';
import 'package:easy_plate/features/grocery_list/domain/entities/grocery_list_entity.dart';
import 'package:easy_plate/features/grocery_list/domain/repositories/grocery_lists_repository.dart';
import 'package:easy_plate/features/grocery_list/domain/usecases/build_aggregate_grocery_list_usecase.dart';
import 'package:easy_plate/features/grocery_list/domain/usecases/create_recipe_grocery_list_usecase.dart';
import 'package:easy_plate/features/grocery_list/domain/usecases/delete_grocery_list_usecase.dart';
import 'package:easy_plate/features/grocery_list/domain/usecases/get_grocery_lists_usecase.dart';
import 'package:easy_plate/features/grocery_list/domain/usecases/save_grocery_list_usecase.dart';
import 'package:easy_plate/features/grocery_list/presentation/bloc/grocery_list_bloc.dart';
import 'package:easy_plate/features/meal_planner/domain/entities/meal_plan_entity.dart';
import 'package:easy_plate/features/meal_planner/domain/repositories/meal_plans_repository.dart';
import 'package:easy_plate/features/meal_planner/domain/usecases/get_meal_plans_usecase.dart';
import 'package:easy_plate/features/my_recipes/domain/entities/recipe_entity.dart';
import 'package:easy_plate/features/my_recipes/domain/entities/recipe_ingredient_entity.dart';
import 'package:easy_plate/features/my_recipes/domain/repositories/recipes_repository.dart';
import 'package:easy_plate/core/utils/i18n/strings.g.dart';
import 'package:easy_plate/features/grocery_list/presentation/widgets/grocery_lists_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _Lists implements GroceryListsRepository {
  final stored = <String, GroceryListEntity>{};
  final deleted = <String>[];

  @override
  Future<List<GroceryListEntity>> getLists() async => stored.values.toList();

  @override
  Stream<List<GroceryListEntity>> watchLists() => const Stream.empty();

  @override
  Future<GroceryListEntity?> getListById(String id) async => stored[id];

  @override
  Future<void> saveList(
    GroceryListEntity list, {
    bool stampLanguage = true,
  }) async => stored[list.id] = list;

  @override
  Future<void> deleteList(String id) async {
    stored.remove(id);
    deleted.add(id);
  }
}

class _Recipes implements RecipesRepository {
  final recipes = <String, RecipeEntity>{};

  @override
  Future<RecipeEntity?> getRecipeById(String id) async => recipes[id];

  @override
  noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _Plans implements MealPlansRepository {
  @override
  Future<List<MealPlanEntity>> getPlans() async => const [];

  @override
  noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

RecipeEntity shakshuka({int? servings = 2}) => RecipeEntity(
  id: 'r1',
  title: 'שקשוקה',
  servings: servings,
  ingredients: const [
    RecipeIngredientEntity(
      name: 'עגבניות',
      amount: 100,
      unit: MeasurementUnit.gram,
    ),
    RecipeIngredientEntity(
      name: 'ביצים',
      amount: 4,
      unit: MeasurementUnit.unit,
    ),
  ],
  steps: const [],
  createdAt: DateTime(2026, 1, 1),
);

GroceryListEntity storedList(
  String id, {
  DateTime? createdAt,
  GroceryListSource source = GroceryListSource.plans,
}) => GroceryListEntity(
  id: id,
  name: 'רשימה $id',
  items: const [],
  createdAt: createdAt ?? DateTime(2026, 1, 1),
  source: source,
);

void main() {
  late _Lists lists;
  late _Recipes recipes;
  late InMemoryActiveGroceryListStore active;

  GroceryListBloc build() => GroceryListBloc(
    getGroceryListsUseCase: GetGroceryListsUseCase(lists),
    saveGroceryListUseCase: SaveGroceryListUseCase(lists),
    deleteGroceryListUseCase: DeleteGroceryListUseCase(lists),
    buildAggregateGroceryListUseCase: BuildAggregateGroceryListUseCase(recipes),
    createRecipeGroceryListUseCase: CreateRecipeGroceryListUseCase(
      lists,
      active,
    ),
    getMealPlansUseCase: GetMealPlansUseCase(_Plans()),
    activeListStore: active,
  );

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 10));

  GroceryListLoaded loaded(GroceryListBloc bloc) =>
      bloc.state as GroceryListLoaded;

  setUp(() {
    lists = _Lists();
    recipes = _Recipes();
    active = InMemoryActiveGroceryListStore();
  });

  group('one recipe to lines', () {
    test('scales every amount and credits the recipe', () {
      final items = groceryItemsForRecipe(shakshuka(), scale: 1.5);
      final tomatoes = items.firstWhere((i) => i.name == 'עגבניות');
      expect(tomatoes.totalAmount, 150);
      expect(tomatoes.sources.single.recipeId, 'r1');
      expect(tomatoes.sources.single.label, 'שקשוקה');
      expect(items.firstWhere((i) => i.name == 'ביצים').totalAmount, 6);
    });

    test('the same ingredient twice becomes one line', () {
      final recipe = shakshuka().copyWith(
        ingredients: const [
          RecipeIngredientEntity(
            name: 'מלח',
            amount: 1,
            unit: MeasurementUnit.teaspoon,
          ),
          RecipeIngredientEntity(
            name: 'מלח ',
            amount: 2,
            unit: MeasurementUnit.teaspoon,
          ),
        ],
      );
      final items = groceryItemsForRecipe(recipe);
      expect(items, hasLength(1));
      expect(items.single.totalAmount, 3);
    });
  });

  group('which list opens', () {
    test('an account with no list gets a fresh meal-plan list', () async {
      final bloc = build();
      await settle();

      final state = loaded(bloc);
      expect(state.list.id, GroceryListBloc.defaultListId);
      expect(state.list.source, GroceryListSource.plans);
      expect(state.lists, hasLength(1));
      await bloc.close();
    });

    test('the list last opened on this device wins over the oldest', () async {
      lists.stored['primary'] = storedList('primary');
      lists.stored['b'] = storedList('b', createdAt: DateTime(2026, 2, 1));
      active.value = 'b';
      final bloc = build();
      await settle();

      expect(loaded(bloc).list.id, 'b');
      expect(loaded(bloc).lists.map((l) => l.id), ['primary', 'b']);
      await bloc.close();
    });

    test('a remembered id that no longer exists falls back', () async {
      lists.stored['primary'] = storedList('primary');
      active.value = 'gone';
      final bloc = build();
      await settle();

      expect(loaded(bloc).list.id, 'primary');
      await bloc.close();
    });
  });

  group('the lists sheet', () {
    Future<void> openSheetAndPick(WidgetTester tester, String option) async {
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.groceryList.newList));
      await tester.pumpAndSettle();
      await tester.tap(find.text(option));
      await tester.pumpAndSettle();
    }

    Widget host(GroceryListBloc bloc) => MaterialApp(
      home: BlocProvider.value(
        value: bloc,
        child: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showGroceryListsSheet(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    // The bug this pins: the lists sheet closed itself and ran the rest of
    // the flow from its own, dead context, so a choice added nothing.
    testWidgets('"new list" then a choice really adds the list', (
      tester,
    ) async {
      lists.stored['primary'] = storedList('primary');
      final bloc = build();
      await tester.pumpWidget(host(bloc));
      await tester.pumpAndSettle();

      await openSheetAndPick(tester, t.groceryList.emptyList);

      final state = loaded(bloc);
      expect(state.lists, hasLength(2));
      expect(state.list.source, GroceryListSource.manual);
      expect(state.list.name, t.groceryList.defaultListName);
      // Closed without waiting: inside the widget test's fake clock the
      // bloc's close never resolves on its own, and awaiting it here hung
      // the test after every assertion had already passed.
      unawaited(bloc.close());
      await tester.pump();
    });

    testWidgets('"from menus" adds a plans list', (tester) async {
      lists.stored['primary'] = storedList('primary');
      final bloc = build();
      await tester.pumpWidget(host(bloc));
      await tester.pumpAndSettle();

      await openSheetAndPick(tester, t.groceryList.fromPlans);

      expect(loaded(bloc).lists, hasLength(2));
      expect(loaded(bloc).list.source, GroceryListSource.plans);
      // Closed without waiting: inside the widget test's fake clock the
      // bloc's close never resolves on its own, and awaiting it here hung
      // the test after every assertion had already passed.
      unawaited(bloc.close());
      await tester.pump();
    });
  });

  group('several lists', () {
    test('a new hand-made list opens, and is remembered', () async {
      lists.stored['primary'] = storedList('primary');
      final bloc = build();
      await settle();

      bloc.add(
        const GroceryListEvent.createList('לחג', GroceryListSource.manual),
      );
      await settle();

      final state = loaded(bloc);
      expect(state.list.name, 'לחג');
      expect(state.list.source, GroceryListSource.manual);
      expect(state.lists, hasLength(2));
      expect(active.value, state.list.id);
      await bloc.close();
    });

    test('rebuilding a hand-made list leaves it as it is', () async {
      lists.stored['m'] = GroceryListEntity(
        id: 'm',
        name: 'ידני',
        items: const [
          GroceryItemEntity(
            id: 'x',
            name: 'חלב',
            unit: MeasurementUnit.liter,
            sources: [GroceryItemSourceEntity(label: 'חלב', amount: 1)],
            category: 'כללי',
            isAdHoc: true,
          ),
        ],
        createdAt: DateTime(2026, 1, 1),
        source: GroceryListSource.manual,
      );
      active.value = 'm';
      final bloc = build();
      await settle();

      bloc.add(const GroceryListEvent.regenerate());
      await settle();

      expect(loaded(bloc).list.items.single.name, 'חלב');
      await bloc.close();
    });

    test('switching opens the other list', () async {
      lists.stored['primary'] = storedList('primary');
      lists.stored['b'] = storedList('b', createdAt: DateTime(2026, 2, 1));
      final bloc = build();
      await settle();

      bloc.add(const GroceryListEvent.selectList('b'));
      await settle();

      expect(loaded(bloc).list.id, 'b');
      expect(active.value, 'b');
      await bloc.close();
    });

    test('deleting the open list opens the oldest one left', () async {
      lists.stored['primary'] = storedList('primary');
      lists.stored['b'] = storedList('b', createdAt: DateTime(2026, 2, 1));
      lists.stored['c'] = storedList('c', createdAt: DateTime(2026, 3, 1));
      active.value = 'c';
      final bloc = build();
      await settle();

      bloc.add(const GroceryListEvent.deleteList('c'));
      await settle();

      final state = loaded(bloc);
      expect(lists.deleted, ['c']);
      expect(state.list.id, 'primary');
      expect(state.lists.map((l) => l.id), ['primary', 'b']);
      await bloc.close();
    });

    test('deleting another list keeps the open one', () async {
      lists.stored['primary'] = storedList('primary');
      lists.stored['b'] = storedList('b', createdAt: DateTime(2026, 2, 1));
      final bloc = build();
      await settle();

      bloc.add(const GroceryListEvent.deleteList('b'));
      await settle();

      expect(loaded(bloc).list.id, 'primary');
      expect(loaded(bloc).lists, hasLength(1));
      await bloc.close();
    });

    test('a rename shows on the open list and in the switcher', () async {
      lists.stored['primary'] = storedList('primary');
      final bloc = build();
      await settle();

      bloc.add(const GroceryListEvent.renameList('primary', 'שבועי'));
      await settle();

      final state = loaded(bloc);
      expect(state.list.name, 'שבועי');
      expect(state.lists.single.name, 'שבועי');
      expect(lists.stored['primary']!.name, 'שבועי');
      await bloc.close();
    });

    test('a list made on the recipe page opens here by itself', () async {
      lists.stored['primary'] = storedList('primary');
      final bloc = build();
      await settle();

      // The recipe page's path: the same use case, the same store.
      final made = await CreateRecipeGroceryListUseCase(
        lists,
        active,
      )(shakshuka(), name: '');
      await settle();

      expect(loaded(bloc).list.id, made.id);
      expect(loaded(bloc).list.name, 'שקשוקה');
      await bloc.close();
    });
  });

  group('a list from one recipe', () {
    test(
      'holds the recipe\'s lines, scaled, and remembers the recipe',
      () async {
        final bloc = build();
        await settle();

        bloc.add(GroceryListEvent.createRecipeList(shakshuka(), '', 2));
        await settle();

        final list = loaded(bloc).list;
        expect(list.source, GroceryListSource.recipe);
        expect(list.recipeId, 'r1');
        expect(list.recipeServings, 2);
        expect(list.recipeScale, 2);
        expect(list.name, 'שקשוקה');
        expect(
          list.items.firstWhere((i) => i.name == 'עגבניות').totalAmount,
          200,
        );
        await bloc.close();
      },
    );

    test('a new scale moves only the recipe\'s share of each line', () async {
      final bloc = build();
      await settle();
      bloc.add(GroceryListEvent.createRecipeList(shakshuka(), 'ארוחה', 1));
      await settle();

      final tomatoes = loaded(
        bloc,
      ).list.items.firstWhere((i) => i.name == 'עגבניות');
      bloc
        ..add(GroceryListEvent.toggleItem(tomatoes.id))
        ..add(GroceryListEvent.addBuffer(tomatoes.id, 50))
        ..add(
          const GroceryListEvent.addAdHocItem('לחם', 1, MeasurementUnit.unit),
        );
      await settle();

      bloc.add(const GroceryListEvent.setRecipeScale(3));
      await settle();

      final list = loaded(bloc).list;
      final scaled = list.items.firstWhere((i) => i.id == tomatoes.id);
      // 100 from the recipe ×3, plus the 50 the shopper added by hand.
      expect(scaled.totalAmount, 350);
      expect(scaled.isChecked, isTrue);
      expect(list.items.firstWhere((i) => i.name == 'לחם').totalAmount, 1);
      expect(list.recipeScale, 3);
      expect(lists.stored[list.id]!.recipeScale, 3);
      await bloc.close();
    });

    test('rebuilding follows the recipe as it is now, keeping ticks', () async {
      recipes.recipes['r1'] = shakshuka();
      final bloc = build();
      await settle();
      bloc.add(GroceryListEvent.createRecipeList(shakshuka(), '', 1));
      await settle();
      final eggs = loaded(bloc).list.items.firstWhere((i) => i.name == 'ביצים');
      bloc.add(GroceryListEvent.toggleItem(eggs.id));
      await settle();

      recipes.recipes['r1'] = shakshuka().copyWith(
        ingredients: const [
          RecipeIngredientEntity(
            name: 'ביצים',
            amount: 6,
            unit: MeasurementUnit.unit,
          ),
        ],
      );
      bloc.add(const GroceryListEvent.regenerate());
      await settle();

      final rebuilt = loaded(bloc).list.items.single;
      expect(rebuilt.totalAmount, 6);
      expect(rebuilt.isChecked, isTrue);
      await bloc.close();
    });

    test('rebuilding with the recipe gone keeps the lines', () async {
      final bloc = build();
      await settle();
      bloc.add(GroceryListEvent.createRecipeList(shakshuka(), '', 1));
      await settle();

      bloc.add(const GroceryListEvent.regenerate());
      await settle();

      expect(loaded(bloc).list.items, hasLength(2));
      await bloc.close();
    });
  });
}
