import 'package:uuid/uuid.dart';

import '../../../core/constants/app_enums.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/monetization/monetization_config.dart';
import '../../../core/services/auth_session_service.dart';
import '../../../core/services/cook_session_service.dart';
import '../../../core/utils/i18n/strings.g.dart';
import '../../grocery_list/data/datasources/active_grocery_list_store.dart';
import '../../grocery_list/domain/entities/grocery_item_entity.dart';
import '../../grocery_list/domain/entities/grocery_item_source_entity.dart';
import '../../grocery_list/domain/entities/grocery_list_entity.dart';
import '../../grocery_list/domain/repositories/grocery_lists_repository.dart';
import '../../grocery_list/domain/usecases/create_recipe_grocery_list_usecase.dart';
import '../../meal_planner/domain/entities/meal_entity.dart';
import '../../meal_planner/domain/entities/meal_item_entity.dart';
import '../../meal_planner/domain/entities/meal_plan_entity.dart';
import '../../meal_planner/domain/repositories/meal_plans_repository.dart';
import '../../my_recipes/domain/entities/recipe_entity.dart';
import '../../my_recipes/domain/entities/recipe_ingredient_entity.dart';
import '../../my_recipes/domain/repositories/recipes_repository.dart';
import '../../recipe_books/domain/entities/book_recipe_ref_entity.dart';
import '../../recipe_books/domain/entities/recipe_book_entity.dart';
import '../../recipe_books/domain/repositories/recipe_books_repository.dart';
import '../../recipe_ingestion/domain/repositories/recipe_ingestion_repository.dart';
import '../../user_profile/domain/entities/user_preferences_entity.dart';
import '../../user_profile/domain/repositories/user_preferences_repository.dart';
import 'assistant_models.dart';
import 'assistant_tools.dart';
import 'assistant_ui_bridge.dart';
import 'assistant_scope.dart';

/// Runs the model's function calls against the app's own repositories and
/// use cases. Every tool returns a [ToolResult] the model can read, and most
/// also return a card the chat renders. Nothing here is AI: the one AI tool
/// (`import_recipe`) delegates to the ingestion repository like the add
/// screen does, allowance gate included.
class AssistantDispatcher {
  final RecipesRepository recipes;
  final RecipeBooksRepository books;
  final MealPlansRepository plans;
  final GroceryListsRepository groceries;
  final ActiveGroceryListStore activeList;
  final RecipeIngestionRepository ingestion;
  final UserPreferencesRepository preferences;
  final CookSessionService cooking;
  final AssistantUiBridge ui;

  static const _uuid = Uuid();

  AssistantDispatcher({
    required this.recipes,
    required this.books,
    required this.plans,
    required this.groceries,
    required this.activeList,
    required this.ingestion,
    required this.preferences,
    required this.cooking,
    required this.ui,
  });

  Future<ToolResult> execute(ToolCall call) async {
    try {
      return await _run(call.name, call.arguments);
    } on AppException catch (e) {
      return ToolResult.error(e.type.name, e.message);
    } catch (e) {
      return ToolResult.error('failed', e.toString());
    }
  }

  Future<ToolResult> _run(String name, Map<String, dynamic> a) {
    switch (name) {
      case AssistantTools.searchRecipes:
        return _searchRecipes(a);
      case AssistantTools.getRecipe:
        return _getRecipe(a);
      case AssistantTools.createRecipe:
        return _createRecipe(a);
      case AssistantTools.updateRecipe:
        return _updateRecipe(a);
      case AssistantTools.deleteRecipe:
        return _deleteRecipe(a);
      case AssistantTools.importRecipe:
        return _importRecipe(a);
      case AssistantTools.searchWebRecipes:
        return _searchWebRecipes(a);
      case AssistantTools.openRecipe:
        return _openRecipe(a);
      case AssistantTools.listBooks:
        return _listBooks();
      case AssistantTools.createBook:
        return _createBook(a);
      case AssistantTools.addRecipeToBook:
        return _addRecipeToBook(a);
      case AssistantTools.listMealPlans:
        return _listMealPlans(a);
      case AssistantTools.createMealPlan:
        return _createMealPlan(a);
      case AssistantTools.planMeal:
        return _planMeal(a);
      case AssistantTools.removePlannedItem:
        return _removePlannedItem(a);
      case AssistantTools.listGroceryLists:
        return _listGroceryLists();
      case AssistantTools.createGroceryList:
        return _createGroceryList(a);
      case AssistantTools.getGroceryList:
        return _getGroceryList(a);
      case AssistantTools.addGroceryItems:
        return _addGroceryItems(a);
      case AssistantTools.setGroceryItemChecked:
        return _setGroceryItemChecked(a);
      case AssistantTools.removeGroceryItems:
        return _removeGroceryItems(a);
      case AssistantTools.clearCheckedItems:
        return _clearCheckedItems(a);
      case AssistantTools.groceryListFromRecipe:
        return _groceryListFromRecipe(a);
      case AssistantTools.startCookMode:
        return _startCookMode(a);
      case AssistantTools.startTimer:
        return _startTimer(a);
      case AssistantTools.cookingStatus:
        return _cookingStatus();
      case AssistantTools.getPreferences:
        return _getPreferences();
      case AssistantTools.setShoppingDay:
        return _setShoppingDay(a);
      case AssistantTools.setDietaryPreferences:
        return _setDietaryPreferences(a);
      case AssistantTools.premiumStatus:
        return _premiumStatus();
      case AssistantTools.convertMeasurement:
        return Future.value(_convertMeasurement(a));
      case AssistantTools.estimateNutrition:
        return _estimateNutrition(a);
      case AssistantTools.openScreen:
        return _openScreen(a);
    }
    return Future.value(
      ToolResult.error('unknown_tool', 'No tool named $name'),
    );
  }

  // ---- Shared helpers ------------------------------------------------------

  /// A recipe by id, or by the closest title when the model passed a name.
  Future<RecipeEntity?> _findRecipe(String? idOrTitle) async {
    if (idOrTitle == null || idOrTitle.trim().isEmpty) return null;
    final byId = await recipes.getRecipeById(idOrTitle);
    if (byId != null) return byId;
    final needle = idOrTitle.trim().toLowerCase();
    final all = await recipes.getRecipes();
    for (final r in all) {
      if (r.title.toLowerCase() == needle) return r;
    }
    for (final r in all) {
      if (r.title.toLowerCase().contains(needle)) return r;
    }
    return null;
  }

  ToolResult _notFound(String what, String? name) =>
      ToolResult.error('not_found', '$what "${name ?? ''}" was not found');

  static Map<String, dynamic> _recipeSummary(RecipeEntity r) => {
    'id': r.id,
    'title': r.title,
    'servings': r.servings,
    'prep_minutes': r.prepTimeMinutes,
    'cook_minutes': r.cookTimeMinutes,
    'dietary_tags': r.dietaryTags.map((d) => d.name).toList(),
    'ingredient_count': r.ingredients.length,
    'step_count': r.steps.length,
  };

  static Map<String, dynamic> _recipeFull(RecipeEntity r) => {
    ..._recipeSummary(r),
    'ingredients': r.ingredients.map(_ingredientJson).toList(),
    'steps': r.steps,
    if (r.nutrition != null)
      'nutrition_per_serving': {
        'calories': r.nutrition!.calories,
        'protein_g': r.nutrition!.proteinGrams,
        'carbs_g': r.nutrition!.carbsGrams,
        'fat_g': r.nutrition!.fatGrams,
      },
    'allergens': r.allergens.map((a) => a.name).toList(),
  };

  static Map<String, dynamic> _ingredientJson(RecipeIngredientEntity i) => {
    'name': i.name,
    'amount': i.amount,
    'unit': i.unit.name,
  };

  static RecipeIngredientEntity _ingredientFrom(Map<String, dynamic> m) =>
      RecipeIngredientEntity(
        name: (m['name'] as String? ?? '').trim(),
        amount: (m['amount'] as num?)?.toDouble(),
        unit: _unitFrom(m['unit'] as String?),
      );

  static MeasurementUnit _unitFrom(String? name) =>
      MeasurementUnit.values.where((u) => u.name == name).firstOrNull ??
      MeasurementUnit.unspecified;

  static List<DietaryPreference> _dietaryFrom(Object? raw) => [
    for (final n in (raw as List?)?.cast<String>() ?? const <String>[])
      ...DietaryPreference.values.where((d) => d.name == n),
  ];

  static int? _weekdayFrom(Object? raw) {
    if (raw is int) return raw.clamp(0, 6);
    if (raw is String) {
      final i = ShoppingDay.values.indexWhere(
        (d) => d.name == raw.trim().toLowerCase(),
      );
      return i < 0 ? null : i;
    }
    return null;
  }

  static List<String> _strings(Object? raw) =>
      (raw as List?)?.map((e) => e.toString()).toList() ?? const [];

  Future<List<DietaryPreference>> _dietaryPreferences() async =>
      (await preferences.getPreferences()).dietaryPreferences;

  // ---- Recipes ------------------------------------------------------------

  Future<ToolResult> _searchRecipes(Map<String, dynamic> a) async {
    final query = (a['query'] as String? ?? '').trim().toLowerCase();
    final dietary = _dietaryFrom(a['dietary']);
    final limit = (a['limit'] as int?) ?? 20;
    final all = await recipes.getRecipes();
    final hits = all.where((r) {
      if (dietary.isNotEmpty && !dietary.every(r.dietaryTags.contains)) {
        return false;
      }
      if (query.isEmpty) return true;
      return r.title.toLowerCase().contains(query) ||
          r.ingredients.any((i) => i.name.toLowerCase().contains(query));
    }).toList();
    final shown = hits.take(limit).toList();
    return ToolResult.ok(
      {'count': hits.length, 'recipes': shown.map(_recipeSummary).toList()},
      card: shown.isEmpty
          ? null
          : RecipeListCard(t.assistant.results(count: hits.length), shown),
    );
  }

  Future<ToolResult> _getRecipe(Map<String, dynamic> a) async {
    final recipe = await _findRecipe(a['recipe_id'] as String?);
    if (recipe == null) return _notFound('Recipe', a['recipe_id'] as String?);
    return ToolResult.ok(_recipeFull(recipe), card: RecipeCard(recipe));
  }

  Future<ToolResult> _createRecipe(Map<String, dynamic> a) async {
    final ingredients = [
      for (final m in (a['ingredients'] as List?) ?? const [])
        if (m is Map) _ingredientFrom(m.cast<String, dynamic>()),
    ].where((i) => i.name.isNotEmpty).toList();
    final steps = _strings(a['steps']).where((s) => s.trim().isNotEmpty);
    final recipe = RecipeEntity(
      id: _uuid.v4(),
      title: (a['title'] as String? ?? '').trim(),
      ingredients: ingredients,
      steps: steps.toList(),
      createdAt: DateTime.now(),
      servings: a['servings'] as int?,
      prepTimeMinutes: a['prep_minutes'] as int?,
      cookTimeMinutes: a['cook_minutes'] as int?,
      dietaryTags: _dietaryFrom(a['dietary_tags']),
      sourceChannel: RecipeIngestionChannel.manual,
    );
    if (recipe.title.isEmpty) {
      return ToolResult.error('invalid', 'A title is required');
    }
    await recipes.saveRecipe(recipe);
    return ToolResult.ok(
      _recipeSummary(recipe),
      card: RecipeCard(recipe, caption: t.assistant.recipeSaved),
    );
  }

  Future<ToolResult> _updateRecipe(Map<String, dynamic> a) async {
    final recipe = await _findRecipe(a['recipe_id'] as String?);
    if (recipe == null) return _notFound('Recipe', a['recipe_id'] as String?);
    if (!recipe.canEdit) {
      return ToolResult.error('read_only', 'This recipe is view-only');
    }
    final remove = _strings(
      a['remove_ingredient_names'],
    ).map((s) => s.toLowerCase()).toSet();
    final ingredients = [
      for (final i in recipe.ingredients)
        if (!remove.contains(i.name.toLowerCase())) i,
      for (final m in (a['add_ingredients'] as List?) ?? const [])
        if (m is Map) _ingredientFrom(m.cast<String, dynamic>()),
    ];
    final steps = a['steps'] == null ? null : _strings(a['steps']);
    final updated = recipe.copyWith(
      title: (a['title'] as String?)?.trim(),
      servings: a['servings'] as int?,
      prepTimeMinutes: a['prep_minutes'] as int?,
      cookTimeMinutes: a['cook_minutes'] as int?,
      ingredients: ingredients,
      steps: steps,
    );
    await recipes.saveRecipe(updated);
    return ToolResult.ok(_recipeFull(updated), card: RecipeCard(updated));
  }

  Future<ToolResult> _deleteRecipe(Map<String, dynamic> a) async {
    final recipe = await _findRecipe(a['recipe_id'] as String?);
    if (recipe == null) return _notFound('Recipe', a['recipe_id'] as String?);
    if (!await ui.confirmDelete(recipe.title)) {
      return ToolResult.error('cancelled', 'The user did not confirm');
    }
    await recipes.deleteRecipe(recipe.id);
    return ToolResult.ok({
      'deleted': recipe.id,
    }, card: StatusCard(t.assistant.done, icon: 'delete'));
  }

  Future<ToolResult> _importRecipe(Map<String, dynamic> a) async {
    final source = a['source'] as String? ?? 'text';
    final content = (a['content'] as String? ?? '').trim();
    if (content.isEmpty) {
      return ToolResult.error('invalid', 'Nothing to import');
    }
    final prefs = await _dietaryPreferences();
    // Links cost an extraction from the daily allowance, as on the add screen.
    if ((source == 'url' || source == 'social_video') &&
        !await ui.allowAiExtraction()) {
      return ToolResult.error('quota', t.ads.aiQuotaReached);
    }
    final parsed = switch (source) {
      'url' => await ingestion.parseFromUrl(content, prefs),
      'social_video' => await ingestion.parseFromSocialVideo(content, prefs),
      'request' => await ingestion.generateRecipe(content, prefs),
      _ => await ingestion.parseRawText(content, prefs),
    };
    await recipes.saveRecipe(parsed);
    return ToolResult.ok(
      _recipeFull(parsed),
      card: RecipeCard(parsed, caption: t.assistant.recipeSaved),
    );
  }

  Future<ToolResult> _searchWebRecipes(Map<String, dynamic> a) async {
    final query = (a['query'] as String? ?? '').trim();
    final results = await ingestion.searchWeb(
      query,
      await _dietaryPreferences(),
    );
    return ToolResult.ok(
      {
        'results': [
          for (final r in results)
            {'title': r.title, 'url': r.url, 'snippet': r.snippet},
        ],
      },
      card: results.isEmpty ? null : WebResultsCard(results),
    );
  }

  Future<ToolResult> _openRecipe(Map<String, dynamic> a) async {
    final recipe = await _findRecipe(a['recipe_id'] as String?);
    if (recipe == null) return _notFound('Recipe', a['recipe_id'] as String?);
    ui.openRecipe(recipe);
    return ToolResult.ok({'opened': recipe.id});
  }

  // ---- Books --------------------------------------------------------------

  Future<ToolResult> _listBooks() async {
    final all = await books.getBooks();
    return ToolResult.ok(
      {
        'books': [
          for (final b in all)
            {'id': b.id, 'title': b.title, 'recipe_count': b.recipeRefs.length},
        ],
      },
      card: LinesCard(t.nav.library, [
        for (final b in all) '${b.title} · ${b.recipeRefs.length}',
      ]),
    );
  }

  Future<ToolResult> _createBook(Map<String, dynamic> a) async {
    final title = (a['title'] as String? ?? '').trim();
    if (title.isEmpty) {
      return ToolResult.error('invalid', 'A title is required');
    }
    final book = RecipeBookEntity(
      id: _uuid.v4(),
      title: title,
      recipeRefs: const [],
      createdAt: DateTime.now(),
    );
    await books.saveBook(book);
    return ToolResult.ok({
      'id': book.id,
      'title': title,
    }, card: StatusCard(title, icon: 'book'));
  }

  Future<ToolResult> _addRecipeToBook(Map<String, dynamic> a) async {
    final recipe = await _findRecipe(a['recipe_id'] as String?);
    if (recipe == null) return _notFound('Recipe', a['recipe_id'] as String?);
    final bookId = a['book_id'] as String? ?? '';
    var book = await books.getBookById(bookId);
    book ??= (await books.getBooks())
        .where((b) => b.title.toLowerCase() == bookId.toLowerCase())
        .firstOrNull;
    if (book == null) return _notFound('Book', bookId);
    if (book.recipeRefs.any((r) => r.recipeId == recipe.id)) {
      return ToolResult.ok({'already_in_book': true, 'book': book.title});
    }
    final refs = [
      ...book.recipeRefs,
      BookRecipeRefEntity(recipeId: recipe.id, order: book.recipeRefs.length),
    ];
    await books.saveBook(book.copyWith(recipeRefs: refs));
    return ToolResult.ok({
      'book': book.title,
      'recipe': recipe.title,
    }, card: StatusCard('${recipe.title} → ${book.title}', icon: 'book'));
  }

  // ---- Meal plans ---------------------------------------------------------

  String _dayLabel(int weekday) => switch (ShoppingDay.values[weekday]) {
    ShoppingDay.sunday => t.weekday.sunday,
    ShoppingDay.monday => t.weekday.monday,
    ShoppingDay.tuesday => t.weekday.tuesday,
    ShoppingDay.wednesday => t.weekday.wednesday,
    ShoppingDay.thursday => t.weekday.thursday,
    ShoppingDay.friday => t.weekday.friday,
    ShoppingDay.saturday => t.weekday.saturday,
  };

  /// A meal name the model may pass as a key ("dinner") or as the label
  /// the user sees; both resolve to the label the plan stores.
  String _mealLabel(String raw) {
    final key = raw.trim();
    const keys = {
      'breakfast',
      'lunch',
      'dinner',
      'morningSnack',
      'afternoonSnack',
      'eveningSnack',
    };
    if (!keys.contains(key)) return key;
    return switch (key) {
      'breakfast' => t.mealPlanner.breakfast,
      'lunch' => t.mealPlanner.lunch,
      'dinner' => t.mealPlanner.dinner,
      'morningSnack' => t.mealPlanner.morningSnack,
      'afternoonSnack' => t.mealPlanner.afternoonSnack,
      _ => t.mealPlanner.eveningSnack,
    };
  }

  Future<Map<String, RecipeEntity>> _recipeIndex() async => {
    for (final r in await recipes.getRecipes()) r.id: r,
  };

  Future<Map<String, dynamic>> _planJson(MealPlanEntity plan) async {
    final index = await _recipeIndex();
    return {
      'id': plan.id,
      'name': plan.name,
      'days': [
        for (var d = 0; d < 7; d++)
          {
            'weekday': ShoppingDay.values[d].name,
            'meals': [
              for (final m in plan.mealsForWeekday(d))
                {
                  'meal_id': m.id,
                  'name': m.name,
                  'items': [
                    for (final i in m.items)
                      {
                        'item_id': i.id,
                        'recipe_id': i.recipeId,
                        'title': i.recipeId != null
                            ? index[i.recipeId]?.title
                            : i.freeText,
                      },
                  ],
                },
            ],
          },
      ],
    };
  }

  Future<ToolResult> _listMealPlans(Map<String, dynamic> a) async {
    final all = await plans.getPlans();
    final wanted = a['plan_id'] as String?;
    final chosen = wanted == null
        ? all
        : all.where((p) => p.id == wanted || p.name == wanted).toList();
    final json = [for (final p in chosen) await _planJson(p)];
    final index = await _recipeIndex();
    final lines = <String>[];
    for (final p in chosen) {
      for (var d = 0; d < 7; d++) {
        for (final m in p.mealsForWeekday(d)) {
          if (m.items.isEmpty) continue;
          final titles = m.items
              .map(
                (i) =>
                    i.recipeId != null ? index[i.recipeId]?.title : i.freeText,
              )
              .whereType<String>()
              .join(', ');
          lines.add('${_dayLabel(d)} · ${m.name}: $titles');
        }
      }
    }
    return ToolResult.ok(
      {'plans': json},
      card: lines.isEmpty ? null : LinesCard(t.nav.mealPlan, lines),
    );
  }

  Future<MealPlanEntity> _createPlanEntity(
    String name,
    MealPlanTemplate template,
  ) async {
    final names = switch (template) {
      MealPlanTemplate.free => const <String>[],
      MealPlanTemplate.threeMeals => [
        t.mealPlanner.breakfast,
        t.mealPlanner.lunch,
        t.mealPlanner.dinner,
      ],
      MealPlanTemplate.sixMeals => [
        t.mealPlanner.breakfast,
        t.mealPlanner.morningSnack,
        t.mealPlanner.lunch,
        t.mealPlanner.afternoonSnack,
        t.mealPlanner.dinner,
        t.mealPlanner.eveningSnack,
      ],
    };
    final plan = MealPlanEntity(
      id: _uuid.v4(),
      name: name,
      meals: [
        for (var weekday = 0; weekday < 7; weekday++)
          for (var order = 0; order < names.length; order++)
            MealEntity(
              id: _uuid.v4(),
              weekday: weekday,
              name: names[order],
              order: order,
              items: const [],
            ),
      ],
      createdAt: DateTime.now(),
    );
    await plans.savePlan(plan);
    return plan;
  }

  Future<ToolResult> _createMealPlan(Map<String, dynamic> a) async {
    final name = (a['name'] as String? ?? '').trim();
    if (name.isEmpty) return ToolResult.error('invalid', 'A name is required');
    final template =
        MealPlanTemplate.values
            .where((v) => v.name == a['template'])
            .firstOrNull ??
        MealPlanTemplate.threeMeals;
    final plan = await _createPlanEntity(name, template);
    return ToolResult.ok({
      'id': plan.id,
      'name': plan.name,
    }, card: StatusCard(plan.name, icon: 'calendar'));
  }

  Future<ToolResult> _planMeal(Map<String, dynamic> a) async {
    final weekday = _weekdayFrom(a['weekday']);
    final mealName = _mealLabel(a['meal'] as String? ?? '');
    if (weekday == null || mealName.isEmpty) {
      return ToolResult.error('invalid', 'weekday and meal are required');
    }
    RecipeEntity? recipe;
    final freeText = (a['free_text'] as String?)?.trim();
    if (a['recipe_id'] != null) {
      recipe = await _findRecipe(a['recipe_id'] as String?);
      if (recipe == null) {
        return _notFound('Recipe', a['recipe_id'] as String?);
      }
    } else if (freeText == null || freeText.isEmpty) {
      return ToolResult.error('invalid', 'recipe_id or free_text is required');
    }

    final all = await plans.getPlans();
    MealPlanEntity? plan;
    final wanted = a['plan_id'] as String?;
    if (wanted != null) {
      plan = all.where((p) => p.id == wanted || p.name == wanted).firstOrNull;
      if (plan == null) return _notFound('Plan', wanted);
    } else if (all.isNotEmpty) {
      plan = all.reduce((x, y) => x.createdAt.isAfter(y.createdAt) ? x : y);
    } else {
      plan = await _createPlanEntity(
        t.mealPlanner.newPlan,
        MealPlanTemplate.threeMeals,
      );
    }

    var meal = plan
        .mealsForWeekday(weekday)
        .where((m) => m.name.toLowerCase() == mealName.toLowerCase())
        .firstOrNull;
    final meals = [...plan.meals];
    if (meal == null) {
      meal = MealEntity(
        id: _uuid.v4(),
        weekday: weekday,
        name: mealName,
        order: plan.mealsForWeekday(weekday).length,
        items: const [],
      );
      meals.add(meal);
    }
    final item = MealItemEntity(
      id: _uuid.v4(),
      recipeId: recipe?.id,
      freeText: recipe == null ? freeText : null,
    );
    final updatedMeal = meal.copyWith(items: [...meal.items, item]);
    final at = meals.indexWhere((m) => m.id == meal!.id);
    meals[at] = updatedMeal;
    await plans.savePlan(plan.copyWith(meals: meals));

    final title = recipe?.title ?? freeText!;
    return ToolResult.ok(
      {
        'plan_id': plan.id,
        'meal_id': updatedMeal.id,
        'item_id': item.id,
        'weekday': ShoppingDay.values[weekday].name,
        'meal': updatedMeal.name,
        'title': title,
      },
      card: PlannedMealCard(
        planName: plan.name,
        dayLabel: _dayLabel(weekday),
        mealName: updatedMeal.name,
        title: title,
        recipe: recipe,
      ),
    );
  }

  Future<ToolResult> _removePlannedItem(Map<String, dynamic> a) async {
    final plan = await plans.getPlanById(a['plan_id'] as String? ?? '');
    if (plan == null) return _notFound('Plan', a['plan_id'] as String?);
    final mealId = a['meal_id'] as String?;
    final itemId = a['item_id'] as String?;
    var removed = false;
    final meals = [
      for (final m in plan.meals)
        if (m.id == mealId)
          m.copyWith(
            items: [
              for (final i in m.items)
                if (i.id == itemId) ...[if (!(removed = true)) i] else i,
            ],
          )
        else
          m,
    ];
    if (!removed) return _notFound('Planned item', itemId);
    await plans.savePlan(plan.copyWith(meals: meals));
    return ToolResult.ok({
      'removed': itemId,
    }, card: StatusCard(t.assistant.done, icon: 'delete'));
  }

  // ---- Groceries ----------------------------------------------------------

  Future<GroceryListEntity?> _activeGroceryList() async {
    final id = await activeList.read();
    if (id != null) {
      final list = await groceries.getListById(id);
      if (list != null) return list;
    }
    final all = await groceries.getLists();
    if (all.isEmpty) return null;
    return all.reduce((x, y) => x.createdAt.isAfter(y.createdAt) ? x : y);
  }

  /// The list the model named (id, else name), or the active one.
  Future<GroceryListEntity?> _groceryList(String? idOrName) async {
    if (idOrName == null || idOrName.trim().isEmpty) {
      return _activeGroceryList();
    }
    final byId = await groceries.getListById(idOrName);
    if (byId != null) return byId;
    final needle = idOrName.trim().toLowerCase();
    return (await groceries.getLists())
        .where((l) => l.name.toLowerCase() == needle)
        .firstOrNull;
  }

  /// "Grocery list", then "Grocery list 2", "Grocery list 3": two lists
  /// never share a name.
  Future<String> _uniqueListName(String wanted) async {
    final base = wanted.trim();
    final taken = (await groceries.getLists())
        .map((l) => l.name.toLowerCase())
        .toSet();
    if (!taken.contains(base.toLowerCase())) return base;
    for (var n = 2; ; n++) {
      final candidate = '$base $n';
      if (!taken.contains(candidate.toLowerCase())) return candidate;
    }
  }

  Map<String, dynamic> _listSummary(GroceryListEntity l, String? activeId) => {
    'id': l.id,
    'name': l.name,
    'item_count': l.items.length,
    'bought': l.checkedCount,
    'active': l.id == activeId,
  };

  Future<ToolResult> _listGroceryLists() async {
    final all = await groceries.getLists();
    final activeId = await activeList.read();
    return ToolResult.ok(
      {
        'lists': [for (final l in all) _listSummary(l, activeId)],
      },
      card: all.isEmpty
          ? null
          : LinesCard(t.nav.groceries, [
              for (final l in all)
                '${l.name} · ${l.items.length}${l.id == activeId ? ' ✓' : ''}',
            ]),
    );
  }

  Future<ToolResult> _createGroceryList(Map<String, dynamic> a) async {
    final wanted = (a['name'] as String? ?? '').trim();
    if (wanted.isEmpty) {
      return ToolResult.error('invalid', 'A name is required');
    }
    final list = GroceryListEntity(
      id: _uuid.v4(),
      name: await _uniqueListName(wanted),
      items: const [],
      createdAt: DateTime.now(),
      source: GroceryListSource.manual,
    );
    await groceries.saveList(list);
    await activeList.write(list.id);
    return ToolResult.ok({
      'list_id': list.id,
      'name': list.name,
    }, card: StatusCard('${t.assistant.listCreated}: ${list.name}'));
  }

  static Map<String, dynamic> _itemJson(GroceryItemEntity i) => {
    'id': i.id,
    'name': i.name,
    'amount': i.totalAmount,
    'unit': i.unit.name,
    'bought': i.isChecked,
    'category': i.category,
  };

  ToolResult _groceryResult(
    GroceryListEntity list, {
    Map<String, dynamic> extra = const {},
  }) => ToolResult.ok(
    {
      'list_id': list.id,
      'list_name': list.name,
      'items': list.items.map(_itemJson).toList(),
      ...extra,
    },
    card: GroceryCard(listId: list.id, listName: list.name, items: list.items),
  );

  Future<ToolResult> _getGroceryList(Map<String, dynamic> a) async {
    final list = await _groceryList(a['list_id'] as String?);
    if (list == null) {
      return ToolResult.ok({'list_id': null, 'items': const []});
    }
    return _groceryResult(list);
  }

  Future<ToolResult> _addGroceryItems(Map<String, dynamic> a) async {
    final wanted = [
      for (final m in (a['items'] as List?) ?? const [])
        if (m is Map) _ingredientFrom(m.cast<String, dynamic>()),
    ].where((i) => i.name.isNotEmpty).toList();
    if (wanted.isEmpty) return ToolResult.error('invalid', 'No items given');

    final listId = a['list_id'] as String?;
    final all = await groceries.getLists();
    GroceryListEntity? list;
    if (listId != null && listId.trim().isNotEmpty) {
      list = await _groceryList(listId);
      if (list == null) return _notFound('Grocery list', listId);
    } else if (all.length > 1) {
      // Several lists and no choice: the model asks, it does not guess.
      final activeId = await activeList.read();
      return ToolResult(
        {
          'ok': false,
          'error': 'ambiguous_list',
          'message': t.assistant.whichList,
          'lists': [for (final l in all) _listSummary(l, activeId)],
        },
        card: LinesCard(t.assistant.whichList, [
          for (final l in all)
            '${l.name} · ${l.items.length}${l.id == activeId ? ' ✓' : ''}',
        ]),
      );
    } else {
      list = all.firstOrNull;
    }
    var created = false;
    if (list == null) {
      list = GroceryListEntity(
        id: _uuid.v4(),
        name: await _uniqueListName(t.assistant.listTitle),
        items: const [],
        createdAt: DateTime.now(),
        source: GroceryListSource.manual,
      );
      created = true;
    }
    final items = [...list.items];
    for (final w in wanted) {
      final amount = w.amount ?? 1;
      final at = items.indexWhere(
        (i) => i.name.toLowerCase() == w.name.toLowerCase() && i.unit == w.unit,
      );
      if (at >= 0) {
        final existing = items[at];
        items[at] = existing.copyWith(
          isChecked: false,
          sources: [
            ...existing.sources,
            GroceryItemSourceEntity(label: w.name, amount: amount),
          ],
        );
      } else {
        items.add(
          GroceryItemEntity(
            id: _uuid.v4(),
            name: w.name,
            unit: w.unit,
            sources: [GroceryItemSourceEntity(label: w.name, amount: amount)],
            category: 'כללי',
            isAdHoc: true,
          ),
        );
      }
    }
    final saved = list.copyWith(items: items);
    await groceries.saveList(saved);
    if (created) await activeList.write(saved.id);
    return _groceryResult(saved, extra: {'added': wanted.length});
  }

  /// Items by id or by name (exact, then contains), in the order asked.
  List<GroceryItemEntity> _matchItems(
    GroceryListEntity list,
    List<String> keys,
  ) {
    final found = <GroceryItemEntity>[];
    for (final key in keys) {
      final k = key.trim().toLowerCase();
      final hit =
          list.items.where((i) => i.id == key).firstOrNull ??
          list.items.where((i) => i.name.toLowerCase() == k).firstOrNull ??
          list.items.where((i) => i.name.toLowerCase().contains(k)).firstOrNull;
      if (hit != null && !found.contains(hit)) found.add(hit);
    }
    return found;
  }

  Future<ToolResult> _setGroceryItemChecked(Map<String, dynamic> a) async {
    final list = await _groceryList(a['list_id'] as String?);
    if (list == null) return _notFound('Grocery list', null);
    final checked = a['checked'] as bool? ?? true;
    final hits = _matchItems(
      list,
      _strings(a['items']),
    ).map((i) => i.id).toSet();
    if (hits.isEmpty) return _notFound('Item', _strings(a['items']).join(', '));
    final saved = list.copyWith(
      items: [
        for (final i in list.items)
          hits.contains(i.id) ? i.copyWith(isChecked: checked) : i,
      ],
    );
    await groceries.saveList(saved);
    return _groceryResult(saved, extra: {'changed': hits.length});
  }

  /// The checklist card's own toggle, outside a model turn.
  Future<void> toggleGroceryItem(String listId, String itemId) async {
    final list = await groceries.getListById(listId);
    if (list == null) return;
    await groceries.saveList(
      list.copyWith(
        items: [
          for (final i in list.items)
            i.id == itemId ? i.copyWith(isChecked: !i.isChecked) : i,
        ],
      ),
    );
  }

  Future<ToolResult> _removeGroceryItems(Map<String, dynamic> a) async {
    final list = await _groceryList(a['list_id'] as String?);
    if (list == null) return _notFound('Grocery list', null);
    final hits = _matchItems(
      list,
      _strings(a['items']),
    ).map((i) => i.id).toSet();
    if (hits.isEmpty) return _notFound('Item', _strings(a['items']).join(', '));
    final saved = list.copyWith(
      items: [
        for (final i in list.items)
          if (!hits.contains(i.id)) i,
      ],
    );
    await groceries.saveList(saved);
    return _groceryResult(saved, extra: {'removed': hits.length});
  }

  Future<ToolResult> _clearCheckedItems(Map<String, dynamic> a) async {
    final list = await _groceryList(a['list_id'] as String?);
    if (list == null) return _notFound('Grocery list', null);
    final kept = list.items.where((i) => !i.isChecked).toList();
    final saved = list.copyWith(items: kept);
    await groceries.saveList(saved);
    return _groceryResult(
      saved,
      extra: {'removed': list.items.length - kept.length},
    );
  }

  Future<ToolResult> _groceryListFromRecipe(Map<String, dynamic> a) async {
    final recipe = await _findRecipe(a['recipe_id'] as String?);
    if (recipe == null) return _notFound('Recipe', a['recipe_id'] as String?);
    final scale = (a['scale'] as num?)?.toDouble() ?? 1;
    final list = await CreateRecipeGroceryListUseCase(
      groceries,
      activeList,
    )(recipe, name: await _uniqueListName(recipe.title), scale: scale);
    return _groceryResult(list);
  }

  // ---- Cooking ------------------------------------------------------------

  Future<ToolResult> _startCookMode(Map<String, dynamic> a) async {
    final recipe = await _findRecipe(a['recipe_id'] as String?);
    if (recipe == null) return _notFound('Recipe', a['recipe_id'] as String?);
    if (MonetizationConfig.cookModeLocked) {
      ui.openScreen('premium');
      return ToolResult.error('premium_required', t.assistant.needsPremium);
    }
    final step = (a['step'] as int?) ?? 1;
    final session = cooking.start(recipe);
    cooking.setStep(
      recipe.id,
      (step - 1).clamp(0, recipe.steps.length - 1),
    );
    ui.openCookMode(session.recipe);
    return ToolResult.ok({
      'recipe_id': recipe.id,
      'step': step,
    }, card: StatusCard(t.assistant.cookStarted, icon: 'flame'));
  }

  Future<ToolResult> _startTimer(Map<String, dynamic> a) async {
    final recipe = await _findRecipe(a['recipe_id'] as String?);
    if (recipe == null) return _notFound('Recipe', a['recipe_id'] as String?);
    if (MonetizationConfig.cookModeLocked) {
      return ToolResult.error('premium_required', t.assistant.needsPremium);
    }
    final step = ((a['step'] as int?) ?? 1) - 1;
    final session = cooking.start(recipe);
    final timer = session.timers[step];
    if (timer == null) {
      return ToolResult.error(
        'no_timer',
        'Step ${step + 1} names no duration; available: '
            '${session.timers.keys.map((k) => k + 1).join(', ')}',
      );
    }
    if (!timer.running) cooking.toggleTimer(recipe.id, step);
    return ToolResult.ok({
      'recipe_id': recipe.id,
      'step': step + 1,
      'remaining': timer.display,
    }, card: StatusCard(t.assistant.timerSet(n: '${step + 1}'), icon: 'timer'));
  }

  Future<ToolResult> _cookingStatus() async {
    final sessions = cooking.sessions;
    return ToolResult.ok({
      'cooking': [
        for (final s in sessions)
          {
            'recipe_id': s.id,
            'title': s.recipe.title,
            'step': s.stepIndex + 1,
            'of': s.recipe.steps.length,
            'timers': [
              for (final e in s.activeTimers)
                {
                  'step': e.key + 1,
                  'remaining': e.value.display,
                  'rung': e.value.finished,
                },
            ],
          },
      ],
    });
  }

  // ---- Account ------------------------------------------------------------

  Map<String, dynamic> _prefsJson(UserPreferencesEntity p) => {
    'shopping_day': p.shoppingDay.name,
    'dietary': p.dietaryPreferences.map((d) => d.name).toList(),
    'language': p.language.name,
  };

  Future<ToolResult> _getPreferences() async =>
      ToolResult.ok(_prefsJson(await preferences.getPreferences()));

  Future<void> _savePreferences(UserPreferencesEntity updated) async {
    await preferences.savePreferences(updated);
    AuthSessionService().publishPreferences(updated);
  }

  Future<ToolResult> _setShoppingDay(Map<String, dynamic> a) async {
    final day = _weekdayFrom(a['day']);
    if (day == null) return ToolResult.error('invalid', 'Unknown day');
    final current = await preferences.getPreferences();
    await _savePreferences(
      current.copyWith(shoppingDay: ShoppingDay.values[day]),
    );
    return ToolResult.ok({
      'shopping_day': ShoppingDay.values[day].name,
    }, card: StatusCard(t.assistant.prefSaved));
  }

  Future<ToolResult> _setDietaryPreferences(Map<String, dynamic> a) async {
    final current = await preferences.getPreferences();
    final add = _dietaryFrom(a['add']);
    final remove = _dietaryFrom(a['remove']).toSet();
    final next = {
      for (final d in current.dietaryPreferences)
        if (!remove.contains(d)) d,
      ...add,
    }.toList();
    await _savePreferences(current.copyWith(dietaryPreferences: next));
    return ToolResult.ok({
      'dietary': next.map((d) => d.name).toList(),
    }, card: StatusCard(t.assistant.prefSaved));
  }

  Future<ToolResult> _premiumStatus() async => ToolResult.ok({
    'premium': MonetizationConfig.isPremium,
    'cook_mode_locked': MonetizationConfig.cookModeLocked,
    'notifications_locked': MonetizationConfig.notificationsLocked,
  });

  Future<ToolResult> _openScreen(Map<String, dynamic> a) async {
    final screen = a['screen'] as String? ?? '';
    ui.openScreen(screen);
    return ToolResult.ok({'opened': screen});
  }

  // ---- Knowledge helpers --------------------------------------------------

  static const _toMl = <String, double>{
    'milliliter': 1,
    'ml': 1,
    'liter': 1000,
    'l': 1000,
    'teaspoon': 5,
    'tsp': 5,
    'tablespoon': 15,
    'tbsp': 15,
    'cup': 240,
  };
  static const _toG = <String, double>{
    'gram': 1,
    'g': 1,
    'kilogram': 1000,
    'kg': 1000,
  };

  /// Grams per millilitre for the pantry staples people convert most.
  static const _density = <String, double>{
    'water': 1,
    'milk': 1.03,
    'flour': 0.53,
    'sugar': 0.85,
    'brown sugar': 0.8,
    'butter': 0.96,
    'oil': 0.92,
    'olive oil': 0.92,
    'honey': 1.42,
    'rice': 0.78,
    'salt': 1.2,
    'cocoa': 0.5,
    'oats': 0.4,
  };

  ToolResult _convertMeasurement(Map<String, dynamic> a) {
    final amount = (a['amount'] as num?)?.toDouble();
    final from = (a['from'] as String? ?? '').trim().toLowerCase();
    final to = (a['to'] as String? ?? '').trim().toLowerCase();
    if (amount == null || from.isEmpty || to.isEmpty) {
      return ToolResult.error('invalid', 'amount, from and to are required');
    }
    double? result;
    if ((from == 'celsius' || from == 'c') &&
        (to == 'fahrenheit' || to == 'f')) {
      result = amount * 9 / 5 + 32;
    } else if ((from == 'fahrenheit' || from == 'f') &&
        (to == 'celsius' || to == 'c')) {
      result = (amount - 32) * 5 / 9;
    } else {
      final ingredient = (a['ingredient'] as String? ?? '').toLowerCase();
      final density =
          _density.entries
              .where((e) => ingredient.contains(e.key))
              .map((e) => e.value)
              .firstOrNull ??
          1.0;
      // Everything goes through millilitres; weight crosses over by density.
      double? ml;
      if (_toMl.containsKey(from)) ml = amount * _toMl[from]!;
      if (_toG.containsKey(from)) ml = amount * _toG[from]! / density;
      if (ml != null) {
        if (_toMl.containsKey(to)) result = ml / _toMl[to]!;
        if (_toG.containsKey(to)) result = ml * density / _toG[to]!;
      }
    }
    if (result == null) {
      return ToolResult.error('unsupported', 'Cannot convert $from to $to');
    }
    final rounded = (result * 100).round() / 100;
    return ToolResult.ok({
      'amount': amount,
      'from': from,
      'to': to,
      'result': rounded,
    }, card: StatusCard('$amount $from = $rounded $to', icon: 'scale'));
  }

  Future<ToolResult> _estimateNutrition(Map<String, dynamic> a) async {
    final recipe = await _findRecipe(a['recipe_id'] as String?);
    if (recipe == null) return _notFound('Recipe', a['recipe_id'] as String?);
    final estimated = await ingestion.estimateNutrition(recipe);
    await recipes.saveRecipe(estimated);
    return ToolResult.ok(_recipeFull(estimated), card: RecipeCard(estimated));
  }

  // ---- Context for the system prompt ------------------------------------

  /// What the model should know before the first word: the date, the
  /// preferences, the recipes it can refer to by id, the active list and
  /// what is cooking. Kept short; the tools fetch the rest on demand.
  /// Everything about one item, for a conversation locked to it: the model
  /// reads this instead of looking the item up, and cannot mistake it for
  /// another. Null when the item is gone.
  Future<String?> describe(AssistantScope scope) async {
    switch (scope.kind) {
      case AssistantScopeKind.recipe:
        final r = await recipes.getRecipeById(scope.id);
        if (r == null) return null;
        final b = StringBuffer()
          ..writeln('Recipe "${r.title}" (id ${r.id}).')
          ..writeln(
            'Servings: ${r.servings ?? '?'}; prep ${r.prepTimeMinutes ?? '?'} min; '
            'cook ${r.cookTimeMinutes ?? '?'} min; '
            'tags: ${r.dietaryTags.map((d) => d.name).join(', ')}; '
            'allergens: ${r.allergens.map((a) => a.name).join(', ')}.',
          )
          ..writeln('Ingredients:');
        for (final i in r.ingredients) {
          b.writeln(
            '- ${i.name}${i.amount == null ? '' : ': ${i.amount} ${i.unit.name}'}',
          );
        }
        b.writeln('Steps:');
        for (var i = 0; i < r.steps.length; i++) {
          b.writeln('${i + 1}. ${r.steps[i]}');
        }
        if (r.nutrition case final n?) {
          b.writeln(
            'Nutrition per serving (estimate): ${n.calories} kcal, '
            'protein ${n.proteinGrams} g, carbs ${n.carbsGrams} g, fat ${n.fatGrams} g.',
          );
        }
        return b.toString();
      case AssistantScopeKind.mealPlan:
        final p = await plans.getPlanById(scope.id);
        if (p == null) return null;
        final titles = {
          for (final r in await recipes.getRecipes()) r.id: r.title,
        };
        final b = StringBuffer()
          ..writeln('Meal plan "${p.name}" (id ${p.id}).');
        for (var day = 0; day < 7; day++) {
          final meals = p.mealsForWeekday(day);
          if (meals.isEmpty) continue;
          b.writeln('${ShoppingDay.values[day].name}:');
          for (final m in meals) {
            final items = m.items
                .map(
                  (i) => i.recipeId != null
                      ? '${titles[i.recipeId] ?? 'recipe'} (recipe_id ${i.recipeId})'
                      : (i.freeText ?? ''),
                )
                .join(', ');
            b.writeln(
              '- ${m.name} (meal_id ${m.id}): ${items.isEmpty ? 'empty' : items}',
            );
          }
        }
        return b.toString();
      case AssistantScopeKind.groceryList:
        final l = await groceries.getListById(scope.id);
        if (l == null) return null;
        final b = StringBuffer()
          ..writeln(
            'Grocery list "${l.name}" (list_id ${l.id}): ${l.items.length} items, '
            '${l.checkedCount} bought.',
          );
        for (final i in l.items) {
          b.writeln(
            '- ${i.isChecked ? '[x]' : '[ ]'} ${i.name} (item_id ${i.id})'
            '${i.totalAmount > 0 ? ': ${i.totalAmount} ${i.unit.name}' : ''}',
          );
        }
        return b.toString();
    }
  }

  Future<String> snapshot() async {
    final prefs = await preferences.getPreferences();
    final all = await recipes.getRecipes();
    final list = await _activeGroceryList();
    final now = DateTime.now();
    final buffer = StringBuffer()
      ..writeln(
        'Today: ${now.toIso8601String().substring(0, 10)} '
        '(${ShoppingDay.values[now.weekday % 7].name}).',
      )
      ..writeln(
        'User language: ${prefs.language.name}; '
        'shopping day: ${prefs.shoppingDay.name}; '
        'dietary: ${prefs.dietaryPreferences.map((d) => d.name).join(', ')}.',
      )
      ..writeln('Premium: ${MonetizationConfig.isPremium}.')
      ..writeln('Saved recipes (id: title), most recent first:');
    final recent = [...all]..sort((x, y) => y.createdAt.compareTo(x.createdAt));
    for (final r in recent.take(40)) {
      buffer.writeln('- ${r.id}: ${r.title}');
    }
    if (list != null) {
      buffer.writeln(
        'Active grocery list "${list.name}" '
        '(${list.items.length} items, ${list.checkedCount} bought): '
        '${list.items.take(30).map((i) => i.name).join(', ')}',
      );
    } else {
      buffer.writeln('No grocery list yet.');
    }
    final sessions = cooking.sessions;
    if (sessions.isNotEmpty) {
      buffer.writeln(
        'Cooking now: '
        '${sessions.map((s) => '${s.recipe.title} (step ${s.stepIndex + 1})').join('; ')}',
      );
    }
    return buffer.toString();
  }
}
