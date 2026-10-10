import 'dart:convert';

import 'package:easy_plate/core/constants/app_enums.dart';
import 'package:easy_plate/core/features/features_flags.dart';
import 'package:easy_plate/core/home_widgets/home_widget_launch.dart';
import 'package:easy_plate/core/home_widgets/home_widgets_channel.dart';
import 'package:easy_plate/core/home_widgets/home_widgets_service.dart';
import 'package:easy_plate/core/home_widgets/home_widgets_snapshot.dart';
import 'package:easy_plate/core/services/share_intent_service.dart';
import 'package:easy_plate/core/utils/i18n/strings.g.dart';
import 'package:easy_plate/features/grocery_list/domain/entities/grocery_item_entity.dart';
import 'package:easy_plate/features/grocery_list/domain/entities/grocery_item_source_entity.dart';
import 'package:easy_plate/features/grocery_list/domain/entities/grocery_list_entity.dart';
import 'package:easy_plate/features/grocery_list/domain/repositories/grocery_lists_repository.dart';
import 'package:easy_plate/features/meal_planner/domain/entities/meal_entity.dart';
import 'package:easy_plate/features/meal_planner/domain/entities/meal_item_entity.dart';
import 'package:easy_plate/features/meal_planner/domain/entities/meal_plan_entity.dart';
import 'package:easy_plate/features/meal_planner/domain/repositories/meal_plans_repository.dart';
import 'package:easy_plate/features/my_recipes/domain/entities/recipe_entity.dart';
import 'package:easy_plate/features/my_recipes/domain/repositories/recipes_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _Lists implements GroceryListsRepository {
  final Map<String, GroceryListEntity> stored = {};
  _Lists([Iterable<GroceryListEntity> lists = const []]) {
    for (final l in lists) {
      stored[l.id] = l;
    }
  }
  @override
  Future<List<GroceryListEntity>> getLists() async => stored.values.toList();
  @override
  Stream<List<GroceryListEntity>> watchLists() => const Stream.empty();
  @override
  Future<GroceryListEntity?> getListById(String id) async => stored[id];
  @override
  Future<void> saveList(GroceryListEntity list, {bool stampLanguage = true}) async =>
      stored[list.id] = list;
  @override
  Future<void> deleteList(String id) async => stored.remove(id);
}

class _Plans implements MealPlansRepository {
  @override
  Future<List<MealPlanEntity>> getPlans() async => const [];
  @override
  Stream<List<MealPlanEntity>> watchPlans() => const Stream.empty();
  @override
  Future<MealPlanEntity?> getPlanById(String id) async => null;
  @override
  Future<void> savePlan(MealPlanEntity plan, {bool stampLanguage = true}) async {}
  @override
  Future<void> deletePlan(String id) async {}
}

class _Recipes implements RecipesRepository {
  @override
  Future<List<RecipeEntity>> getRecipes() async => const [];
  @override
  Stream<List<RecipeEntity>> watchRecipes() => const Stream.empty();
  @override
  Future<RecipeEntity?> getRecipeById(String id) async => null;
  @override
  Future<void> saveRecipe(RecipeEntity recipe, {bool stampLanguage = true}) async {}
  @override
  Future<void> deleteRecipe(String id) async {}
  @override
  Future<RecipeEntity> readyForSharing(RecipeEntity recipe, {bool persist = true}) async =>
      recipe;
}

GroceryListEntity _list({String id = 'l1', List<GroceryItemEntity>? items}) =>
    GroceryListEntity(
      id: id,
      name: 'Shabbat',
      items: items ??
          const [
            GroceryItemEntity(
              id: 'a',
              name: 'Tomatoes',
              unit: MeasurementUnit.kilogram,
              category: 'produce',
              sources: [GroceryItemSourceEntity(label: 'x', amount: 1.5)],
            ),
            GroceryItemEntity(
              id: 'b',
              name: 'Bread',
              unit: MeasurementUnit.unspecified,
              category: '',
              isChecked: true,
              isAdHoc: true,
              sources: [GroceryItemSourceEntity(label: '', amount: 1)],
            ),
          ],
      createdAt: DateTime(2026),
    );

MealPlanEntity _plan() => MealPlanEntity(
  id: 'p1',
  name: 'Week',
  createdAt: DateTime(2026),
  meals: const [
    MealEntity(
      id: 'm1',
      weekday: 3,
      name: 'Dinner',
      order: 1,
      items: [
        MealItemEntity(id: 'i1', recipeId: 'r1'),
        MealItemEntity(id: 'i2', freeText: 'Salad'),
      ],
    ),
    MealEntity(id: 'm0', weekday: 3, name: 'Breakfast', order: 0, items: []),
    MealEntity(id: 'm2', weekday: 0, name: 'Lunch', order: 0, items: []),
  ],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => LocaleSettings.setLocale(AppLocale.en));

  group('HomeWidgetsSnapshot', () {
    test('serialises lists with quantities and plans with all seven days', () {
      final snapshot = HomeWidgetsSnapshot(
        signedIn: true,
        access: FeatureAccess.enabled,
        assistantAccess: FeatureAccess.locked,
        language: 'en',
        rtl: false,
        dark: false,
        defaults: const HomeWidgetDefaults(listId: 'l1', voice: true),
        lists: [_list()],
        plans: [_plan()],
        recipeTitles: const {'r1': 'Shakshuka'},
        now: DateTime(2026, 10, 7),
      );
      final json = jsonDecode(snapshot.encode()) as Map<String, Object?>;
      expect(json['v'], HomeWidgetsSnapshot.version);
      expect(json['signedIn'], isTrue);
      expect(json['access'], 'enabled');
      expect(json['assistantAccess'], 'locked');
      expect((json['defaults'] as Map)['voice'], isTrue);
      expect((json['weekdays'] as List).length, 7);
      expect((json['prompts'] as List).length, 3);
      expect((json['s'] as Map)['askShefi'], isNotEmpty);

      final list = (json['lists'] as List).single as Map;
      expect(list['total'], 2);
      expect(list['checked'], 1);
      final items = list['items'] as List;
      expect((items[0] as Map)['qty'], '1.5 kg');
      expect((items[1] as Map)['qty'], '1');
      expect((items[1] as Map)['checked'], isTrue);

      final plan = (json['plans'] as List).single as Map;
      final days = plan['days'] as List;
      expect(days.length, 7);
      // Wednesday: ordered by `order`, recipe items carry the title.
      final wednesday = days[3] as List;
      expect((wednesday[0] as Map)['name'], 'Breakfast');
      final dinnerItems = (wednesday[1] as Map)['items'] as List;
      expect((dinnerItems[0] as Map)['label'], 'Shakshuka');
      expect((dinnerItems[0] as Map)['recipeId'], 'r1');
      expect((dinnerItems[1] as Map)['label'], 'Salad');
      expect((dinnerItems[1] as Map).containsKey('recipeId'), isFalse);
      expect(days[1], isEmpty);
    });

    test('a signed-out snapshot carries no account data', () {
      final json = jsonDecode(
        HomeWidgetsSnapshot.signedOut(language: 'he', rtl: true, dark: true).encode(),
      ) as Map<String, Object?>;
      expect(json['signedIn'], isFalse);
      expect(json['lists'], isEmpty);
      expect(json['plans'], isEmpty);
      expect(json['rtl'], isTrue);
      expect((json['s'] as Map)['signIn'], isNotEmpty);
    });

    test('weekday index is Sunday-based like ShoppingDay', () {
      expect(HomeWidgetsSnapshot.weekdayIndex(DateTime(2026, 10, 4)), 0); // Sunday
      expect(HomeWidgetsSnapshot.weekdayIndex(DateTime(2026, 10, 10)), 6); // Saturday
      expect(HomeWidgetsSnapshot.weekdayIndex(DateTime(2026, 10, 7)), 3);
    });

    test('defaults round-trip through json', () {
      const defaults = HomeWidgetDefaults(
        listId: 'l1',
        planId: 'p1',
        voice: true,
        appearance: HomeWidgetAppearance.dark,
      );
      final back = HomeWidgetDefaults.fromJson(defaults.toJson());
      expect(back.listId, 'l1');
      expect(back.planId, 'p1');
      expect(back.voice, isTrue);
      expect(back.appearance, HomeWidgetAppearance.dark);
      expect(HomeWidgetDefaults.fromJson(const {}).appearance, HomeWidgetAppearance.app);
      expect(defaults.copyWith(clearListId: true).listId, isNull);
    });
  });

  group('HomeWidgetLaunch', () {
    test('parses the widget scheme and ignores everything else', () {
      final launch = HomeWidgetLaunch.parse(
        Uri.parse('easyplate://open/widget/assistant?voice=1&prompt=What%20now'),
      )!;
      expect(launch.action, HomeWidgetAction.assistant);
      expect(launch.voice, isTrue);
      expect(launch.prompt, 'What now');

      final grocery = HomeWidgetLaunch.parse(
        Uri.parse('easyplate://open/widget/grocery?list=l1&add=1'),
      )!;
      expect(grocery.action, HomeWidgetAction.grocery);
      expect(grocery.listId, 'l1');
      expect(grocery.add, isTrue);

      final plan = HomeWidgetLaunch.parse(Uri.parse('easyplate://widget/plan'))!;
      expect(plan.action, HomeWidgetAction.plan);
      expect(plan.planId, isNull);

      expect(HomeWidgetLaunch.parse(Uri.parse('easyplate://open/s/ABC')), isNull);
      expect(HomeWidgetLaunch.parse(Uri.parse('/widget/plan'))?.action, HomeWidgetAction.plan);
      expect(HomeWidgetLaunch.parse(Uri.parse('easyplate://widget/nope')), isNull);
      expect(HomeWidgetLaunch.parse(Uri.parse('/home')), isNull);
    });

    test('the pending mailbox holds the latest launch until taken', () {
      PendingHomeWidgetLaunch.capture(Uri.parse('easyplate://widget/settings'));
      expect(PendingHomeWidgetLaunch.notifier.value?.action, HomeWidgetAction.settings);
      expect(PendingHomeWidgetLaunch.take()?.action, HomeWidgetAction.settings);
      expect(PendingHomeWidgetLaunch.take(), isNull);
    });
  });

  test('the app\'s own links are never taken for a shared recipe source', () {
    expect(ShareIntentService.isOwnLink('easyplate://open/widget/assistant?voice=1'), isTrue);
    expect(ShareIntentService.isOwnLink('easyplate://open/s/7K3M9QX2'), isTrue);
    expect(ShareIntentService.isOwnLink('https://aieasyplate.app/s/7K3M9QX2'), isTrue);
    expect(ShareIntentService.isOwnLink('https://www.youtube.com/watch?v=x'), isFalse);
    expect(ShareIntentService.isOwnLink('2 eggs, 1 cup flour'), isFalse);
  });

  group('HomeWidgetsService.applyPending', () {
    late _Lists lists;
    late HomeWidgetsService service;

    setUp(() {
      lists = _Lists([_list()]);
      service = HomeWidgetsService.forTest(
        channel: HomeWidgetsChannel(),
        groceries: lists,
        plans: _Plans(),
        recipes: _Recipes(),
      );
    });

    test('add appends an ad-hoc line of one unit to the named list', () async {
      await service.applyPending(
        {'id': 'q1', 'type': 'add', 'listId': 'l1', 'name': ' Milk '},
        lists,
      );
      final saved = lists.stored['l1']!;
      expect(saved.items.length, 3);
      final milk = saved.items.last;
      expect(milk.name, 'Milk');
      expect(milk.isAdHoc, isTrue);
      expect(milk.unit, MeasurementUnit.unit);
      expect(milk.totalAmount, 1);
    });

    test('toggle sets the line to the state the widget asked for', () async {
      await service.applyPending(
        {'id': 'q2', 'type': 'toggle', 'listId': 'l1', 'itemId': 'a', 'checked': true},
        lists,
      );
      expect(lists.stored['l1']!.items.first.isChecked, isTrue);
      await service.applyPending(
        {'id': 'q3', 'type': 'toggle', 'listId': 'l1', 'itemId': 'b'},
        lists,
      );
      // No `checked`: flipped.
      expect(lists.stored['l1']!.items[1].isChecked, isFalse);
    });

    test('a missing list falls back to the oldest, and none at all creates one', () async {
      await service.applyPending(
        {'id': 'q4', 'type': 'add', 'listId': 'gone', 'name': 'Eggs'},
        lists,
      );
      expect(lists.stored['l1']!.items.map((i) => i.name), contains('Eggs'));

      final empty = _Lists();
      await service.applyPending(
        {'id': 'q5', 'type': 'add', 'name': 'Eggs'},
        empty,
      );
      expect(empty.stored.keys.single, 'primary');
      expect(empty.stored['primary']!.items.single.name, 'Eggs');
    });

    test('blank names and unknown types change nothing', () async {
      await service.applyPending({'id': 'q6', 'type': 'add', 'listId': 'l1', 'name': '  '}, lists);
      await service.applyPending({'id': 'q7', 'type': 'rename', 'listId': 'l1'}, lists);
      expect(lists.stored['l1']!.items.length, 2);
    });
  });
}
