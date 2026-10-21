import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_enums.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/hive/user_scope.dart';
import '../../../core/features/features_flags.dart';
import '../../../core/monetization/monetization_config.dart';
import '../../../core/services/auth_session_service.dart';
import '../../../core/services/cook_session_service.dart';
import '../../../core/utils/i18n/strings.g.dart';
import '../../collab_containers/domain/container_sharing_service.dart';
import '../../feedback/domain/entities/feedback_entity.dart';
import '../../feedback/domain/repositories/feedback_repository.dart';
import '../../feedback/domain/support_details.dart';
import '../../feedback/domain/usecases/send_feedback_usecase.dart';
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
import '../../recipe_ingestion/domain/entities/ingestion_file.dart';
import '../../recipe_sharing/domain/repositories/recipe_sharing_repository.dart';
import '../../recipe_sharing/domain/usecases/save_collab_recipe_usecase.dart';
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

  /// Where `contact_support` writes; without it the tool answers that
  /// support is unavailable (tests, a host with no Firestore).
  final FeedbackRepository? feedback;

  /// Where an edit to a shared book, plan or list goes so the other members
  /// get it — the screens publish after saving, and an edit Shefi made
  /// without it stayed on this phone until the next sync rebuilt the copy
  /// from the document and dropped it. Null in tests.
  final ContainerSharingService? sharing;

  /// The same for a shared recipe (SaveCollabRecipeUseCase).
  final RecipeSharingRepository? recipeSharing;

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
    this.feedback,
    this.sharing,
    this.recipeSharing,
  });

  // ── Saving, shared items included ──────────────────────────────────────

  /// A shared recipe goes to its document first, as the editor saves it; a
  /// refusal (demoted, removed) is thrown and reaches the model as an error.
  Future<void> _saveRecipe(RecipeEntity recipe) async {
    final remote = recipeSharing;
    final uid = UserScope().uid;
    if (recipe.collabId != null && remote != null && uid != null) {
      await SaveCollabRecipeUseCase(sharing: remote, recipes: recipes)(
        recipe,
        byUid: uid,
      );
      return;
    }
    await recipes.saveRecipe(recipe);
  }

  Future<void> _saveBook(RecipeBookEntity book) async {
    await books.saveBook(book);
    final shared = sharing;
    if (book.isShared && shared != null) {
      await _publish((uid) => shared.books.publish(book, uid: uid));
    }
  }

  Future<void> _savePlan(MealPlanEntity plan) async {
    await plans.savePlan(plan);
    final shared = sharing;
    if (plan.isShared && shared != null) {
      await _publish((uid) => shared.plans.publish(plan, uid: uid));
    }
  }

  Future<void> _saveList(GroceryListEntity list) async {
    await groceries.saveList(list);
    final shared = sharing;
    if (list.collabId != null && shared != null) {
      await _publish((uid) => shared.lists.publish(list, uid: uid));
    }
  }

  /// Best effort, like the screens: the local save stands, and the next
  /// save from anywhere publishes again.
  Future<void> _publish(Future<void> Function(String uid) publish) async {
    final uid = UserScope().uid;
    if (uid == null) return;
    try {
      await publish(uid);
    } catch (e) {
      debugPrint('Shared item publish failed: $e');
    }
  }

  Future<ToolResult> execute(ToolCall call) async {
    try {
      return await _run(call.name, call.arguments);
    } on AppException catch (e) {
      return ToolResult.error(e.type.name, _brief(e.message));
    } catch (e) {
      return ToolResult.error('failed', _brief(e.toString()));
    }
  }

  /// A failure as the model reads it: the first line, capped. The result
  /// rides in the conversation for every later turn, so a whole server
  /// response or a stack trace would be paid for again and again.
  static String _brief(String message) {
    final line = message.trimLeft().split('\n').first.trimRight();
    return line.length <= 300 ? line : '${line.substring(0, 299)}…';
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
      case AssistantTools.contactSupport:
        return _contactSupport(a);
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

  /// What one call may carry. The model knows the schema, not these; an
  /// answer that runs away (a title that is a whole recipe, a thousand
  /// grocery items) is cut here rather than written to the box.
  static const maxTitleLength = 200;
  static const maxTextLength = 4000;
  static const maxListItems = 100;

  /// A short string — a title, a name, a key — trimmed and capped.
  static String _title(Object? raw) => _capped(raw, maxTitleLength);

  /// A long string — a step, a message — trimmed and capped.
  static String _text(Object? raw) => _capped(raw, maxTextLength);

  static String _capped(Object? raw, int max) {
    final s = (raw is String ? raw : raw?.toString() ?? '').trim();
    return s.length <= max ? s : s.substring(0, max).trimRight();
  }

  /// A list argument, at most [maxListItems] long; anything else is empty.
  static List<Object?> _list(Object? raw) =>
      raw is List ? raw.take(maxListItems).toList() : const [];

  /// The gate the screen would show before [feature]'s own entry point: a
  /// feature the console hid or marked "coming soon" is refused; one that is
  /// Premium-only, for a free account, is refused and the paywall opens the
  /// way a tap on the locked entry would.
  ToolResult? _gate(FeaturesFlags feature) {
    switch (feature.access) {
      case FeatureAccess.enabled:
        return null;
      case FeatureAccess.locked:
        ui.openScreen('premium');
        return ToolResult.error('premium_required', t.assistant.needsPremium);
      case FeatureAccess.hidden:
      case FeatureAccess.comingSoon:
        return ToolResult.error(
          'unavailable',
          '${feature.label} is not available in this app right now',
        );
    }
  }

  /// A recipe by id, or by the closest title when the model passed a name.
  Future<RecipeEntity?> _findRecipe(String? idOrTitle) async {
    if (idOrTitle == null || idOrTitle.trim().isEmpty) return null;
    idOrTitle = _title(idOrTitle);
    final byId = await recipes.getRecipeById(idOrTitle);
    if (byId != null) return byId;
    final needle = idOrTitle.toLowerCase();
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
        name: _title(m['name']),
        amount: (m['amount'] as num?)?.toDouble(),
        unit: _unitFrom(m['unit']?.toString()),
      );

  /// Ingredient-shaped entries of a list argument, nameless ones dropped.
  static List<RecipeIngredientEntity> _ingredients(Object? raw) => [
    for (final m in _list(raw))
      if (m is Map) _ingredientFrom(m.cast<String, dynamic>()),
  ].where((i) => i.name.isNotEmpty).toList();

  static MeasurementUnit _unitFrom(String? name) =>
      MeasurementUnit.values.where((u) => u.name == name).firstOrNull ??
      MeasurementUnit.unspecified;

  static List<DietaryPreference> _dietaryFrom(Object? raw) => [
    for (final n in _list(raw).whereType<String>())
      ...DietaryPreference.values.where((d) => d.name == n),
  ];

  /// An integer argument as the model sent it: the schema says `integer`,
  /// but a JSON number can still arrive as `4.0` (or, rarely, `"4"`), and
  /// a cast would fail the whole tool over the shape of a number.
  static int? _int(Object? raw) => switch (raw) {
    final int n => n,
    final num n => n.toInt(),
    final String s => int.tryParse(s.trim()),
    _ => null,
  };

  static int? _weekdayFrom(Object? raw) {
    if (raw is num) return raw.toInt().clamp(0, 6);
    if (raw is String) {
      final i = ShoppingDay.values.indexWhere(
        (d) => d.name == raw.trim().toLowerCase(),
      );
      return i < 0 ? null : i;
    }
    return null;
  }

  static List<String> _strings(Object? raw) => _list(raw).map(_text).toList();

  Future<List<DietaryPreference>> _dietaryPreferences() async =>
      (await preferences.getPreferences()).dietaryPreferences;

  // ---- Recipes ------------------------------------------------------------

  Future<ToolResult> _searchRecipes(Map<String, dynamic> a) async {
    final query = _title(a['query']).toLowerCase();
    final dietary = _dietaryFrom(a['dietary']);
    // `take` throws on a negative count; a model's "limit: 0" is read as
    // "the default", not "nothing".
    final limit = (_int(a['limit']) ?? 20).clamp(1, 100);
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
    final ingredients = _ingredients(a['ingredients']);
    final steps = _strings(a['steps']).where((s) => s.isNotEmpty);
    final recipe = RecipeEntity(
      id: _uuid.v4(),
      title: _title(a['title']),
      ingredients: ingredients,
      steps: steps.toList(),
      createdAt: DateTime.now(),
      servings: _int(a['servings']),
      prepTimeMinutes: _int(a['prep_minutes']),
      cookTimeMinutes: _int(a['cook_minutes']),
      dietaryTags: _dietaryFrom(a['dietary_tags']),
      sourceChannel: RecipeIngestionChannel.manual,
    );
    if (recipe.title.isEmpty) {
      return ToolResult.error('invalid', 'A title is required');
    }
    await _saveRecipe(recipe);
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
      ..._ingredients(a['add_ingredients']),
    ];
    final steps = a['steps'] == null ? null : _strings(a['steps']);
    // A blank title is "no change", not a recipe with no name.
    final title = _title(a['title']);
    final updated = recipe.copyWith(
      title: title.isEmpty ? null : title,
      servings: _int(a['servings']),
      prepTimeMinutes: _int(a['prep_minutes']),
      cookTimeMinutes: _int(a['cook_minutes']),
      ingredients: ingredients,
      steps: steps,
    );
    await _saveRecipe(updated);
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
    // Cut, a pasted recipe would silently lose its last steps: too long is
    // refused, and the model can send the user to the add screen.
    if (content.length > maxTextLength) {
      return ToolResult.error(
        'invalid',
        'content is longer than $maxTextLength characters',
      );
    }
    final link = source == 'url' || source == 'social_video';
    // The same four switches as the add screen's channels.
    final gate = _gate(switch (source) {
      'url' => FeaturesFlags.ingestLink,
      'social_video' => FeaturesFlags.ingestSocialVideo,
      'request' => FeaturesFlags.ingestAiRequest,
      _ => FeaturesFlags.ingestText,
    });
    if (gate != null) return gate;
    // Only an http(s) address reaches the fetch — checked before the gate
    // below, which spends an extraction.
    if (link && !IngestionLaunch.isWebUrl(content)) {
      return ToolResult.error('invalid', 'content must be an http(s) link');
    }
    final prefs = await _dietaryPreferences();
    // Every source is a model call and costs an extraction from the daily
    // allowance, as on the add screen (text, link, video and request alike).
    if (!await ui.allowAiExtraction()) {
      return ToolResult.error('quota', t.ads.aiQuotaReached);
    }
    final parsed = switch (source) {
      'url' => await ingestion.parseFromUrl(content, prefs),
      'social_video' => await ingestion.parseFromSocialVideo(content, prefs),
      'request' => await ingestion.generateRecipe(content, prefs),
      _ => await ingestion.parseRawText(content, prefs),
    };
    await _saveRecipe(parsed);
    return ToolResult.ok(
      _recipeFull(parsed),
      card: RecipeCard(parsed, caption: t.assistant.recipeSaved),
    );
  }

  Future<ToolResult> _searchWebRecipes(Map<String, dynamic> a) async {
    if (_gate(FeaturesFlags.ingestWebSearch) case final gate?) return gate;
    final query = _title(a['query']);
    if (query.isEmpty) return ToolResult.error('invalid', 'query is required');
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
          for (final b in all.take(maxListedEntities))
            {'id': b.id, 'title': b.title, 'recipe_count': b.recipeRefs.length},
        ],
        if (all.length > maxListedEntities)
          'more_books_not_listed': all.length - maxListedEntities,
      },
      card: LinesCard(t.nav.library, [
        for (final b in all) '${b.title} · ${b.recipeRefs.length}',
      ]),
    );
  }

  Future<ToolResult> _createBook(Map<String, dynamic> a) async {
    if (_gate(FeaturesFlags.books) case final gate?) return gate;
    final title = _title(a['title']);
    if (title.isEmpty) {
      return ToolResult.error('invalid', 'A title is required');
    }
    final book = RecipeBookEntity(
      id: _uuid.v4(),
      title: title,
      recipeRefs: const [],
      createdAt: DateTime.now(),
    );
    await _saveBook(book);
    return ToolResult.ok({
      'id': book.id,
      'title': title,
    }, card: StatusCard(title, icon: 'book'));
  }

  Future<ToolResult> _addRecipeToBook(Map<String, dynamic> a) async {
    if (_gate(FeaturesFlags.books) case final gate?) return gate;
    final recipe = await _findRecipe(a['recipe_id'] as String?);
    if (recipe == null) return _notFound('Recipe', a['recipe_id'] as String?);
    final bookId = _title(a['book_id']);
    var book = await books.getBookById(bookId);
    book ??= (await books.getBooks())
        .where((b) => b.title.toLowerCase() == bookId.toLowerCase())
        .firstOrNull;
    if (book == null) return _notFound('Book', bookId);
    if (!book.canEdit) {
      return ToolResult.error('read_only', 'This book is view-only');
    }
    if (book.recipeRefs.any((r) => r.recipeId == recipe.id)) {
      return ToolResult.ok({'already_in_book': true, 'book': book.title});
    }
    final refs = [
      ...book.recipeRefs,
      BookRecipeRefEntity(recipeId: recipe.id, order: book.recipeRefs.length),
    ];
    await _saveBook(book.copyWith(recipeRefs: refs));
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
    final wanted = a['plan_id'] == null ? null : _title(a['plan_id']);
    final matching = wanted == null
        ? all
        : all.where((p) => p.id == wanted || p.name == wanted).toList();
    // Capped: each plan carries its whole week, and the result stays in
    // the conversation.
    final chosen = matching.take(maxListedEntities).toList();
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
      {
        'plans': json,
        if (matching.length > chosen.length)
          'more_plans_not_listed': matching.length - chosen.length,
      },
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
    await _savePlan(plan);
    return plan;
  }

  Future<ToolResult> _createMealPlan(Map<String, dynamic> a) async {
    if (_gate(FeaturesFlags.mealPlans) case final gate?) return gate;
    final name = _title(a['name']);
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
    if (_gate(FeaturesFlags.mealPlans) case final gate?) return gate;
    final weekday = _weekdayFrom(a['weekday']);
    final mealName = _mealLabel(_title(a['meal']));
    if (weekday == null || mealName.isEmpty) {
      return ToolResult.error('invalid', 'weekday and meal are required');
    }
    RecipeEntity? recipe;
    final freeText = a['free_text'] == null ? null : _title(a['free_text']);
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
    final wanted = a['plan_id'] == null ? null : _title(a['plan_id']);
    if (wanted != null) {
      plan = all.where((p) => p.id == wanted || p.name == wanted).firstOrNull;
      if (plan == null) return _notFound('Plan', wanted);
      if (!plan.canEdit) return _planReadOnly;
    } else if (all.any((p) => p.canEdit)) {
      // The newest plan this user may write: a shared plan they only view
      // is never picked on their behalf.
      plan = all
          .where((p) => p.canEdit)
          .reduce((x, y) => x.createdAt.isAfter(y.createdAt) ? x : y);
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
    await _savePlan(plan.copyWith(meals: meals));

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
    if (_gate(FeaturesFlags.mealPlans) case final gate?) return gate;
    final plan = await plans.getPlanById(_title(a['plan_id']));
    if (plan == null) return _notFound('Plan', a['plan_id'] as String?);
    if (!plan.canEdit) return _planReadOnly;
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
    await _savePlan(plan.copyWith(meals: meals));
    return ToolResult.ok({
      'removed': itemId,
    }, card: StatusCard(t.assistant.done, icon: 'delete'));
  }

  // ---- Groceries ----------------------------------------------------------

  static ToolResult get _planReadOnly => ToolResult.error(
    'read_only',
    'This meal plan is view-only',
  );
  static ToolResult get _listReadOnly => ToolResult.error(
    'read_only',
    'This grocery list is view-only',
  );

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
    if (_gate(FeaturesFlags.groceryLists) case final gate?) return gate;
    final wanted = _title(a['name']);
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
    await _saveList(list);
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
  }) {
    // The model's copy is capped like the scoped prompt (still-to-buy lines
    // first): every result stays in the conversation for the turns after
    // it. The card on screen keeps the whole list.
    final ordered = [
      ...list.items.where((i) => !i.isChecked),
      ...list.items.where((i) => i.isChecked),
    ];
    final shown = ordered.take(scopedGroceryItemCap);
    final more = list.items.length - shown.length;
    return ToolResult.ok(
      {
        'list_id': list.id,
        'list_name': list.name,
        'items': shown.map(_itemJson).toList(),
        if (more > 0) ...{
          'total_items': list.items.length,
          'more_items_not_listed': more,
        },
        ...extra,
      },
      card: GroceryCard(
        listId: list.id,
        listName: list.name,
        items: list.items,
      ),
    );
  }

  Future<ToolResult> _getGroceryList(Map<String, dynamic> a) async {
    final list = await _groceryList(a['list_id'] as String?);
    if (list == null) {
      return ToolResult.ok({'list_id': null, 'items': const []});
    }
    return _groceryResult(list);
  }

  Future<ToolResult> _addGroceryItems(Map<String, dynamic> a) async {
    if (_gate(FeaturesFlags.groceryLists) case final gate?) return gate;
    final wanted = _ingredients(a['items']);
    if (wanted.isEmpty) return ToolResult.error('invalid', 'No items given');

    final listId = a['list_id'] == null ? null : _title(a['list_id']);
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
    if (list != null && !list.canEdit) return _listReadOnly;
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
            category: kDefaultGroceryCategory,
            isAdHoc: true,
          ),
        );
      }
    }
    final saved = list.copyWith(items: items);
    await _saveList(saved);
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
    if (_gate(FeaturesFlags.groceryLists) case final gate?) return gate;
    final list = await _groceryList(a['list_id'] as String?);
    if (list == null) return _notFound('Grocery list', null);
    if (!list.canEdit) return _listReadOnly;
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
    await _saveList(saved);
    return _groceryResult(saved, extra: {'changed': hits.length});
  }

  /// The checklist card's own toggle, outside a model turn. Returns the list
  /// as saved, or null when nothing changed (list gone, or view-only).
  Future<GroceryListEntity?> toggleGroceryItem(
    String listId,
    String itemId,
  ) async {
    final list = await groceries.getListById(listId);
    // A viewer's card toggles nothing: the shared list is not theirs to tick.
    if (list == null || !list.canEdit) return null;
    final saved = list.copyWith(
      items: [
        for (final i in list.items)
          i.id == itemId ? i.copyWith(isChecked: !i.isChecked) : i,
      ],
    );
    await _saveList(saved);
    return saved;
  }

  Future<ToolResult> _removeGroceryItems(Map<String, dynamic> a) async {
    if (_gate(FeaturesFlags.groceryLists) case final gate?) return gate;
    final list = await _groceryList(a['list_id'] as String?);
    if (list == null) return _notFound('Grocery list', null);
    if (!list.canEdit) return _listReadOnly;
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
    await _saveList(saved);
    return _groceryResult(saved, extra: {'removed': hits.length});
  }

  Future<ToolResult> _clearCheckedItems(Map<String, dynamic> a) async {
    if (_gate(FeaturesFlags.groceryLists) case final gate?) return gate;
    final list = await _groceryList(a['list_id'] as String?);
    if (list == null) return _notFound('Grocery list', null);
    if (!list.canEdit) return _listReadOnly;
    final kept = list.items.where((i) => !i.isChecked).toList();
    final saved = list.copyWith(items: kept);
    await _saveList(saved);
    return _groceryResult(
      saved,
      extra: {'removed': list.items.length - kept.length},
    );
  }

  Future<ToolResult> _groceryListFromRecipe(Map<String, dynamic> a) async {
    if (_gate(FeaturesFlags.groceryLists) ??
            _gate(FeaturesFlags.groceryFromRecipe)
        case final gate?) {
      return gate;
    }
    final recipe = await _findRecipe(a['recipe_id'] as String?);
    if (recipe == null) return _notFound('Recipe', a['recipe_id'] as String?);
    final raw = a['scale'];
    final wanted = raw is num ? raw.toDouble() : double.tryParse('$raw') ?? 1;
    // Bounded: a slip like 500 would fill the list with absurd amounts.
    final scale = wanted > 0 ? wanted.clamp(0.1, maxScale) : 1.0;
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
    // Premium-locked, hidden or "coming soon": the same verdict as the
    // screen's entry point, so a hidden cook mode starts no session.
    if (_gate(FeaturesFlags.cookMode) case final gate?) return gate;
    final step = _int(a['step']) ?? 1;
    final session = cooking.start(recipe);
    // `clamp` needs lower <= upper: a recipe with no steps clamps to 0.
    final last = recipe.steps.isEmpty ? 0 : recipe.steps.length - 1;
    cooking.setStep(recipe.id, (step - 1).clamp(0, last));
    ui.openCookMode(session.recipe);
    return ToolResult.ok({
      'recipe_id': recipe.id,
      'step': step,
    }, card: StatusCard(t.assistant.cookStarted, icon: 'flame'));
  }

  Future<ToolResult> _startTimer(Map<String, dynamic> a) async {
    final recipe = await _findRecipe(a['recipe_id'] as String?);
    if (recipe == null) return _notFound('Recipe', a['recipe_id'] as String?);
    if (_gate(FeaturesFlags.cookMode) ?? _gate(FeaturesFlags.cookTimers)
        case final gate?) {
      return gate;
    }
    final step = (_int(a['step']) ?? 1) - 1;
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

  /// Opens a support conversation as the support screen's form would:
  /// reason + message, signed with the same details, marked as coming
  /// through Shefi. Gated by the same two flags as the form and the chat.
  Future<ToolResult> _contactSupport(Map<String, dynamic> a) async {
    // The form's own cap on the message.
    final message = _text(a['message']);
    if (message.isEmpty) {
      return ToolResult.error('invalid', 'message is required');
    }
    final reason = FeedbackType.values
        .where((type) => type.name == a['reason'])
        .firstOrNull;
    if (reason == null) {
      return ToolResult.error('invalid', 'reason is not one of the list');
    }
    final repository = feedback;
    final session = AuthSessionService();
    final uid = session.user?.uid;
    if (repository == null ||
        uid == null ||
        !FeaturesFlags.feedback.isEnabled ||
        !FeaturesFlags.supportChat.isEnabled) {
      return ToolResult.error(
        'unavailable',
        'Support messages cannot be sent from here right now.',
      );
    }
    final details = await SupportDetails.collect();
    final id = await SendFeedbackUseCase(repository)(
      type: reason,
      message: message,
      authorUid: uid,
      authorName: session.profile?.fullName ?? '',
      authorEmail: session.profile?.email ?? session.user?.email,
      appVersion: details['version'],
      details: details,
      source: FeedbackSource.shefi,
    );
    return ToolResult.ok({
      'ticket_id': id,
      'reason': reason.name,
      'note':
          'Sent. The team answers in the app: support screen → my conversations, and a notification when they do.',
    });
  }

  Future<ToolResult> _openScreen(Map<String, dynamic> a) async {
    final screen = _title(a['screen']);
    if (!AssistantTools.screens.contains(screen)) {
      return ToolResult.error('invalid', 'No screen named "$screen"');
    }
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
    'ounce': 28.35,
    'oz': 28.35,
    'pound': 453.6,
    'lb': 453.6,
  };

  /// Spellings the model (or the user's words) send for the same unit:
  /// plurals, British spellings and the usual abbreviations.
  static const _unitAliases = <String, String>{
    'millilitre': 'milliliter',
    'mls': 'ml',
    'litre': 'liter',
    'ltr': 'liter',
    'tsps': 'tsp',
    'tbs': 'tbsp',
    'tbsps': 'tbsp',
    'tbl': 'tbsp',
    'gr': 'g',
    'grs': 'g',
    'kgs': 'kg',
    'kilo': 'kilogram',
    'kilos': 'kilogram',
    'kilogramme': 'kilogram',
    'gramme': 'gram',
    'lbs': 'lb',
    '°c': 'celsius',
    '°f': 'fahrenheit',
  };

  /// [raw] as a key of [_toMl] / [_toG] (or celsius / fahrenheit):
  /// "Cups" → cup, "tablespoons" → tablespoon, "grams" → gram.
  static String _unit(String raw) {
    final u = raw.trim().toLowerCase().replaceAll(RegExp(r'\.$'), '');
    String? known(String s) {
      if (_toMl.containsKey(s) || _toG.containsKey(s)) return s;
      if (s == 'celsius' || s == 'c' || s == 'fahrenheit' || s == 'f') {
        return s;
      }
      return _unitAliases[s];
    }

    return known(u) ??
        (u.endsWith('es') ? known(u.substring(0, u.length - 2)) : null) ??
        (u.endsWith('s') ? known(u.substring(0, u.length - 1)) : null) ??
        u;
  }

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
    final raw = a['amount'];
    final amount = raw is num
        ? raw.toDouble()
        : double.tryParse(raw?.toString().trim().replaceAll(',', '.') ?? '');
    final from = _unit(_title(a['from']));
    final to = _unit(_title(a['to']));
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
      final ingredient = _title(a['ingredient']).toLowerCase();
      // The longest name that matches: "brown sugar" before "sugar".
      final density =
          (_density.entries.where((e) => ingredient.contains(e.key)).toList()
                ..sort((x, y) => y.key.length.compareTo(x.key.length)))
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
    if (_gate(FeaturesFlags.nutrition) case final gate?) return gate;
    final recipe = await _findRecipe(a['recipe_id'] as String?);
    if (recipe == null) return _notFound('Recipe', a['recipe_id'] as String?);
    if (!recipe.canEdit) {
      return ToolResult.error('read_only', 'This recipe is view-only');
    }
    final estimate = await ingestion.estimateNutrition(recipe);
    // Only the estimate, onto the recipe as it is stored now: the model
    // call took seconds, and an edit saved meanwhile (here, or on the
    // website) must not be undone by the copy read before it.
    final fresh = await recipes.getRecipeById(recipe.id);
    if (fresh == null) return _notFound('Recipe', recipe.id);
    final estimated = fresh.copyWith(
      servings: estimate.servings,
      nutrition: estimate.nutrition,
    );
    await _saveRecipe(estimated);
    return ToolResult.ok(_recipeFull(estimated), card: RecipeCard(estimated));
  }

  // ---- Context for the system prompt ------------------------------------

  /// How many books or plans a listing tool hands the model.
  static const maxListedEntities = 100;

  /// The largest recipe multiplier `grocery_list_from_recipe` accepts.
  static const maxScale = 20.0;

  /// How many lines of a scoped grocery list go into the system prompt.
  static const scopedGroceryItemCap = 150;

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
        // Capped: a 600-line list would otherwise ride along on every turn.
        // Still-to-buy lines first, since those are what gets asked about;
        // the tools look items up by name in the whole list, so an unlisted
        // one can still be ticked or removed, and get_grocery_list reads it.
        final unchecked = l.items.where((i) => !i.isChecked);
        final checked = l.items.where((i) => i.isChecked);
        final shown = [
          ...unchecked,
          ...checked,
        ].take(scopedGroceryItemCap).toList();
        for (final i in shown) {
          b.writeln(
            '- ${i.isChecked ? '[x]' : '[ ]'} ${i.name} (item_id ${i.id})'
            '${i.totalAmount > 0 ? ': ${i.totalAmount} ${i.unit.name}' : ''}',
          );
        }
        final rest = l.items.length - shown.length;
        if (rest > 0) {
          final restUnchecked =
              unchecked.length - shown.where((i) => !i.isChecked).length;
          b.writeln(
            '...and $rest more items not listed here '
            '($restUnchecked still to buy, ${rest - restUnchecked} bought); '
            'call get_grocery_list to read them.',
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
