import 'package:uuid/uuid.dart';

import '../../../core/constants/app_enums.dart';
import '../../grocery_list/domain/entities/grocery_item_entity.dart';
import '../../grocery_list/domain/entities/grocery_item_source_entity.dart';
import '../../grocery_list/domain/entities/grocery_list_entity.dart';
import '../../grocery_list/domain/repositories/grocery_lists_repository.dart';
import '../../meal_planner/domain/entities/meal_entity.dart';
import '../../meal_planner/domain/entities/meal_item_entity.dart';
import '../../meal_planner/domain/entities/meal_plan_entity.dart';
import '../../meal_planner/domain/repositories/meal_plans_repository.dart';
import '../../my_recipes/domain/entities/recipe_ingredient_entity.dart';
import '../../recipe_books/domain/entities/book_recipe_ref_entity.dart';
import '../../recipe_books/domain/entities/book_spine.dart';
import '../../recipe_books/domain/entities/recipe_book_entity.dart';
import '../../recipe_books/domain/repositories/recipe_books_repository.dart';
import 'entities/collab_container_entity.dart';

/// What the sharing flow needs to know about a book or a plan, so one set of
/// use cases serves both. Each side keeps its own store; this is the seam.
///
/// Recipes travel by collab id, never by local id: a local id means nothing
/// on another account. [encode] is handed the mapping for this account and
/// [decode] the reverse one, built by the caller from the local recipe box.
abstract class ContainerAdapter<T> {
  CollabKind get kind;

  String idOf(T item);
  String? collabIdOf(T item);
  CollabRole? roleOf(T item);
  String titleOf(T item);

  /// The local recipe ids the item points at.
  List<String> recipeIdsOf(T item);

  T withCollab(T item, {required String collabId, required CollabRole role});
  T withoutCollab(T item);

  Map<String, dynamic> encode(
    T item, {
    required Map<String, String> collabIdByRecipeId,
    required Map<String, String> titles,
  });

  /// The shared document laid over [local] — its id, creation time and
  /// whatever is private to this copy are kept; everything shared is taken
  /// from the document. A null [local] builds a fresh item.
  T decode(
    CollabContainerEntity container, {
    required T? local,
    required Map<String, String> recipeIdByCollabId,
    required String uid,
  });

  Future<List<T>> all();
  Future<T?> byId(String id);
  Future<void> save(T item);

  bool isShared(T item) => collabIdOf(item) != null;
  bool isMine(T item) =>
      roleOf(item) == null || roleOf(item) == CollabRole.owner;
}

const _uuid = Uuid();

List<Map<String, dynamic>> _encodeIngredients(
  List<RecipeIngredientEntity> ingredients,
) => [
  for (final i in ingredients)
    {'name': i.name, 'amount': i.amount, 'unit': i.unit.name},
];

List<RecipeIngredientEntity> _decodeIngredients(Object? raw) => [
  for (final item in (raw as List?) ?? const [])
    if (item is Map)
      RecipeIngredientEntity(
        name: (item['name'] as String?) ?? '',
        amount: (item['amount'] as num?)?.toDouble(),
        unit: MeasurementUnit.values.firstWhere(
          (u) => u.name == item['unit'],
          orElse: () => MeasurementUnit.unspecified,
        ),
      ),
];

class BookContainerAdapter extends ContainerAdapter<RecipeBookEntity> {
  final RecipeBooksRepository books;
  BookContainerAdapter(this.books);

  @override
  CollabKind get kind => CollabKind.book;
  @override
  String idOf(RecipeBookEntity item) => item.id;
  @override
  String? collabIdOf(RecipeBookEntity item) => item.collabId;
  @override
  CollabRole? roleOf(RecipeBookEntity item) => item.collabRole;
  @override
  String titleOf(RecipeBookEntity item) => item.title;
  @override
  List<String> recipeIdsOf(RecipeBookEntity item) => [
    for (final r in item.orderedRefs) r.recipeId,
  ];

  @override
  RecipeBookEntity withCollab(
    RecipeBookEntity item, {
    required String collabId,
    required CollabRole role,
  }) => item.copyWith(collabId: collabId, collabRole: role);
  @override
  RecipeBookEntity withoutCollab(RecipeBookEntity item) =>
      item.copyWith(clearCollab: true);

  @override
  Map<String, dynamic> encode(
    RecipeBookEntity item, {
    required Map<String, String> collabIdByRecipeId,
    required Map<String, String> titles,
  }) {
    final refs = item.orderedRefs;
    return {
      'coverImageFileName': item.coverImageFileName,
      'coverImageStoragePath': item.coverImageStoragePath,
      'spine': item.spine?.name,
      'recipes': [
        // A recipe that cannot be shared (see RecipeLinker) simply is not in
        // the shared book; the owner's own copy keeps it.
        for (final ref in refs)
          if (collabIdByRecipeId[ref.recipeId] case final collabId?)
            {'collabId': collabId, 'order': ref.order},
      ],
    };
  }

  @override
  RecipeBookEntity decode(
    CollabContainerEntity container, {
    required RecipeBookEntity? local,
    required Map<String, String> recipeIdByCollabId,
    required String uid,
  }) {
    final content = container.content;
    final remotePath = content['coverImageStoragePath'] as String?;
    final refs = <BookRecipeRefEntity>[];
    for (final raw in (content['recipes'] as List?) ?? const []) {
      if (raw is! Map) continue;
      final localId = recipeIdByCollabId[raw['collabId']];
      if (localId == null) continue;
      refs.add(
        BookRecipeRefEntity(
          recipeId: localId,
          order: (raw['order'] as num?)?.toInt() ?? refs.length,
        ),
      );
    }
    return RecipeBookEntity(
      id: local?.id ?? _uuid.v4(),
      title: container.title,
      recipeRefs: refs,
      collaborators: local?.collaborators ?? const {},
      // The shared cover wins when it has travelled; one this copy picked on
      // its own is kept when the document carries none — as with a recipe.
      coverImageFileName: remotePath != null
          ? content['coverImageFileName'] as String?
          : local?.coverImageFileName,
      coverImageStoragePath: remotePath ?? local?.coverImageStoragePath,
      spine: BookSpine.fromName(content['spine'] as String?) ?? local?.spine,
      collabId: container.id,
      collabRole: container.roleOf(uid),
      createdAt: local?.createdAt ?? DateTime.now(),
    );
  }

  @override
  Future<List<RecipeBookEntity>> all() => books.getBooks();
  @override
  Future<RecipeBookEntity?> byId(String id) => books.getBookById(id);
  @override
  Future<void> save(RecipeBookEntity item) => books.saveBook(item);
}

class PlanContainerAdapter extends ContainerAdapter<MealPlanEntity> {
  final MealPlansRepository plans;
  PlanContainerAdapter(this.plans);

  @override
  CollabKind get kind => CollabKind.mealPlan;
  @override
  String idOf(MealPlanEntity item) => item.id;
  @override
  String? collabIdOf(MealPlanEntity item) => item.collabId;
  @override
  CollabRole? roleOf(MealPlanEntity item) => item.collabRole;
  @override
  String titleOf(MealPlanEntity item) => item.name;
  @override
  List<String> recipeIdsOf(MealPlanEntity item) => [
    for (final meal in item.meals)
      for (final i in meal.items) ?i.recipeId,
  ];

  @override
  MealPlanEntity withCollab(
    MealPlanEntity item, {
    required String collabId,
    required CollabRole role,
  }) => item.copyWith(collabId: collabId, collabRole: role);
  @override
  MealPlanEntity withoutCollab(MealPlanEntity item) =>
      item.copyWith(clearCollab: true);

  @override
  Map<String, dynamic> encode(
    MealPlanEntity item, {
    required Map<String, String> collabIdByRecipeId,
    required Map<String, String> titles,
  }) {
    return {
      'meals': [
        for (final meal in item.meals)
          {
            'id': meal.id,
            'weekday': meal.weekday,
            'name': meal.name,
            'order': meal.order,
            'items': [
              for (final i in meal.items)
                {
                  'id': i.id,
                  // A recipe that cannot be shared goes across as a quick
                  // entry under its title, so the other side still sees
                  // what the meal is.
                  'recipeCollabId': i.recipeId == null
                      ? null
                      : collabIdByRecipeId[i.recipeId],
                  'label': i.recipeId == null
                      ? i.freeText
                      : (titles[i.recipeId] ?? i.freeText),
                  'freeText': i.freeText,
                  'ingredients': _encodeIngredients(i.ingredients),
                },
            ],
          },
      ],
    };
  }

  @override
  MealPlanEntity decode(
    CollabContainerEntity container, {
    required MealPlanEntity? local,
    required Map<String, String> recipeIdByCollabId,
    required String uid,
  }) {
    final meals = <MealEntity>[];
    for (final raw in (container.content['meals'] as List?) ?? const []) {
      if (raw is! Map) continue;
      final items = <MealItemEntity>[];
      for (final rawItem in (raw['items'] as List?) ?? const []) {
        if (rawItem is! Map) continue;
        final localId = recipeIdByCollabId[rawItem['recipeCollabId']];
        items.add(
          localId != null
              ? MealItemEntity(
                  id: (rawItem['id'] as String?) ?? _uuid.v4(),
                  recipeId: localId,
                )
              : MealItemEntity(
                  id: (rawItem['id'] as String?) ?? _uuid.v4(),
                  freeText:
                      (rawItem['freeText'] as String?) ??
                      (rawItem['label'] as String?) ??
                      '',
                  ingredients: _decodeIngredients(rawItem['ingredients']),
                ),
        );
      }
      meals.add(
        MealEntity(
          id: (raw['id'] as String?) ?? _uuid.v4(),
          weekday: (raw['weekday'] as num?)?.toInt() ?? 0,
          name: (raw['name'] as String?) ?? '',
          order: (raw['order'] as num?)?.toInt() ?? meals.length,
          items: items,
        ),
      );
    }
    return MealPlanEntity(
      id: local?.id ?? _uuid.v4(),
      name: container.title,
      meals: meals,
      collabId: container.id,
      collabRole: container.roleOf(uid),
      createdAt: local?.createdAt ?? DateTime.now(),
    );
  }

  @override
  Future<List<MealPlanEntity>> all() => plans.getPlans();
  @override
  Future<MealPlanEntity?> byId(String id) => plans.getPlanById(id);
  @override
  Future<void> save(MealPlanEntity item) => plans.savePlan(item);
}

/// A grocery list travels as written: every line with its amounts, ticks
/// and category. Nothing is linked — a line's recipe source is a label to
/// the other side, and the list it came from (a plan, a recipe) stays a
/// fact about the owner's copy only.
class GroceryListContainerAdapter extends ContainerAdapter<GroceryListEntity> {
  final GroceryListsRepository lists;
  GroceryListContainerAdapter(this.lists);

  @override
  CollabKind get kind => CollabKind.groceryList;
  @override
  String idOf(GroceryListEntity item) => item.id;
  @override
  String? collabIdOf(GroceryListEntity item) => item.collabId;
  @override
  CollabRole? roleOf(GroceryListEntity item) => item.collabRole;
  @override
  String titleOf(GroceryListEntity item) => item.name;
  @override
  List<String> recipeIdsOf(GroceryListEntity item) => const [];

  @override
  GroceryListEntity withCollab(
    GroceryListEntity item, {
    required String collabId,
    required CollabRole role,
  }) => item.copyWith(collabId: collabId, collabRole: role);
  @override
  GroceryListEntity withoutCollab(GroceryListEntity item) =>
      item.copyWith(clearCollab: true);

  @override
  Map<String, dynamic> encode(
    GroceryListEntity item, {
    required Map<String, String> collabIdByRecipeId,
    required Map<String, String> titles,
  }) {
    return {
      'items': [
        for (final line in item.items)
          {
            'id': line.id,
            'name': line.name,
            'unit': line.unit.name,
            'category': line.category,
            'isChecked': line.isChecked,
            'isAdHoc': line.isAdHoc,
            'sources': [
              for (final source in line.sources)
                {'label': source.label, 'amount': source.amount},
            ],
          },
      ],
    };
  }

  @override
  GroceryListEntity decode(
    CollabContainerEntity container, {
    required GroceryListEntity? local,
    required Map<String, String> recipeIdByCollabId,
    required String uid,
  }) {
    final items = <GroceryItemEntity>[];
    for (final raw in (container.content['items'] as List?) ?? const []) {
      if (raw is! Map) continue;
      final sources = <GroceryItemSourceEntity>[];
      for (final rawSource in (raw['sources'] as List?) ?? const []) {
        if (rawSource is! Map) continue;
        sources.add(
          GroceryItemSourceEntity(
            label: (rawSource['label'] as String?) ?? '',
            amount: (rawSource['amount'] as num?)?.toDouble() ?? 0,
          ),
        );
      }
      items.add(
        GroceryItemEntity(
          id: (raw['id'] as String?) ?? _uuid.v4(),
          name: (raw['name'] as String?) ?? '',
          unit: MeasurementUnit.values.firstWhere(
            (u) => u.name == raw['unit'],
            orElse: () => MeasurementUnit.unspecified,
          ),
          sources: sources,
          category: (raw['category'] as String?) ?? '',
          isChecked: raw['isChecked'] == true,
          isAdHoc: raw['isAdHoc'] == true,
        ),
      );
    }
    // A member's copy is hand-made as far as rebuilding goes: the plans or
    // the recipe it was built from live on the owner's account. The owner's
    // own copy keeps its source and can still be rebuilt.
    final mine = container.roleOf(uid) == CollabRole.owner;
    return GroceryListEntity(
      id: local?.id ?? _uuid.v4(),
      name: container.title,
      items: items,
      collaborators: local?.collaborators ?? const {},
      selectedPlanIds: mine ? (local?.selectedPlanIds ?? const []) : const [],
      createdAt: local?.createdAt ?? DateTime.now(),
      contentLang: local?.contentLang,
      contentVersion: local?.contentVersion ?? 0,
      source: mine
          ? (local?.source ?? GroceryListSource.manual)
          : GroceryListSource.manual,
      recipeId: mine ? local?.recipeId : null,
      recipeScale: mine ? (local?.recipeScale ?? 1) : 1,
      recipeServings: mine ? local?.recipeServings : null,
      recipeTitle: mine ? local?.recipeTitle : null,
      collabId: container.id,
      collabRole: container.roleOf(uid),
    );
  }

  @override
  Future<List<GroceryListEntity>> all() => lists.getLists();
  @override
  Future<GroceryListEntity?> byId(String id) => lists.getListById(id);
  @override
  Future<void> save(GroceryListEntity item) =>
      lists.saveList(item, stampLanguage: false);
}
