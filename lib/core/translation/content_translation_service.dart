import 'package:flutter/foundation.dart';

import '../../features/grocery_list/domain/entities/grocery_item_entity.dart';
import '../../features/grocery_list/domain/entities/grocery_list_entity.dart';
import '../../features/grocery_list/domain/repositories/grocery_lists_repository.dart';
import '../../features/meal_planner/domain/entities/meal_entity.dart';
import '../../features/meal_planner/domain/entities/meal_item_entity.dart';
import '../../features/meal_planner/domain/entities/meal_plan_entity.dart';
import '../../features/meal_planner/domain/repositories/meal_plans_repository.dart';
import '../../features/my_recipes/domain/entities/recipe_entity.dart';
import '../../features/my_recipes/domain/entities/recipe_ingredient_entity.dart';
import '../../features/my_recipes/domain/repositories/recipes_repository.dart';
import '../../features/recipe_books/domain/entities/recipe_book_entity.dart';
import '../../features/recipe_books/domain/repositories/recipe_books_repository.dart';
import '../constants/app_enums.dart';
import 'content_changes.dart';
import 'content_translation.dart';
import 'content_translation_datasource.dart';
import 'content_variants_local_store.dart';

/// What one pass did, for the message shown when it finishes.
class TranslationOutcome {
  final int translated;
  final int reused;
  final int failed;

  const TranslationOutcome({
    this.translated = 0,
    this.reused = 0,
    this.failed = 0,
  });

  int get total => translated + reused;
  bool get didNothing => total == 0 && failed == 0;

  TranslationOutcome operator +(TranslationOutcome other) => TranslationOutcome(
    translated: translated + other.translated,
    reused: reused + other.reused,
    failed: failed + other.failed,
  );
}

/// Rewrites the account's own recipes, books, plans and shopping lists into
/// the language the app was just switched to.
///
/// The record itself always holds the text in one language and says which
/// ([RecipeEntity.contentLang] and friends). Switching asks the account's own
/// language folder first, and the model only for what is missing there, so
/// the second switch to a language — and every other device — is free. Going
/// back to the language something was written in never calls the model: that
/// text is what the folder holds.
///
/// Content shared with other people is translated the same way, but only in
/// this account's copy: the translations live under `users/{uid}`, and the
/// shared document keeps whatever its author wrote.
class ContentTranslationService {
  static const recipeType = 'recipe';
  static const bookType = 'book';
  static const planType = 'mealPlan';
  static const listType = 'groceryList';
  static const types = [recipeType, bookType, planType, listType];

  final ContentTranslationDataSource remote;

  /// The same translations on the device. Read first, so switching to a
  /// language the account has been in before needs no network at all.
  final ContentVariantsLocalStore local;
  final RecipesRepository recipes;
  final RecipeBooksRepository books;
  final MealPlansRepository plans;
  final GroceryListsRepository lists;

  ContentTranslationService({
    required this.remote,
    ContentVariantsLocalStore? local,
    required this.recipes,
    required this.books,
    required this.plans,
    required this.lists,
  }) : local = local ?? ContentVariantsLocalStore();

  /// Translates everything that is not already in [target].
  ///
  /// [onProgress] reports records done out of records to do, for the dialog
  /// that stays up while this runs.
  Future<TranslationOutcome> switchTo(
    AppLanguage target, {
    void Function(int done, int total)? onProgress,
  }) async {
    final code = target.code;
    final loaded = await Future.wait([
      recipes.getRecipes(),
      books.getBooks(),
      plans.getPlans(),
      lists.getLists(),
    ]);
    final allRecipes = (loaded[0] as List<RecipeEntity>)
        .where((r) => _needs(r.contentLang, r.title, target))
        .toList();
    final allBooks = (loaded[1] as List<RecipeBookEntity>)
        .where((b) => _needs(b.contentLang, b.title, target))
        .toList();
    final allPlans = (loaded[2] as List<MealPlanEntity>)
        .where((p) => _needs(p.contentLang, p.name, target))
        .toList();
    final allLists = (loaded[3] as List<GroceryListEntity>)
        .where((l) => _needs(l.contentLang, l.name, target))
        .toList();

    final total =
        allRecipes.length + allBooks.length + allPlans.length + allLists.length;
    if (total == 0) return const TranslationOutcome();

    final items = [
      ...allRecipes.map(_recipeItem),
      ...allBooks.map(_bookItem),
      ...allPlans.map(_planItem),
      ...allLists.map(_listItem),
    ];

    // Cheapest first: the device, then the account's folder in Firebase, and
    // the model only for what neither has. Coming back to a language this
    // account has been in before stops at the first step.
    final known = await local.read(code);
    final stale = [
      for (final item in items)
        if (!_matches(known, item)) item,
    ];
    if (stale.isNotEmpty) {
      final fromCloud = await remote.readVariants(code, types);
      final fresh = <String, TranslatedFields>{};
      for (final item in stale) {
        final key = '${item.type}/${item.id}';
        final fields = fromCloud[key];
        if (fields != null && fields.version == item.version) {
          fresh[key] = fields;
        }
      }
      known.addAll(fresh);
      await local.write(code, fresh);
    }

    // A stored translation counts while the record still stands at the
    // version it was made from. Translating does not move that number, so
    // the second switch to a language — and every other device — is free.
    bool usable(TranslatableItem item) {
      if (_matches(known, item)) return true;
      known.remove('${item.type}/${item.id}');
      return false;
    }

    final wanted = [
      for (final item in items)
        if (!usable(item)) item,
    ];

    // Before anything is translated away, the record's own text is filed
    // under its own language. Coming back to it then costs one read.
    // Every record's current words are kept on the device under their own
    // language before they are replaced — so going back to the language the
    // app was just in is always instant, even when nothing needed the model.
    final originals = <String, Map<String, TranslatedFields>>{};
    for (final item in items) {
      final source = _sourceLanguageOf(
        item,
        allRecipes,
        allBooks,
        allPlans,
        allLists,
      );
      if (source == null) continue;
      (originals[source] ??= {})['${item.type}/${item.id}'] = TranslatedFields({
        ...item.fields,
        'version': item.version,
      });
    }
    await Future.wait([
      for (final item in wanted)
        if (_sourceLanguageOf(item, allRecipes, allBooks, allPlans, allLists)
            case final source?)
          remote.writeSource(source, item),
      for (final entry in originals.entries)
        local.write(entry.key, entry.value),
    ]);

    var failed = 0;
    if (wanted.isNotEmpty) {
      try {
        final made = await remote.translate(code, wanted);
        known.addAll(made);
        await local.write(code, {
          for (final item in wanted)
            if (made['${item.type}/${item.id}'] case final fields?)
              '${item.type}/${item.id}': TranslatedFields({
                ...fields.fields,
                'version': item.version,
              }),
        });
      } catch (e) {
        // Whatever the folder already held is still applied below; only the
        // records that needed the model are left in their own language.
        debugPrint('Translating into $code failed: $e');
        failed = wanted.length;
      }
    }

    var done = 0;
    var translated = 0;
    var reused = 0;
    void step(bool fromModel) {
      done++;
      if (fromModel) {
        translated++;
      } else {
        reused++;
      }
      onProgress?.call(done, total);
    }

    for (final recipe in allRecipes) {
      final fields = known['$recipeType/${recipe.id}'];
      if (fields == null) continue;
      await recipes.saveRecipe(
        _applyRecipe(recipe, fields, target),
        stampLanguage: false,
      );
      step(wanted.any((i) => i.id == recipe.id && i.type == recipeType));
    }
    for (final book in allBooks) {
      final fields = known['$bookType/${book.id}'];
      if (fields == null) continue;
      await books.saveBook(
        book.copyWith(
          title: fields.text('title') ?? book.title,
          contentLang: code,
        ),
        stampLanguage: false,
      );
      step(wanted.any((i) => i.id == book.id && i.type == bookType));
    }
    for (final plan in allPlans) {
      final fields = known['$planType/${plan.id}'];
      if (fields == null) continue;
      await plans.savePlan(
        _applyPlan(plan, fields, target),
        stampLanguage: false,
      );
      step(wanted.any((i) => i.id == plan.id && i.type == planType));
    }
    for (final list in allLists) {
      final fields = known['$listType/${list.id}'];
      if (fields == null) continue;
      await lists.saveList(
        _applyList(list, fields, target),
        stampLanguage: false,
      );
      step(wanted.any((i) => i.id == list.id && i.type == listType));
    }

    // The library, the planner and the shopping list hold their own copy.
    if (translated + reused > 0) ContentChanges.instance.notify();
    return TranslationOutcome(
      translated: translated,
      reused: reused,
      failed: failed,
    );
  }

  static bool _matches(
    Map<String, TranslatedFields> known,
    TranslatableItem item,
  ) => known['${item.type}/${item.id}']?.version == item.version;

  /// Whether switching to [target] can be done from the device alone: every
  /// record that needs another language has it stored locally at its current
  /// version. The screen skips the loading card when it can.
  Future<bool> isLocal(AppLanguage target) async {
    final loaded = await Future.wait([
      recipes.getRecipes(),
      books.getBooks(),
      plans.getPlans(),
      lists.getLists(),
    ]);
    final items = [
      for (final r in loaded[0] as List<RecipeEntity>)
        if (_needs(r.contentLang, r.title, target)) _recipeItem(r),
      for (final b in loaded[1] as List<RecipeBookEntity>)
        if (_needs(b.contentLang, b.title, target)) _bookItem(b),
      for (final p in loaded[2] as List<MealPlanEntity>)
        if (_needs(p.contentLang, p.name, target)) _planItem(p),
      for (final l in loaded[3] as List<GroceryListEntity>)
        if (_needs(l.contentLang, l.name, target)) _listItem(l),
    ];
    if (items.isEmpty) return true;
    final known = await local.read(target.code);
    return items.every((item) => _matches(known, item));
  }

  /// Which language a record's own text is in, for filing the original.
  static String? _sourceLanguageOf(
    TranslatableItem item,
    List<RecipeEntity> recipes,
    List<RecipeBookEntity> books,
    List<MealPlanEntity> plans,
    List<GroceryListEntity> lists,
  ) {
    String? langOf(String? contentLang, String sample) =>
        (AppLanguageCode.fromCode(contentLang) ??
                guessLanguage(sample, fallback: AppLanguage.english))
            .code;
    return switch (item.type) {
      recipeType =>
        recipes
            .where((r) => r.id == item.id)
            .map((r) => langOf(r.contentLang, r.title))
            .firstOrNull,
      bookType =>
        books
            .where((b) => b.id == item.id)
            .map((b) => langOf(b.contentLang, b.title))
            .firstOrNull,
      planType =>
        plans
            .where((p) => p.id == item.id)
            .map((p) => langOf(p.contentLang, p.name))
            .firstOrNull,
      listType =>
        lists
            .where((l) => l.id == item.id)
            .map((l) => langOf(l.contentLang, l.name))
            .firstOrNull,
      _ => null,
    };
  }

  /// A record is left alone when its text is already in the target language.
  /// Records saved before this existed carry no language; their script says
  /// enough (see [guessLanguage]).
  static bool _needs(String? contentLang, String sample, AppLanguage target) {
    final current =
        AppLanguageCode.fromCode(contentLang) ??
        guessLanguage(sample, fallback: target);
    return current != target;
  }

  // -- what goes to the model -------------------------------------------

  static TranslatableItem _recipeItem(RecipeEntity r) => TranslatableItem(
    type: recipeType,
    id: r.id,
    version: r.contentVersion,
    fields: {
      'title': r.title,
      'ingredients': [for (final i in r.ingredients) i.name],
      'steps': r.steps,
    },
  );

  static TranslatableItem _bookItem(RecipeBookEntity b) => TranslatableItem(
    type: bookType,
    id: b.id,
    version: b.contentVersion,
    fields: {'title': b.title},
  );

  static TranslatableItem _planItem(MealPlanEntity p) => TranslatableItem(
    type: planType,
    id: p.id,
    version: p.contentVersion,
    fields: {
      'name': p.name,
      'meals': [for (final m in p.meals) m.name],
      'items': _planFreeText(p),
    },
  );

  static TranslatableItem _listItem(GroceryListEntity l) => TranslatableItem(
    type: listType,
    id: l.id,
    version: l.contentVersion,
    fields: {
      'name': l.name,
      'items': [for (final i in l.items) i.name],
    },
  );

  /// The typed-in lines of a plan, flattened in the order the meals hold
  /// them, so the answer can be laid back over them by position.
  static List<String> _planFreeText(MealPlanEntity plan) => [
    for (final meal in plan.meals)
      for (final item in meal.items)
        if (item.freeText?.trim().isNotEmpty ?? false) item.freeText!,
  ];

  // -- what comes back ---------------------------------------------------

  static RecipeEntity _applyRecipe(
    RecipeEntity recipe,
    TranslatedFields fields,
    AppLanguage target,
  ) {
    final names = fields.listOfLength('ingredients', recipe.ingredients.length);
    return recipe.copyWith(
      title: fields.text('title') ?? recipe.title,
      ingredients: names == null
          ? recipe.ingredients
          : [
              for (final (index, ingredient) in recipe.ingredients.indexed)
                RecipeIngredientEntity(
                  name: names[index],
                  amount: ingredient.amount,
                  unit: ingredient.unit,
                ),
            ],
      steps: fields.listOfLength('steps', recipe.steps.length) ?? recipe.steps,
      contentLang: target.code,
    );
  }

  static MealPlanEntity _applyPlan(
    MealPlanEntity plan,
    TranslatedFields fields,
    AppLanguage target,
  ) {
    final mealNames = fields.listOfLength('meals', plan.meals.length);
    final freeText = fields.listOfLength('items', _planFreeText(plan).length);
    var cursor = 0;
    return plan.copyWith(
      name: fields.text('name') ?? plan.name,
      meals: [
        for (final (index, meal) in plan.meals.indexed)
          MealEntity(
            id: meal.id,
            weekday: meal.weekday,
            name: mealNames == null ? meal.name : mealNames[index],
            order: meal.order,
            items: [
              for (final item in meal.items)
                if (item.freeText case final text? when text.trim().isNotEmpty)
                  MealItemEntity(
                    id: item.id,
                    recipeId: item.recipeId,
                    freeText: freeText == null ? text : freeText[cursor++],
                    ingredients: item.ingredients,
                  )
                else
                  item,
            ],
          ),
      ],
      contentLang: target.code,
    );
  }

  static GroceryListEntity _applyList(
    GroceryListEntity list,
    TranslatedFields fields,
    AppLanguage target,
  ) {
    final names = fields.listOfLength('items', list.items.length);
    return list.copyWith(
      name: fields.text('name') ?? list.name,
      items: names == null
          ? list.items
          : [
              for (final (index, item) in list.items.indexed)
                GroceryItemEntity(
                  id: item.id,
                  name: names[index],
                  unit: item.unit,
                  sources: item.sources,
                  category: item.category,
                  isChecked: item.isChecked,
                  isAdHoc: item.isAdHoc,
                ),
            ],
      contentLang: target.code,
    );
  }
}
