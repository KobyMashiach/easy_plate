import 'package:easy_plate/core/constants/app_enums.dart';
import 'package:easy_plate/core/translation/content_translation.dart';
import 'package:easy_plate/core/translation/content_translation_datasource.dart';
import 'package:easy_plate/core/translation/content_translation_service.dart';
import 'package:easy_plate/core/translation/content_variants_local_store.dart';
import 'package:easy_plate/features/grocery_list/domain/entities/grocery_item_entity.dart';
import 'package:easy_plate/features/grocery_list/domain/entities/grocery_list_entity.dart';
import 'package:easy_plate/features/grocery_list/domain/repositories/grocery_lists_repository.dart';
import 'package:easy_plate/features/meal_planner/domain/entities/meal_plan_entity.dart';
import 'package:easy_plate/features/meal_planner/domain/repositories/meal_plans_repository.dart';
import 'package:easy_plate/features/my_recipes/domain/entities/recipe_entity.dart';
import 'package:easy_plate/features/my_recipes/domain/entities/recipe_ingredient_entity.dart';
import 'package:easy_plate/features/my_recipes/domain/repositories/recipes_repository.dart';
import 'package:easy_plate/features/recipe_books/domain/entities/recipe_book_entity.dart';
import 'package:easy_plate/features/recipe_books/domain/repositories/recipe_books_repository.dart';
import 'package:flutter_test/flutter_test.dart';

RecipeEntity shakshuka({String? contentLang, int version = 0}) => RecipeEntity(
  id: 'r1',
  title: 'שקשוקה',
  ingredients: const [
    RecipeIngredientEntity(
      name: 'ביצים',
      amount: 4,
      unit: MeasurementUnit.unspecified,
    ),
    RecipeIngredientEntity(
      name: 'עגבניות',
      amount: 6,
      unit: MeasurementUnit.unspecified,
    ),
  ],
  steps: const ['מטגנים בצל', 'שוברים ביצים'],
  createdAt: DateTime(2026),
  contentLang: contentLang,
  contentVersion: version,
);

class _FakeRemote implements ContentTranslationDataSource {
  _FakeRemote({
    this.stored = const {},
    this.answer = const {},
    this.throws = false,
  });

  Map<String, TranslatedFields> stored;
  Map<String, TranslatedFields> answer;
  bool throws;

  final asked = <TranslatableItem>[];
  int reads = 0;

  @override
  Future<Map<String, TranslatedFields>> readVariants(
    String lang,
    Iterable<String> types,
  ) async {
    reads++;
    return Map.of(stored);
  }

  @override
  Future<Map<String, TranslatedFields>> translate(
    String lang,
    List<TranslatableItem> items,
  ) async {
    asked.addAll(items);
    if (throws) throw StateError('offline');
    return {
      for (final item in items)
        '${item.type}/${item.id}': ?answer['${item.type}/${item.id}'],
    };
  }

  final sourcesWritten = <String>[];

  @override
  Future<void> writeSource(String lang, TranslatableItem item) async =>
      sourcesWritten.add('$lang/${item.type}/${item.id}');

  @override
  Future<void> forget(String type, String id, Iterable<String> langs) async {}
}

class _FakeLocal extends ContentVariantsLocalStore {
  _FakeLocal([Map<String, Map<String, TranslatedFields>>? initial])
    : byLang = initial ?? {};

  final Map<String, Map<String, TranslatedFields>> byLang;

  @override
  Future<Map<String, TranslatedFields>> read(String lang) async =>
      Map.of(byLang[lang] ?? const {});

  @override
  Future<void> write(
    String lang,
    Map<String, TranslatedFields> variants,
  ) async => (byLang[lang] ??= {}).addAll(variants);
}

class _FakeRecipes implements RecipesRepository {
  _FakeRecipes(this._all);
  List<RecipeEntity> _all;
  final saved = <RecipeEntity>[];

  @override
  Future<List<RecipeEntity>> getRecipes() async => _all;

  @override
  Future<void> saveRecipe(
    RecipeEntity recipe, {
    bool stampLanguage = true,
  }) async {
    saved.add(recipe);
    _all = [
      for (final r in _all)
        if (r.id == recipe.id) recipe else r,
    ];
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeBooks implements RecipeBooksRepository {
  final saved = <RecipeBookEntity>[];
  List<RecipeBookEntity> all = const [];
  @override
  Future<List<RecipeBookEntity>> getBooks() async => all;
  @override
  Future<void> saveBook(
    RecipeBookEntity book, {
    bool stampLanguage = true,
  }) async => saved.add(book);
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakePlans implements MealPlansRepository {
  List<MealPlanEntity> all = const [];
  @override
  Future<List<MealPlanEntity>> getPlans() async => all;
  @override
  Future<void> savePlan(
    MealPlanEntity plan, {
    bool stampLanguage = true,
  }) async {}
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeLists implements GroceryListsRepository {
  final saved = <GroceryListEntity>[];
  List<GroceryListEntity> all = const [];
  @override
  Future<List<GroceryListEntity>> getLists() async => all;
  @override
  Future<void> saveList(
    GroceryListEntity list, {
    bool stampLanguage = true,
  }) async => saved.add(list);
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ContentTranslationService _serviceWith(
  _FakeRemote remote, {
  _FakeLocal? local,
  _FakeRecipes? recipes,
  _FakeBooks? books,
  _FakePlans? plans,
  _FakeLists? lists,
}) => ContentTranslationService(
  remote: remote,
  local: local ?? _FakeLocal(),
  recipes: recipes ?? _FakeRecipes(const []),
  books: books ?? _FakeBooks(),
  plans: plans ?? _FakePlans(),
  lists: lists ?? _FakeLists(),
);

void main() {
  const english = {
    'title': 'Shakshuka',
    'ingredients': ['Eggs', 'Tomatoes'],
    'steps': ['Fry the onion', 'Crack in the eggs'],
  };

  test('a recipe already in the target language is left alone', () async {
    final remote = _FakeRemote();
    final recipes = _FakeRecipes([shakshuka(contentLang: 'en')]);
    final outcome = await _serviceWith(
      remote,
      recipes: recipes,
    ).switchTo(AppLanguage.english);

    expect(outcome.didNothing, isTrue);
    expect(remote.asked, isEmpty);
    expect(remote.reads, 0, reason: 'nothing to do means not even a read');
    expect(recipes.saved, isEmpty);
  });

  test(
    'the script decides for records saved before languages were recorded',
    () async {
      final remote = _FakeRemote(
        answer: {
          'recipe/r1': const TranslatedFields({...english, 'sourceHash': 'x'}),
        },
      );
      final recipes = _FakeRecipes([shakshuka()]);
      await _serviceWith(
        remote,
        recipes: recipes,
      ).switchTo(AppLanguage.english);
      expect(remote.asked.single.id, 'r1');

      // The same record, asked for Hebrew, is recognised as already Hebrew.
      final again = _FakeRemote();
      await _serviceWith(
        again,
        recipes: _FakeRecipes([shakshuka()]),
      ).switchTo(AppLanguage.hebrew);
      expect(again.asked, isEmpty);
    },
  );

  test('translated text replaces the words and keeps the numbers', () async {
    final remote = _FakeRemote(
      answer: {
        'recipe/r1': const TranslatedFields({...english, 'sourceHash': 'x'}),
      },
    );
    final recipes = _FakeRecipes([shakshuka()]);
    final outcome = await _serviceWith(
      remote,
      recipes: recipes,
    ).switchTo(AppLanguage.english);

    final saved = recipes.saved.single;
    expect(saved.title, 'Shakshuka');
    expect(saved.steps, ['Fry the onion', 'Crack in the eggs']);
    expect([for (final i in saved.ingredients) i.name], ['Eggs', 'Tomatoes']);
    expect([for (final i in saved.ingredients) i.amount], [4, 6]);
    expect(saved.contentLang, 'en');
    expect(outcome.translated, 1);
    expect(outcome.reused, 0);
  });

  test('a stored translation of the same text costs no model call', () async {
    final recipe = shakshuka();
    final remote = _FakeRemote(
      stored: {
        // Made from the version the recipe still stands at.
        'recipe/r1': TranslatedFields({
          ...english,
          'version': recipe.contentVersion,
        }),
      },
    );
    final recipes = _FakeRecipes([recipe]);
    final outcome = await _serviceWith(
      remote,
      recipes: recipes,
    ).switchTo(AppLanguage.english);

    expect(remote.asked, isEmpty);
    expect(recipes.saved.single.title, 'Shakshuka');
    expect(outcome.reused, 1);
    expect(outcome.translated, 0);
  });

  test(
    'a stored translation of text that was since edited is made again',
    () async {
      // Made when the recipe stood at version 0. It has been edited since,
      // so the stored copy is dropped and the model asked again.
      const stale = TranslatedFields({
        'title': 'Shakshuka',
        'ingredients': ['Eggs', 'Tomatoes'],
        'steps': ['Fry the onion', 'Crack in the eggs'],
        'version': 0,
      });
      const spicy = TranslatedFields({
        'title': 'Spicy Shakshuka',
        'ingredients': ['Eggs', 'Tomatoes'],
        'steps': ['Fry the onion', 'Crack in the eggs'],
        'version': 0,
      });
      final remote = _FakeRemote(
        stored: {'recipe/r1': stale},
        answer: {'recipe/r1': spicy},
      );
      final recipes = _FakeRecipes([shakshuka(version: 1)]);
      await _serviceWith(
        remote,
        recipes: recipes,
      ).switchTo(AppLanguage.english);

      expect(remote.asked.single.id, 'r1');
      expect(recipes.saved.single.title, 'Spicy Shakshuka');
    },
  );

  test(
    'a list that comes back the wrong length is refused, not spliced',
    () async {
      final remote = _FakeRemote(
        answer: {
          'recipe/r1': const TranslatedFields({
            'title': 'Shakshuka',
            'ingredients': ['Eggs'],
            'steps': ['Fry the onion', 'Crack in the eggs'],
            'version': 0,
          }),
        },
      );
      final recipes = _FakeRecipes([shakshuka()]);
      await _serviceWith(
        remote,
        recipes: recipes,
      ).switchTo(AppLanguage.english);

      final saved = recipes.saved.single;
      expect([for (final i in saved.ingredients) i.name], ['ביצים', 'עגבניות']);
      expect(saved.steps, ['Fry the onion', 'Crack in the eggs']);
    },
  );

  test('a failed call leaves the content alone and says how much', () async {
    final remote = _FakeRemote(throws: true);
    final recipes = _FakeRecipes([shakshuka()]);
    final outcome = await _serviceWith(
      remote,
      recipes: recipes,
    ).switchTo(AppLanguage.english);

    expect(recipes.saved, isEmpty);
    expect(outcome.failed, 1);
    expect(outcome.total, 0);
  });

  test('shopping lists keep their quantities and their checks', () async {
    final list = GroceryListEntity(
      id: 'g1',
      name: 'קניות',
      items: const [
        GroceryItemEntity(
          id: 'i1',
          name: 'חלב',
          unit: MeasurementUnit.liter,
          sources: [],
          category: 'dairy',
          isChecked: true,
        ),
      ],
      createdAt: DateTime(2026),
    );
    final lists = _FakeLists()..all = [list];
    final remote = _FakeRemote(
      answer: {
        'groceryList/g1': const TranslatedFields({
          'name': 'Groceries',
          'items': ['Milk'],
          'version': 0,
        }),
      },
    );
    await _serviceWith(remote, lists: lists).switchTo(AppLanguage.english);

    final saved = lists.saved.single;
    expect(saved.name, 'Groceries');
    expect(saved.items.single.name, 'Milk');
    expect(saved.items.single.isChecked, isTrue);
    expect(saved.items.single.unit, MeasurementUnit.liter);
    expect(saved.contentLang, 'en');
  });

  test(
    'translating files the original and does not move the version',
    () async {
      final remote = _FakeRemote(
        answer: {
          'recipe/r1': const TranslatedFields({...english, 'version': 0}),
        },
      );
      final recipes = _FakeRecipes([shakshuka()]);
      await _serviceWith(
        remote,
        recipes: recipes,
      ).switchTo(AppLanguage.english);

      // The Hebrew the recipe was written in is now in Firebase, so coming
      // back to Hebrew is a read rather than a translation.
      expect(remote.sourcesWritten, ['he/recipe/r1']);
      // The version is what a stored translation is matched on; a translation
      // is not an edit, so it stays put.
      expect(recipes.saved.single.contentVersion, 0);
      expect(recipes.saved.single.contentLang, 'en');
    },
  );

  test(
    'switching back to the language it was written in reads, never translates',
    () async {
      // What the previous test filed: the Hebrew original, at version 0.
      final remote = _FakeRemote(
        stored: {
          'recipe/r1': const TranslatedFields({
            'title': 'שקשוקה',
            'ingredients': ['ביצים', 'עגבניות'],
            'steps': ['מטגנים בצל', 'שוברים ביצים'],
            'version': 0,
          }),
        },
      );
      // The recipe now holds English, as it would after a switch.
      final recipes = _FakeRecipes([
        RecipeEntity(
          id: 'r1',
          title: 'Shakshuka',
          ingredients: const [
            RecipeIngredientEntity(
              name: 'Eggs',
              amount: 4,
              unit: MeasurementUnit.unspecified,
            ),
            RecipeIngredientEntity(
              name: 'Tomatoes',
              amount: 6,
              unit: MeasurementUnit.unspecified,
            ),
          ],
          steps: const ['Fry the onion', 'Crack in the eggs'],
          createdAt: DateTime(2026),
          contentLang: 'en',
        ),
      ]);
      final outcome = await _serviceWith(
        remote,
        recipes: recipes,
      ).switchTo(AppLanguage.hebrew);

      expect(
        remote.asked,
        isEmpty,
        reason: 'the Hebrew is already in Firebase',
      );
      expect(recipes.saved.single.title, 'שקשוקה');
      expect(recipes.saved.single.contentLang, 'he');
      expect(outcome.reused, 1);
      expect(outcome.translated, 0);
    },
  );

  test('a language already on the device needs no network at all', () async {
    final remote = _FakeRemote();
    final local = _FakeLocal({
      'en': {
        'recipe/r1': const TranslatedFields({...english, 'version': 0}),
      },
    });
    final service = _serviceWith(
      remote,
      local: local,
      recipes: _FakeRecipes([shakshuka()]),
    );

    expect(await service.isLocal(AppLanguage.english), isTrue);
    final outcome = await service.switchTo(AppLanguage.english);

    expect(remote.reads, 0, reason: 'Firebase is not even read');
    expect(remote.asked, isEmpty, reason: 'and the model is not asked');
    expect(outcome.reused, 1);
  });

  test('a language the device lacks is not called local', () async {
    final service = _serviceWith(
      _FakeRemote(),
      recipes: _FakeRecipes([shakshuka()]),
    );
    expect(await service.isLocal(AppLanguage.english), isFalse);
  });

  test('what came from Firebase is kept on the device for next time', () async {
    final remote = _FakeRemote(
      stored: {
        'recipe/r1': const TranslatedFields({...english, 'version': 0}),
      },
    );
    final local = _FakeLocal();
    await _serviceWith(
      remote,
      local: local,
      recipes: _FakeRecipes([shakshuka()]),
    ).switchTo(AppLanguage.english);

    expect(remote.asked, isEmpty);
    expect(local.byLang['en']?['recipe/r1']?.text('title'), 'Shakshuka');
  });

  test(
    'a fresh translation and the original both land on the device',
    () async {
      final remote = _FakeRemote(
        answer: {
          'recipe/r1': const TranslatedFields({...english, 'version': 0}),
        },
      );
      final local = _FakeLocal();
      await _serviceWith(
        remote,
        local: local,
        recipes: _FakeRecipes([shakshuka()]),
      ).switchTo(AppLanguage.english);

      expect(local.byLang['en']?['recipe/r1']?.text('title'), 'Shakshuka');
      // So coming back to Hebrew is instant as well.
      expect(local.byLang['he']?['recipe/r1']?.text('title'), 'שקשוקה');
    },
  );

  test(
    'the language just left is on the device even when Firebase supplied the new one',
    () async {
      final remote = _FakeRemote(
        stored: {
          'recipe/r1': const TranslatedFields({...english, 'version': 0}),
        },
      );
      final local = _FakeLocal();
      await _serviceWith(
        remote,
        local: local,
        recipes: _FakeRecipes([shakshuka()]),
      ).switchTo(AppLanguage.english);

      expect(remote.asked, isEmpty);
      expect(local.byLang['he']?['recipe/r1']?.text('title'), 'שקשוקה');
      // Only a record the model had to translate is filed in Firebase again;
      // this one was already there.
      expect(remote.sourcesWritten, isEmpty);
    },
  );
}
