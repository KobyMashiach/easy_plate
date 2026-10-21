import 'package:easy_plate/core/hive/user_scope.dart';
import 'package:easy_plate/features/collab_containers/domain/container_sharing_service.dart';
import 'package:easy_plate/features/collab_containers/domain/usecases/container_collab.dart';
import 'package:easy_plate/core/constants/app_constants.dart';
import 'package:easy_plate/core/constants/app_enums.dart';
import 'package:easy_plate/core/features/features_flags.dart';
import 'package:easy_plate/core/monetization/entitlement_service.dart';
import 'package:easy_plate/core/services/cook_session_service.dart';
import 'package:easy_plate/core/utils/i18n/strings.g.dart';
import 'package:easy_plate/features/assistant/domain/assistant_dispatcher.dart';
import 'package:easy_plate/features/assistant/domain/assistant_models.dart';
import 'package:easy_plate/features/assistant/domain/assistant_scope.dart';
import 'package:easy_plate/features/assistant/domain/assistant_tools.dart';
import 'package:easy_plate/features/assistant/domain/assistant_ui_bridge.dart';
import 'package:easy_plate/features/grocery_list/data/datasources/active_grocery_list_store.dart';
import 'package:easy_plate/features/grocery_list/domain/entities/grocery_item_entity.dart';
import 'package:easy_plate/features/grocery_list/domain/entities/grocery_list_entity.dart';
import 'package:easy_plate/features/grocery_list/domain/repositories/grocery_lists_repository.dart';
import 'package:easy_plate/features/meal_planner/domain/entities/meal_plan_entity.dart';
import 'package:easy_plate/features/meal_planner/domain/repositories/meal_plans_repository.dart';
import 'package:easy_plate/features/my_recipes/domain/entities/nutrition_entity.dart';
import 'package:easy_plate/features/my_recipes/domain/entities/recipe_entity.dart';
import 'package:easy_plate/features/my_recipes/domain/entities/recipe_ingredient_entity.dart';
import 'package:easy_plate/features/my_recipes/domain/repositories/recipes_repository.dart';
import 'package:easy_plate/features/recipe_books/domain/entities/recipe_book_entity.dart';
import 'package:easy_plate/features/recipe_books/domain/repositories/recipe_books_repository.dart';
import 'package:easy_plate/features/recipe_ingestion/domain/repositories/recipe_ingestion_repository.dart';
import 'package:easy_plate/features/user_profile/domain/entities/user_preferences_entity.dart';
import 'package:easy_plate/features/user_profile/domain/repositories/user_preferences_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// In-memory stand-ins: the dispatcher is exercised against real entity
// semantics (copyWith, mealsForWeekday, checkedCount), not against mocks
// of what it should write.
class _Recipes implements RecipesRepository {
  final Map<String, RecipeEntity> store = {};
  @override
  Future<List<RecipeEntity>> getRecipes() async => store.values.toList();
  @override
  Stream<List<RecipeEntity>> watchRecipes() =>
      Stream.value(store.values.toList());
  @override
  Future<RecipeEntity?> getRecipeById(String id) async => store[id];
  @override
  Future<void> saveRecipe(
    RecipeEntity recipe, {
    bool stampLanguage = true,
  }) async => store[recipe.id] = recipe;
  @override
  Future<void> deleteRecipe(String id) async => store.remove(id);
  @override
  Future<RecipeEntity> readyForSharing(
    RecipeEntity recipe, {
    bool persist = true,
  }) async => recipe;
}

class _Books implements RecipeBooksRepository {
  final Map<String, RecipeBookEntity> store = {};
  @override
  Future<List<RecipeBookEntity>> getBooks() async => store.values.toList();
  @override
  Stream<List<RecipeBookEntity>> watchBooks() =>
      Stream.value(store.values.toList());
  @override
  Future<RecipeBookEntity?> getBookById(String id) async => store[id];
  @override
  Future<void> saveBook(
    RecipeBookEntity book, {
    bool stampLanguage = true,
  }) async => store[book.id] = book;
  @override
  Future<void> deleteBook(String id) async => store.remove(id);
  @override
  Future<RecipeBookEntity> readyForSharing(RecipeBookEntity book) async => book;
}

class _Plans implements MealPlansRepository {
  final Map<String, MealPlanEntity> store = {};
  @override
  Future<List<MealPlanEntity>> getPlans() async => store.values.toList();
  @override
  Stream<List<MealPlanEntity>> watchPlans() =>
      Stream.value(store.values.toList());
  @override
  Future<MealPlanEntity?> getPlanById(String id) async => store[id];
  @override
  Future<void> savePlan(
    MealPlanEntity plan, {
    bool stampLanguage = true,
  }) async => store[plan.id] = plan;
  @override
  Future<void> deletePlan(String id) async => store.remove(id);
}

class _PlanCollab implements ContainerCollab<MealPlanEntity> {
  final published = <String>[];
  @override
  Future<void> publish(MealPlanEntity item, {required String uid}) async =>
      published.add('${item.collabId}:$uid');
  @override
  dynamic noSuchMethod(Invocation i) => throw UnimplementedError();
}

class _ContainerSharing implements ContainerSharingService {
  @override
  final _PlanCollab plans = _PlanCollab();
  @override
  dynamic noSuchMethod(Invocation i) => throw UnimplementedError();
}

class _Groceries implements GroceryListsRepository {
  final Map<String, GroceryListEntity> store = {};
  @override
  Future<List<GroceryListEntity>> getLists() async => store.values.toList();
  @override
  Stream<List<GroceryListEntity>> watchLists() =>
      Stream.value(store.values.toList());
  @override
  Future<GroceryListEntity?> getListById(String id) async => store[id];
  @override
  Future<void> saveList(
    GroceryListEntity list, {
    bool stampLanguage = true,
  }) async => store[list.id] = list;
  @override
  Future<void> deleteList(String id) async => store.remove(id);
}

class _Active implements ActiveGroceryListStore {
  String? id;
  @override
  Future<String?> read() async => id;
  @override
  Future<void> write(String listId) async => id = listId;
  @override
  Stream<String> get changes => const Stream.empty();
}

class _Prefs implements UserPreferencesRepository {
  UserPreferencesEntity prefs = const UserPreferencesEntity(
    shoppingDay: ShoppingDay.friday,
    dietaryPreferences: [DietaryPreference.vegetarian],
  );
  @override
  Future<UserPreferencesEntity> getPreferences() async => prefs;
  @override
  Future<void> savePreferences(UserPreferencesEntity preferences) async =>
      prefs = preferences;
}

class _Ingestion extends Mock implements RecipeIngestionRepository {}

class _Ui implements AssistantUiBridge {
  bool confirm = true;
  bool allow = true;
  final opened = <String>[];
  @override
  Future<bool> confirmDelete(String what) async => confirm;
  @override
  Future<bool> allowAiExtraction() async => allow;
  @override
  void openRecipe(RecipeEntity recipe) => opened.add('recipe:${recipe.id}');
  @override
  void openCookMode(RecipeEntity recipe) => opened.add('cook:${recipe.id}');
  @override
  void openScreen(String screen) => opened.add('screen:$screen');
}

void main() {
  // The cook session registers a lifecycle observer: a binding is needed.
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => LocaleSettings.setLocale(AppLocale.en));

  late _Recipes recipes;
  late _Books books;
  late _Plans plans;
  late _Groceries groceries;
  late _Active active;
  late _Prefs prefs;
  late _Ingestion ingestion;
  late _Ui ui;
  late AssistantDispatcher dispatcher;

  final salmon = RecipeEntity(
    id: 'r1',
    title: 'Creamy Tuscan Salmon',
    createdAt: DateTime(2026, 1, 1),
    servings: 4,
    ingredients: const [
      RecipeIngredientEntity(
        name: 'Salmon fillets',
        amount: 4,
        unit: MeasurementUnit.unit,
      ),
      RecipeIngredientEntity(
        name: 'Heavy cream',
        amount: 200,
        unit: MeasurementUnit.milliliter,
      ),
    ],
    steps: const [
      'Season.',
      'Sear the salmon for 4 minutes.',
      'Add cream and serve.',
    ],
  );

  Future<ToolResult> run(String tool, [Map<String, dynamic> args = const {}]) =>
      dispatcher.execute(ToolCall(id: 'c', name: tool, arguments: args));

  setUp(() {
    recipes = _Recipes()..store['r1'] = salmon;
    books = _Books();
    plans = _Plans();
    groceries = _Groceries();
    active = _Active();
    prefs = _Prefs();
    ingestion = _Ingestion();
    ui = _Ui();
    dispatcher = AssistantDispatcher(
      recipes: recipes,
      books: books,
      plans: plans,
      groceries: groceries,
      activeList: active,
      ingestion: ingestion,
      preferences: prefs,
      cooking: CookSessionService(),
      ui: ui,
    );
  });

  // Cook mode is Premium by default; the dispatcher's timer tools follow
  // the same gate as the screen.
  setUp(() => EntitlementService().setForTest(true));
  tearDown(() {
    CookSessionService().finishAll();
    EntitlementService().setForTest(false);
  });

  test('every declared tool has a unique name and an object schema', () {
    final names = AssistantTools.declarations.map((d) => d['name']).toList();
    expect(names.toSet().length, names.length);
    for (final d in AssistantTools.declarations) {
      expect(d['type'], 'function');
      expect((d['parameters'] as Map)['type'], 'object');
      expect((d['description'] as String).length, greaterThan(10));
    }
  });

  test('a failing tool reports a short reason, not the whole error', () async {
    when(
      () => ingestion.estimateNutrition(salmon),
    ).thenThrow(StateError('${'x' * 1000}\n#0 frame\n#1 frame'));
    final r = await run(AssistantTools.estimateNutrition, {'recipe_id': 'r1'});
    expect(r.data['error'], 'failed');
    final message = r.data['message'] as String;
    expect(message.length, 300);
    expect(message, isNot(contains('#0')));
  });

  test('pass 7: an estimate lands on the recipe as it is now', () async {
    when(() => ingestion.estimateNutrition(salmon)).thenAnswer((_) async {
      // Renamed on the website while the model was thinking.
      recipes.store['r1'] = salmon.copyWith(title: 'Renamed on the web');
      return salmon.copyWith(
        servings: 2,
        nutrition: const NutritionEntity(
          calories: 500,
          proteinGrams: 30,
          carbsGrams: 10,
          fatGrams: 20,
        ),
      );
    });
    final r = await run(AssistantTools.estimateNutrition, {'recipe_id': 'r1'});
    expect(r.data['ok'], true);
    final saved = recipes.store['r1']!;
    expect(saved.title, 'Renamed on the web');
    expect(saved.servings, 2);
    expect(saved.nutrition?.calories, 500);
  });

  test('an unknown tool is refused, not thrown', () async {
    final r = await run('no_such_tool');
    expect(r.data['ok'], false);
    expect(r.data['error'], 'unknown_tool');
  });

  group('groceries', () {
    test('a scoped list is capped in the prompt, tools still reach '
        'unlisted items', () async {
      final items = [
        for (var i = 0; i < 400; i++)
          GroceryItemEntity(
            id: 'i$i',
            name: 'Item $i',
            unit: MeasurementUnit.unit,
            sources: const [],
            category: kDefaultGroceryCategory,
            // Every other line already bought.
            isChecked: i.isOdd,
          ),
      ];
      groceries.store['l1'] = GroceryListEntity(
        id: 'l1',
        name: 'Big',
        items: items,
        createdAt: DateTime(2026, 1, 1),
      );
      final text = (await dispatcher.describe(
        const AssistantScope.groceryList(id: 'l1', title: 'Big'),
      ))!;
      final lines = text.split('\n').where((l) => l.startsWith('- ')).toList();
      expect(lines.length, AssistantDispatcher.scopedGroceryItemCap);
      // Still-to-buy lines come first.
      expect(lines.every((l) => l.startsWith('- [ ]')), isTrue);
      expect(text, contains('250 more items'));
      expect(text, contains('50 still to buy, 200 bought'));

      // The last unchecked item was not listed, but can be ticked by name.
      expect(text, isNot(contains('Item 398 ')));
      final r = await run(AssistantTools.setGroceryItemChecked, {
        'list_id': 'l1',
        'items': ['Item 398'],
      });
      expect(r.data['ok'], true);
      expect(
        groceries.store['l1']!.items
            .firstWhere((i) => i.id == 'i398')
            .isChecked,
        isTrue,
      );
    });

    test('adding items creates the active list and merges repeats', () async {
      final r = await run(AssistantTools.addGroceryItems, {
        'items': [
          {'name': 'Milk', 'amount': 1, 'unit': 'liter'},
          {'name': 'Eggs', 'amount': 6, 'unit': 'unit'},
        ],
      });
      expect(r.data['ok'], true);
      expect(r.card, isA<GroceryCard>());
      expect(active.id, isNotNull);
      expect(groceries.store.values.single.items.length, 2);

      await run(AssistantTools.addGroceryItems, {
        'items': [
          {'name': 'eggs', 'amount': 6, 'unit': 'unit'},
        ],
      });
      final list = groceries.store.values.single;
      expect(list.items.length, 2);
      expect(list.items.firstWhere((i) => i.name == 'Eggs').totalAmount, 12);
    });

    test('items are checked by fuzzy name and cleared when bought', () async {
      await run(AssistantTools.addGroceryItems, {
        'items': [
          {'name': 'Milk'},
          {'name': 'Olive oil'},
        ],
      });
      final checked = await run(AssistantTools.setGroceryItemChecked, {
        'items': ['oil'],
        'checked': true,
      });
      expect(checked.data['changed'], 1);
      expect(groceries.store.values.single.checkedCount, 1);

      final cleared = await run(AssistantTools.clearCheckedItems);
      expect(cleared.data['removed'], 1);
      expect(groceries.store.values.single.items.single.name, 'Milk');
    });

    test(
      'with several lists and no choice, adding asks instead of guessing',
      () async {
        await run(AssistantTools.createGroceryList, {'name': 'Weekly'});
        final second = await run(AssistantTools.createGroceryList, {
          'name': 'Weekly',
        });
        expect(second.data['name'], 'Weekly 2');
        expect(groceries.store.values.map((l) => l.name).toSet().length, 2);

        final asked = await run(AssistantTools.addGroceryItems, {
          'items': [
            {'name': 'Milk'},
          ],
        });
        expect(asked.data['error'], 'ambiguous_list');
        expect((asked.data['lists'] as List).length, 2);
        expect(groceries.store.values.every((l) => l.items.isEmpty), isTrue);

        final weekly = groceries.store.values.firstWhere(
          (l) => l.name == 'Weekly',
        );
        final added = await run(AssistantTools.addGroceryItems, {
          'items': [
            {'name': 'Milk'},
          ],
          'list_id': weekly.id,
        });
        expect(added.data['ok'], true);
        expect(groceries.store[weekly.id]!.items.single.name, 'Milk');
        expect(
          groceries.store.values.firstWhere((l) => l.name == 'Weekly 2').items,
          isEmpty,
        );
      },
    );

    test('a list is built from a recipe and becomes active', () async {
      final r = await run(AssistantTools.groceryListFromRecipe, {
        'recipe_id': 'r1',
        'scale': 2,
      });
      expect(r.data['ok'], true);
      final list = groceries.store[active.id]!;
      expect(list.source, GroceryListSource.recipe);
      expect(
        list.items.firstWhere((i) => i.name == 'Heavy cream').totalAmount,
        400,
      );
    });
  });

  group('recipes', () {
    test('search finds by title and by ingredient, and returns ids', () async {
      final byTitle = await run(AssistantTools.searchRecipes, {
        'query': 'tuscan',
      });
      expect((byTitle.data['recipes'] as List).single['id'], 'r1');
      final byIngredient = await run(AssistantTools.searchRecipes, {
        'query': 'cream',
      });
      expect(byIngredient.data['count'], 1);
      final none = await run(AssistantTools.searchRecipes, {'query': 'pizza'});
      expect(none.data['count'], 0);
    });

    test('a recipe named instead of an id still resolves', () async {
      final r = await run(AssistantTools.getRecipe, {
        'recipe_id': 'creamy tuscan',
      });
      expect(r.data['id'], 'r1');
      expect((r.data['steps'] as List).length, 3);
    });

    test('create, update and delete go through the repository', () async {
      final created = await run(AssistantTools.createRecipe, {
        'title': 'Shakshuka',
        'ingredients': [
          {'name': 'Eggs', 'amount': 4, 'unit': 'unit'},
        ],
        'steps': ['Simmer the sauce.', 'Crack the eggs in.'],
        'servings': 2,
        'dietary_tags': ['vegetarian'],
      });
      final id = created.data['id'] as String;
      expect(recipes.store[id]!.dietaryTags, [DietaryPreference.vegetarian]);

      await run(AssistantTools.updateRecipe, {
        'recipe_id': id,
        'servings': 3,
        'add_ingredients': [
          {'name': 'Feta', 'amount': 100, 'unit': 'gram'},
        ],
        'remove_ingredient_names': ['eggs'],
      });
      final updated = recipes.store[id]!;
      expect(updated.servings, 3);
      expect(updated.ingredients.map((i) => i.name), ['Feta']);

      ui.confirm = false;
      final refused = await run(AssistantTools.deleteRecipe, {'recipe_id': id});
      expect(refused.data['error'], 'cancelled');
      expect(recipes.store.containsKey(id), isTrue);
      ui.confirm = true;
      await run(AssistantTools.deleteRecipe, {'recipe_id': id});
      expect(recipes.store.containsKey(id), isFalse);
    });

    test('integer arguments survive arriving as doubles or strings', () async {
      // Gemini's JSON often carries `integer` fields as `4.0`; a strict cast
      // used to fail the whole tool.
      final created = await run(AssistantTools.createRecipe, {
        'title': 'Lentil soup',
        'servings': 4.0,
        'prep_minutes': '10',
        'cook_minutes': 25.0,
        'ingredients': [
          {'name': 'Lentils', 'amount': 200, 'unit': 'gram'},
          {'unit': 'unit'}, // nameless: dropped, not fatal
        ],
        'dietary_tags': ['vegan', 3],
      });
      expect(created.data['ok'], isNot(false));
      final saved = recipes.store[created.data['id'] as String]!;
      expect(saved.servings, 4);
      expect(saved.prepTimeMinutes, 10);
      expect(saved.cookTimeMinutes, 25);
      expect(saved.ingredients.map((i) => i.name), ['Lentils']);
      expect(saved.dietaryTags, [DietaryPreference.vegan]);

      final found = await run(AssistantTools.searchRecipes, {
        'query': '',
        'limit': 1.0,
      });
      expect((found.data['recipes'] as List), hasLength(1));
      expect(found.data['count'], 2);
    });

    test(
      'a link import is gated by the AI allowance and saved on success',
      () async {
        ui.allow = false;
        final blocked = await run(AssistantTools.importRecipe, {
          'source': 'url',
          'content': 'https://example.com/r',
        });
        expect(blocked.data['error'], 'quota');
        verifyNever(() => ingestion.parseFromUrl(any(), any()));

        ui.allow = true;
        when(() => ingestion.parseFromUrl(any(), any())).thenAnswer(
          (_) async => salmon.copyWith(title: 'Imported'),
        );
        final ok = await run(AssistantTools.importRecipe, {
          'source': 'url',
          'content': 'https://example.com/r',
        });
        expect(ok.data['title'], 'Imported');
        expect(recipes.store.values.any((r) => r.title == 'Imported'), isTrue);
      },
    );

    test('text and request imports spend the AI allowance too', () async {
      ui.allow = false;
      for (final source in ['text', 'request']) {
        final r = await run(AssistantTools.importRecipe, {
          'source': source,
          'content': 'Shakshuka with eggs and tomatoes',
        });
        expect(r.data['error'], 'quota', reason: source);
      }
      verifyNever(() => ingestion.parseRawText(any(), any()));
      verifyNever(() => ingestion.generateRecipe(any(), any()));
    });

    test('a link import refuses anything but an http(s) address', () async {
      for (final bad in ['javascript:alert(1)', 'example.com/r', 'a recipe']) {
        final r = await run(AssistantTools.importRecipe, {
          'source': 'url',
          'content': bad,
        });
        expect(r.data['error'], 'invalid', reason: bad);
      }
      final video = await run(AssistantTools.importRecipe, {
        'source': 'social_video',
        'content': 'tiktok.com/@a/video/1',
      });
      expect(video.data['error'], 'invalid');
      verifyNever(() => ingestion.parseFromUrl(any(), any()));
      verifyNever(() => ingestion.parseFromSocialVideo(any(), any()));
    });

    test('a search limit below one falls back instead of throwing', () async {
      final r = await run(AssistantTools.searchRecipes, {
        'query': '',
        'limit': -3,
      });
      expect(r.data['ok'], true);
      expect((r.data['recipes'] as List), hasLength(1));
    });
  });

  group('meal plans', () {
    test('planning a meal creates a plan when none exists', () async {
      final r = await run(AssistantTools.planMeal, {
        'weekday': 'tuesday',
        'meal': 'dinner',
        'recipe_id': 'r1',
      });
      expect(r.data['ok'], true);
      expect(r.card, isA<PlannedMealCard>());
      final plan = plans.store.values.single;
      final dinner = plan
          .mealsForWeekday(2)
          .firstWhere((m) => m.name == 'Dinner');
      expect(dinner.items.single.recipeId, 'r1');

      final listed = await run(AssistantTools.listMealPlans);
      expect(listed.card, isA<LinesCard>());

      final removed = await run(AssistantTools.removePlannedItem, {
        'plan_id': plan.id,
        'meal_id': dinner.id,
        'item_id': dinner.items.single.id,
      });
      expect(removed.data['ok'], true);
      expect(
        plans.store[plan.id]!.mealsForWeekday(2).every((m) => m.items.isEmpty),
        isTrue,
      );
    });

    test('a free-text dish lands on a custom meal', () async {
      await run(AssistantTools.createMealPlan, {
        'name': 'Week',
        'template': 'free',
      });
      final r = await run(AssistantTools.planMeal, {
        'weekday': 'friday',
        'meal': 'Shabbat dinner',
        'free_text': 'Chicken soup',
      });
      expect(r.data['title'], 'Chicken soup');
      final meal = plans.store.values.single.mealsForWeekday(5).single;
      expect(meal.name, 'Shabbat dinner');
      expect(meal.items.single.freeText, 'Chicken soup');
    });

    test(
      'pass 8: an edit to a shared plan is published to its members',
      () async {
        await run(AssistantTools.planMeal, {
          'weekday': 'tuesday',
          'meal': 'dinner',
          'recipe_id': 'r1',
        });
        final plan = plans.store.values.single;
        plans.store[plan.id] = plan.copyWith(
          collabId: 'c1',
          collabRole: CollabRole.editor,
        );
        final sharing = _ContainerSharing();
        UserScope().resetForTest();
        await UserScope().switchTo('me');
        addTearDown(UserScope().resetForTest);
        final shared = AssistantDispatcher(
          recipes: recipes,
          books: books,
          plans: plans,
          groceries: groceries,
          activeList: active,
          ingestion: ingestion,
          preferences: prefs,
          cooking: CookSessionService(),
          ui: ui,
          sharing: sharing,
        );
        final r = await shared.execute(
          const ToolCall(
            id: 'c',
            name: AssistantTools.planMeal,
            arguments: {
              'weekday': 'friday',
              'meal': 'dinner',
              'free_text': 'Soup',
            },
          ),
        );
        expect(r.data['ok'], true);
        expect(sharing.plans.published, ['c1:me']);
      },
    );
  });

  group('books, cooking, preferences, navigation', () {
    test('a recipe joins a book once', () async {
      final book = await run(AssistantTools.createBook, {
        'title': 'Weeknights',
      });
      final id = book.data['id'] as String;
      await run(AssistantTools.addRecipeToBook, {
        'recipe_id': 'r1',
        'book_id': id,
      });
      final again = await run(AssistantTools.addRecipeToBook, {
        'recipe_id': 'r1',
        'book_id': 'weeknights',
      });
      expect(again.data['already_in_book'], true);
      expect(books.store[id]!.recipeRefs.length, 1);
    });

    test('a step timer starts without leaving the chat', () async {
      final r = await run(AssistantTools.startTimer, {
        'recipe_id': 'r1',
        'step': 2,
      });
      expect(r.data, containsPair('ok', true));
      expect(CookSessionService().hasRunningTimer, isTrue);
      final none = await run(AssistantTools.startTimer, {
        'recipe_id': 'r1',
        'step': 1,
      });
      expect(none.data['error'], 'no_timer');
    });

    test('preferences are saved and reported', () async {
      await run(AssistantTools.setShoppingDay, {'day': 'sunday'});
      await run(AssistantTools.setDietaryPreferences, {
        'add': ['vegan'],
        'remove': ['vegetarian'],
      });
      final r = await run(AssistantTools.getPreferences);
      expect(r.data['shopping_day'], 'sunday');
      expect(r.data['dietary'], ['vegan']);
    });

    test('opening things goes through the screen', () async {
      await run(AssistantTools.openRecipe, {'recipe_id': 'r1'});
      await run(AssistantTools.openScreen, {'screen': 'groceries'});
      expect(ui.opened, ['recipe:r1', 'screen:groceries']);
    });
  });

  group('limits', () {
    final long = 'x' * 500;
    final many = [for (var i = 0; i < 150; i++) 'item $i'];

    test('titles are cut to 200 characters, lists to 100 items', () async {
      final created = await run(AssistantTools.createRecipe, {
        'title': long,
        'ingredients': [
          for (final name in many) {'name': name},
        ],
        'steps': many,
      });
      final saved = recipes.store[created.data['id'] as String]!;
      expect(saved.title.length, AssistantDispatcher.maxTitleLength);
      expect(saved.ingredients, hasLength(AssistantDispatcher.maxListItems));
      expect(saved.steps, hasLength(AssistantDispatcher.maxListItems));

      final book = await run(AssistantTools.createBook, {'title': long});
      expect(
        (book.data['title'] as String).length,
        AssistantDispatcher.maxTitleLength,
      );

      final list = await run(AssistantTools.addGroceryItems, {
        'items': [
          for (final name in many) {'name': name},
        ],
      });
      expect(
        list.data['items'] as List,
        hasLength(AssistantDispatcher.maxListItems),
      );
    });

    test('a step longer than 4000 characters is cut, not refused', () async {
      final step = 'y' * 5000;
      final r = await run(AssistantTools.createRecipe, {
        'title': 'Long',
        'ingredients': const [],
        'steps': [step],
      });
      final saved = recipes.store[r.data['id'] as String]!;
      expect(saved.steps.single.length, AssistantDispatcher.maxTextLength);
    });

    test('a pasted recipe over 4000 characters is refused whole', () async {
      final r = await run(AssistantTools.importRecipe, {
        'source': 'text',
        'content': 'z' * 5000,
      });
      expect(r.data['error'], 'invalid');
      verifyNever(() => ingestion.parseRawText(any(), any()));
    });

    test('a blank title on update keeps the old one', () async {
      final r = await run(AssistantTools.updateRecipe, {
        'recipe_id': 'r1',
        'title': '   ',
        'servings': 6,
      });
      expect(r.data['title'], 'Creamy Tuscan Salmon');
      expect(recipes.store['r1']!.servings, 6);
    });

    test('open_screen takes only the screens it declares', () async {
      final bad = await run(AssistantTools.openScreen, {'screen': 'vault'});
      expect(bad.data['error'], 'invalid');
      expect(ui.opened, isEmpty);
      final ok = await run(AssistantTools.openScreen, {'screen': 'library'});
      expect(ok.data['opened'], 'library');
      expect(ui.opened, ['screen:library']);
    });

    test('a view-only book or recipe is not written through', () async {
      books.store['b1'] = RecipeBookEntity(
        id: 'b1',
        title: 'Shared',
        recipeRefs: const [],
        createdAt: DateTime(2026),
        collabId: 'c1',
        collabRole: CollabRole.viewer,
      );
      final r = await run(AssistantTools.addRecipeToBook, {
        'recipe_id': 'r1',
        'book_id': 'b1',
      });
      expect(r.data['error'], 'read_only');
      expect(books.store['b1']!.recipeRefs, isEmpty);
    });
  });

  group('feature gates', () {
    tearDown(() => FeaturesFlags.overrides = null);

    test('a hidden feature refuses the write and nothing is saved', () async {
      FeaturesFlags.overrides = {
        FeaturesFlags.books: FeatureFlagValue.hidden,
        FeaturesFlags.mealPlans: FeatureFlagValue.comingSoon,
        FeaturesFlags.groceryLists: FeatureFlagValue.hidden,
      };
      final book = await run(AssistantTools.createBook, {'title': 'B'});
      expect(book.data['error'], 'unavailable');
      expect(books.store, isEmpty);
      final plan = await run(AssistantTools.planMeal, {
        'weekday': 'monday',
        'meal': 'dinner',
        'recipe_id': 'r1',
      });
      expect(plan.data['error'], 'unavailable');
      expect(plans.store, isEmpty);
      final list = await run(AssistantTools.addGroceryItems, {
        'items': [
          {'name': 'Milk'},
        ],
      });
      expect(list.data['error'], 'unavailable');
      expect(groceries.store, isEmpty);
      // Reads are not gated: the model may still describe what exists.
      expect((await run(AssistantTools.listBooks)).data['ok'], true);
    });

    test(
      'a Premium-only feature on a free account opens the paywall',
      () async {
        EntitlementService().setForTest(false);
        FeaturesFlags.overrides = {
          FeaturesFlags.nutrition: FeatureFlagValue.premiumOnly,
        };
        final r = await run(AssistantTools.estimateNutrition, {
          'recipe_id': 'r1',
        });
        expect(r.data['error'], 'premium_required');
        expect(ui.opened, ['screen:premium']);
        verifyNever(() => ingestion.estimateNutrition(salmon));

        // Paying: the same call goes through.
        EntitlementService().setForTest(true);
        when(
          () => ingestion.estimateNutrition(salmon),
        ).thenAnswer((_) async => salmon);
        final ok = await run(AssistantTools.estimateNutrition, {
          'recipe_id': 'r1',
        });
        expect(ok.data['ok'], true);
      },
    );

    test('an import is gated by its channel\'s own flag', () async {
      FeaturesFlags.overrides = {
        FeaturesFlags.ingestAiRequest: FeatureFlagValue.hidden,
      };
      final r = await run(AssistantTools.importRecipe, {
        'source': 'request',
        'content': 'a quick soup',
      });
      expect(r.data['error'], 'unavailable');
      verifyNever(() => ingestion.generateRecipe(any(), any()));
      when(() => ingestion.parseRawText(any(), any())).thenAnswer(
        (_) async => salmon.copyWith(title: 'Pasted'),
      );
      final text = await run(AssistantTools.importRecipe, {
        'source': 'text',
        'content': 'Salmon: sear it.',
      });
      expect(text.data['title'], 'Pasted');
    });
  });

  group('support', () {
    test('contact_support checks its arguments, then needs a signed-in '
        'account and a repository', () async {
      final noMessage = await dispatcher.execute(
        const ToolCall(
          id: '1',
          name: 'contact_support',
          arguments: {'reason': 'bug', 'message': ' '},
        ),
      );
      expect(noMessage.data['error'], 'invalid');
      final badReason = await dispatcher.execute(
        const ToolCall(
          id: '2',
          name: 'contact_support',
          arguments: {'reason': 'weather', 'message': 'hi'},
        ),
      );
      expect(badReason.data['error'], 'invalid');
      // No feedback repository on this dispatcher, and no session in a test:
      // the tool says so instead of pretending.
      final unavailable = await dispatcher.execute(
        const ToolCall(
          id: '3',
          name: 'contact_support',
          arguments: {'reason': 'bug', 'message': 'the timer stops'},
        ),
      );
      expect(unavailable.data['ok'], isFalse);
      expect(unavailable.data['error'], 'unavailable');
    });
  });

  test('kitchen conversions are exact and density-aware', () async {
    final cups = await run(AssistantTools.convertMeasurement, {
      'amount': 2,
      'from': 'cup',
      'to': 'milliliter',
    });
    expect(cups.data['result'], 480);
    final flour = await run(AssistantTools.convertMeasurement, {
      'amount': 1,
      'from': 'cup',
      'to': 'gram',
      'ingredient': 'flour',
    });
    expect(flour.data['result'], closeTo(127, 1));
    final oven = await run(AssistantTools.convertMeasurement, {
      'amount': 180,
      'from': 'celsius',
      'to': 'fahrenheit',
    });
    expect(oven.data['result'], 356);
    final odd = await run(AssistantTools.convertMeasurement, {
      'amount': 1,
      'from': 'cup',
      'to': 'celsius',
    });
    expect(odd.data['error'], 'unsupported');
  });

  test('conversions take plurals and pick the longest ingredient', () async {
    final cups = await run(AssistantTools.convertMeasurement, {
      'amount': 2,
      'from': 'Cups',
      'to': 'milliliters',
    });
    expect(cups.data['result'], 480);
    final spoons = await run(AssistantTools.convertMeasurement, {
      'amount': '3',
      'from': 'teaspoons',
      'to': 'tablespoons',
    });
    expect(spoons.data['result'], 1);
    final grams = await run(AssistantTools.convertMeasurement, {
      'amount': 1000,
      'from': 'grams',
      'to': 'kgs',
    });
    expect(grams.data['result'], 1);
    final tbsp = await run(AssistantTools.convertMeasurement, {
      'amount': 1,
      'from': 'tbsp.',
      'to': 'ml',
    });
    expect(tbsp.data['result'], 15);
    final brown = await run(AssistantTools.convertMeasurement, {
      'amount': 1,
      'from': 'cup',
      'to': 'grams',
      'ingredient': 'brown sugar',
    });
    expect(brown.data['result'], closeTo(240 * 0.8, 0.01));
    final white = await run(AssistantTools.convertMeasurement, {
      'amount': 1,
      'from': 'cup',
      'to': 'grams',
      'ingredient': 'sugar',
    });
    expect(white.data['result'], closeTo(240 * 0.85, 0.01));
  });

  test(
    'the snapshot names recipes by id, the list and the preferences',
    () async {
      await run(AssistantTools.addGroceryItems, {
        'items': [
          {'name': 'Milk'},
        ],
      });
      final s = await dispatcher.snapshot();
      expect(s, contains('r1: Creamy Tuscan Salmon'));
      expect(s, contains('Milk'));
      expect(s, contains('shopping day: friday'));
    },
  );

  group('pass 6: view-only, caps and gates', () {
    tearDown(() => FeaturesFlags.overrides = null);

    GroceryListEntity viewerList(int n) => GroceryListEntity(
      id: 'shared',
      name: 'Shared',
      items: [
        for (var i = 0; i < n; i++)
          GroceryItemEntity(
            id: 's$i',
            name: 'Thing $i',
            unit: MeasurementUnit.unit,
            sources: const [],
            category: kDefaultGroceryCategory,
          ),
      ],
      createdAt: DateTime(2026),
      collabId: 'c1',
      collabRole: CollabRole.viewer,
    );

    test('every grocery write refuses a view-only list', () async {
      groceries.store['shared'] = viewerList(2);
      final calls = <(String, Map<String, dynamic>)>[
        (
          AssistantTools.addGroceryItems,
          {
            'list_id': 'shared',
            'items': [
              {'name': 'Milk'},
            ],
          },
        ),
        (
          AssistantTools.setGroceryItemChecked,
          {
            'list_id': 'shared',
            'items': ['Thing 0'],
          },
        ),
        (
          AssistantTools.removeGroceryItems,
          {
            'list_id': 'shared',
            'items': ['Thing 0'],
          },
        ),
        (AssistantTools.clearCheckedItems, {'list_id': 'shared'}),
      ];
      for (final (tool, args) in calls) {
        final r = await run(tool, args);
        expect(r.data['error'], 'read_only', reason: tool);
      }
      expect(await dispatcher.toggleGroceryItem('shared', 's0'), isNull);
      final stored = groceries.store['shared']!;
      expect(stored.items.length, 2);
      expect(stored.items.any((i) => i.isChecked), isFalse);
    });

    test('plan writes refuse a view-only plan and never pick one', () async {
      plans.store['view'] = MealPlanEntity(
        id: 'view',
        name: 'Shared week',
        meals: const [],
        // Newest, so it used to be picked when no plan_id was given.
        createdAt: DateTime(2026, 6),
        collabId: 'c2',
        collabRole: CollabRole.viewer,
      );
      final named = await run(AssistantTools.planMeal, {
        'plan_id': 'view',
        'weekday': 'sunday',
        'meal': 'Dinner',
        'free_text': 'Soup',
      });
      expect(named.data['error'], 'read_only');
      final removed = await run(AssistantTools.removePlannedItem, {
        'plan_id': 'view',
        'meal_id': 'm',
        'item_id': 'i',
      });
      expect(removed.data['error'], 'read_only');

      final unnamed = await run(AssistantTools.planMeal, {
        'weekday': 'sunday',
        'meal': 'Dinner',
        'free_text': 'Soup',
      });
      expect(unnamed.data['ok'], true);
      expect(unnamed.data['plan_id'], isNot('view'));
      expect(plans.store['view']!.meals, isEmpty);
    });

    test('grocery results are capped for the model, the card is not', () async {
      groceries.store['big'] = GroceryListEntity(
        id: 'big',
        name: 'Big',
        items: viewerList(400).items,
        createdAt: DateTime(2026),
      );
      final r = await run(AssistantTools.getGroceryList, {'list_id': 'big'});
      expect(
        (r.data['items'] as List).length,
        AssistantDispatcher.scopedGroceryItemCap,
      );
      expect(r.data['total_items'], 400);
      expect(r.data['more_items_not_listed'], 250);
      expect((r.card! as GroceryCard).items.length, 400);
    });

    test('a hidden cook mode starts no session and no timer', () async {
      FeaturesFlags.overrides = {
        FeaturesFlags.cookMode: FeatureFlagValue.hidden,
      };
      final cook = await run(AssistantTools.startCookMode, {'recipe_id': 'r1'});
      expect(cook.data['error'], 'unavailable');
      final timer = await run(AssistantTools.startTimer, {
        'recipe_id': 'r1',
        'step': 2,
      });
      expect(timer.data['error'], 'unavailable');
      expect(CookSessionService().sessions, isEmpty);
    });

    test('book listings are capped and the scale is bounded', () async {
      for (var i = 0; i < 130; i++) {
        books.store['b$i'] = RecipeBookEntity(
          id: 'b$i',
          title: 'Book $i',
          recipeRefs: const [],
          createdAt: DateTime(2026),
        );
      }
      final listed = await run(AssistantTools.listBooks);
      expect(
        (listed.data['books'] as List).length,
        AssistantDispatcher.maxListedEntities,
      );
      expect(listed.data['more_books_not_listed'], 30);

      final r = await run(AssistantTools.groceryListFromRecipe, {
        'recipe_id': 'r1',
        'scale': 500,
      });
      expect(r.data['ok'], true);
      final line = groceries.store[r.data['list_id']]!.items.firstWhere(
        (i) => i.name == 'Salmon fillets',
      );
      // 4 fillets x the bound (20), not x 500.
      expect(line.totalAmount, 4 * AssistantDispatcher.maxScale);
    });
  });
}
