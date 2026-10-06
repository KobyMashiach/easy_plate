import 'package:easy_plate/core/constants/app_enums.dart';
import 'package:easy_plate/core/monetization/entitlement_service.dart';
import 'package:easy_plate/core/services/cook_session_service.dart';
import 'package:easy_plate/core/utils/i18n/strings.g.dart';
import 'package:easy_plate/features/assistant/domain/assistant_dispatcher.dart';
import 'package:easy_plate/features/assistant/domain/assistant_models.dart';
import 'package:easy_plate/features/assistant/domain/assistant_tools.dart';
import 'package:easy_plate/features/assistant/domain/assistant_ui_bridge.dart';
import 'package:easy_plate/features/grocery_list/data/datasources/active_grocery_list_store.dart';
import 'package:easy_plate/features/grocery_list/domain/entities/grocery_list_entity.dart';
import 'package:easy_plate/features/grocery_list/domain/repositories/grocery_lists_repository.dart';
import 'package:easy_plate/features/meal_planner/domain/entities/meal_plan_entity.dart';
import 'package:easy_plate/features/meal_planner/domain/repositories/meal_plans_repository.dart';
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

  test('an unknown tool is refused, not thrown', () async {
    final r = await run('no_such_tool');
    expect(r.data['ok'], false);
    expect(r.data['error'], 'unknown_tool');
  });

  group('groceries', () {
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
}
