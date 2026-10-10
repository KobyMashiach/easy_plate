import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/translation/content_changes.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_enums.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../meal_planner/domain/entities/meal_plan_entity.dart';
import '../../../meal_planner/domain/usecases/get_meal_plans_usecase.dart';
import '../../../meal_planner/domain/usecases/watch_meal_plans_usecase.dart';
import '../../../my_recipes/domain/entities/recipe_entity.dart';
import '../../data/datasources/active_grocery_list_store.dart';
import '../../domain/entities/grocery_item_entity.dart';
import '../../domain/entities/grocery_item_source_entity.dart';
import '../../domain/entities/grocery_list_entity.dart';
import '../../domain/usecases/build_aggregate_grocery_list_usecase.dart';
import '../../domain/usecases/create_recipe_grocery_list_usecase.dart';
import '../../domain/usecases/delete_grocery_list_usecase.dart';
import '../../domain/usecases/get_grocery_lists_usecase.dart';
import '../../domain/usecases/save_grocery_list_usecase.dart';
import '../../domain/usecases/watch_grocery_lists_usecase.dart';
import '../../../../core/hive/user_scope.dart';
import '../../../collab_containers/domain/container_sharing_service.dart';

part 'grocery_list_bloc.freezed.dart';

@freezed
sealed class GroceryListEvent with _$GroceryListEvent {
  const factory GroceryListEvent.init() = _Init;
  const factory GroceryListEvent.regenerate() = _Regenerate;
  const factory GroceryListEvent.selectPlans(List<String> planIds) =
      _SelectPlans;
  const factory GroceryListEvent.toggleItem(String itemId) = _ToggleItem;
  const factory GroceryListEvent.addAdHocItem(
    String name,
    double amount,
    MeasurementUnit unit,
  ) = _AddAdHocItem;
  const factory GroceryListEvent.removeItem(String itemId) = _RemoveItem;
  const factory GroceryListEvent.addBuffer(String itemId, double amount) =
      _AddBuffer;
  const factory GroceryListEvent.adjustSource(
    String itemId,
    int sourceIndex,
    double amount,
  ) = _AdjustSource;
  const factory GroceryListEvent.removeSource(String itemId, int sourceIndex) =
      _RemoveSource;
  const factory GroceryListEvent.changeUnit(
    String itemId,
    MeasurementUnit unit,
  ) = _ChangeUnit;
  const factory GroceryListEvent.setAllChecked(bool checked) = _SetAllChecked;
  const factory GroceryListEvent.deleteCheckedItems() = _DeleteCheckedItems;

  /// The plans box changed: the picker's choices have to follow it.
  const factory GroceryListEvent.plansChanged(List<MealPlanEntity> plans) =
      _PlansChanged;

  // ── Several lists ──────────────────────────────────────────────────────

  /// Opens another of the account's lists.
  const factory GroceryListEvent.selectList(String listId) = _SelectList;

  /// A new list fed by the meal plans, or an empty one filled by hand.
  /// Opens it; a plans list is built straight away.
  const factory GroceryListEvent.createList(
    String name,
    GroceryListSource source,
  ) = _CreateList;

  /// A new list holding [recipe]'s ingredients, [scale] times over. Opens it.
  const factory GroceryListEvent.createRecipeList(
    RecipeEntity recipe,
    String name,
    double scale,
  ) = _CreateRecipeList;

  const factory GroceryListEvent.renameList(String listId, String name) =
      _RenameList;
  const factory GroceryListEvent.deleteList(String listId) = _DeleteList;

  /// For a recipe list: how many times over to make the recipe. The
  /// recipe's lines are rescaled in place; checks and extra lines stay.
  const factory GroceryListEvent.setRecipeScale(double scale) = _SetRecipeScale;

  /// The lists box changed — for the switcher, and for a list deleted on
  /// another device.
  const factory GroceryListEvent.listsChanged(List<GroceryListEntity> lists) =
      _ListsChanged;

  /// Another screen made a different list the open one (a list created from
  /// a recipe's page).
  const factory GroceryListEvent.activeChanged(String listId) = _ActiveChanged;
}

@freezed
sealed class GroceryListState with _$GroceryListState {
  const factory GroceryListState.loading() = GroceryListLoading;

  /// [list] is the open list; [lists] all of the account's lists, oldest
  /// first, for the switcher.
  const factory GroceryListState.loaded(
    GroceryListEntity list, {
    @Default(<MealPlanEntity>[]) List<MealPlanEntity> plans,
    @Default(<GroceryListEntity>[]) List<GroceryListEntity> lists,
  }) = GroceryListLoaded;
  const factory GroceryListState.errorMessage(String error) = GroceryListError;
}

class GroceryListBloc extends Bloc<GroceryListEvent, GroceryListState> {
  StreamSubscription<void>? _contentChanges;
  StreamSubscription<List<MealPlanEntity>>? _plans;
  StreamSubscription<List<GroceryListEntity>>? _listsStream;
  StreamSubscription<String>? _activeStream;

  final GetGroceryListsUseCase getGroceryListsUseCase;
  final SaveGroceryListUseCase saveGroceryListUseCase;
  final DeleteGroceryListUseCase deleteGroceryListUseCase;
  final BuildAggregateGroceryListUseCase buildAggregateGroceryListUseCase;
  final CreateRecipeGroceryListUseCase createRecipeGroceryListUseCase;
  final GetMealPlansUseCase getMealPlansUseCase;
  final ActiveGroceryListStore activeListStore;

  /// Shared lists: the document behind a list another account can see.
  /// Null in tests.
  final ContainerSharingService? sharing;

  /// The plans as the box has them, for the picker. Null in tests.
  final WatchMealPlansUseCase? watchMealPlansUseCase;

  /// The lists as the box has them, for the switcher. Null in tests.
  final WatchGroceryListsUseCase? watchGroceryListsUseCase;

  static const _uuid = Uuid();

  /// The list every account had before there could be several: kept as the
  /// id of the first one, so an existing account opens on the list it
  /// already had.
  static const defaultListId = 'primary';

  /// The open list's id, as last read from or written to [activeListStore].
  String? _activeId;

  GroceryListBloc({
    required this.getGroceryListsUseCase,
    required this.saveGroceryListUseCase,
    required this.deleteGroceryListUseCase,
    required this.buildAggregateGroceryListUseCase,
    required this.createRecipeGroceryListUseCase,
    required this.getMealPlansUseCase,
    required this.activeListStore,
    this.sharing,
    this.watchMealPlansUseCase,
    this.watchGroceryListsUseCase,
  }) : super(const GroceryListState.loading()) {
    on<_Init>(_init);
    // A language switch rewrites every record at once; show it.
    _contentChanges = ContentChanges.instance.stream.listen(
      (_) => add(const _Init()),
    );
    on<_PlansChanged>(_plansChanged);
    // A plan created, renamed or deleted on the planner tab used to reach
    // the picker here only after a regenerate: the tab is kept alive and
    // read the plans once.
    _plans = watchMealPlansUseCase?.call().listen(
      (plans) => add(GroceryListEvent.plansChanged(plans)),
      onError: (Object e) => debugPrint('Plans stream failed: $e'),
    );
    on<_ListsChanged>(_listsChanged);
    _listsStream = watchGroceryListsUseCase?.call().listen(
      (lists) => add(GroceryListEvent.listsChanged(lists)),
      onError: (Object e) => debugPrint('Lists stream failed: $e'),
    );
    on<_ActiveChanged>(_activeChanged);
    _activeStream = activeListStore.changes.listen((id) {
      // This bloc's own switches set the id first; only a change made
      // somewhere else needs a reload.
      if (id != _activeId) add(GroceryListEvent.activeChanged(id));
    });
    on<_Regenerate>(_regenerate);
    on<_SelectPlans>(_selectPlans);
    on<_ToggleItem>(_toggleItem);
    on<_AddAdHocItem>(_addAdHocItem);
    on<_RemoveItem>(_removeItem);
    on<_AddBuffer>(_addBuffer);
    on<_AdjustSource>(_adjustSource);
    on<_RemoveSource>(_removeSource);
    on<_ChangeUnit>(_changeUnit);
    on<_SetAllChecked>(_setAllChecked);
    on<_DeleteCheckedItems>(_deleteCheckedItems);
    on<_SelectList>(_selectList);
    on<_CreateList>(_createList);
    on<_CreateRecipeList>(_createRecipeList);
    on<_RenameList>(_renameList);
    on<_DeleteList>(_deleteList);
    on<_SetRecipeScale>(_setRecipeScale);
    add(const GroceryListEvent.init());
  }

  factory GroceryListBloc.fromContext(BuildContext context) {
    final store = HiveActiveGroceryListStore.instance;
    return GroceryListBloc(
      getGroceryListsUseCase: GetGroceryListsUseCase(context.read()),
      saveGroceryListUseCase: SaveGroceryListUseCase(context.read()),
      deleteGroceryListUseCase: DeleteGroceryListUseCase(context.read()),
      buildAggregateGroceryListUseCase: BuildAggregateGroceryListUseCase(
        context.read(),
      ),
      createRecipeGroceryListUseCase: CreateRecipeGroceryListUseCase(
        context.read(),
        store,
      ),
      getMealPlansUseCase: GetMealPlansUseCase(context.read()),
      activeListStore: store,
      sharing: context.read(),
      watchMealPlansUseCase: WatchMealPlansUseCase(context.read()),
      watchGroceryListsUseCase: WatchGroceryListsUseCase(context.read()),
    );
  }

  static List<GroceryListEntity> _ordered(Iterable<GroceryListEntity> lists) =>
      lists.toList()..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  /// [lists] with [list] in it — replaced where it was, added if new.
  static List<GroceryListEntity> _withList(
    List<GroceryListEntity> lists,
    GroceryListEntity list,
  ) {
    final at = lists.indexWhere((l) => l.id == list.id);
    if (at == -1) return _ordered([...lists, list]);
    return [...lists]..[at] = list;
  }

  GroceryListEntity _newList(
    String name,
    GroceryListSource source, {
    String? id,
  }) => GroceryListEntity(
    id: id ?? _uuid.v4(),
    name: name.trim().isEmpty ? t.groceryList.defaultListName : name.trim(),
    items: const [],
    createdAt: DateTime.now(),
    source: source,
  );

  void _plansChanged(_PlansChanged event, Emitter<GroceryListState> emit) {
    final current = state;
    if (current is! GroceryListLoaded) return;
    emit(current.copyWith(plans: event.plans));
  }

  /// Keeps the switcher in step with the box. The open list itself is left
  /// as the state has it — this bloc's own writes land here a beat after
  /// they were shown, and taking them back would flicker a quick run of
  /// ticks — unless it is gone, deleted on another device.
  Future<void> _listsChanged(
    _ListsChanged event,
    Emitter<GroceryListState> emit,
  ) async {
    final current = state;
    if (current is! GroceryListLoaded) return;
    final lists = _ordered(event.lists);
    final fresh = lists.where((l) => l.id == current.list.id).firstOrNull;
    if (fresh != null || current.list.id == defaultListId) {
      // The open list keeps the version on screen while a write of this
      // bloc's own is in flight: the box echoes every write back, and taking
      // an older echo would revert a tap made in the meantime. Once nothing
      // is in flight, a box that differs from the screen was written by
      // someone else — a home-screen widget's quick add or tick, the share
      // itself giving the list its collab id — and is taken.
      final open =
          fresh != null &&
              (fresh.collabId != current.list.collabId ||
                  (_inflight == 0 &&
                      _signature(fresh) != _signature(current.list)))
          ? fresh
          : current.list;
      emit(current.copyWith(list: open, lists: _withList(lists, open)));
      return;
    }
    _activeId = null;
    await _load(emit);
  }

  Future<void> _activeChanged(
    _ActiveChanged event,
    Emitter<GroceryListState> emit,
  ) async {
    _activeId = event.listId;
    await _load(emit);
  }

  /// The open list: the one last chosen on this device, else the oldest,
  /// else a fresh meal-plan list (saved on its first write, as before).
  Future<({GroceryListEntity list, List<GroceryListEntity> lists})>
  _resolve() async {
    final lists = _ordered(await getGroceryListsUseCase());
    _activeId ??= await activeListStore.read();
    final list =
        lists.where((l) => l.id == _activeId).firstOrNull ??
        lists.where((l) => l.id == defaultListId).firstOrNull ??
        lists.firstOrNull ??
        _newList(
          t.groceryList.defaultListName,
          GroceryListSource.plans,
          id: defaultListId,
        );
    _activeId = list.id;
    return (list: list, lists: _withList(lists, list));
  }

  Future<GroceryListEntity> _currentList() async => (await _resolve()).list;

  /// Every write goes through here: the box, then — for a shared list —
  /// the shared document, so the other accounts see the change.
  Future<void> _save(GroceryListEntity list) async {
    _inflight++;
    try {
      await saveGroceryListUseCase(list);
    } finally {
      _inflight--;
    }
    final uid = UserScope().uid;
    if (!list.isShared || uid == null) return;
    try {
      await sharing?.lists.publish(list, uid: uid);
    } catch (e) {
      debugPrint('Shared list publish failed: $e');
    }
  }

  /// Writes of this bloc's own that the box has not echoed yet. While one
  /// is in flight an echo may be older than the screen, so the screen wins.
  int _inflight = 0;

  /// What the box holds versus what is on screen: the lines, their ticks,
  /// their amounts. Equal means the echo is this bloc's own write.
  static String _signature(GroceryListEntity l) => [
    l.name,
    l.recipeScale,
    for (final item in l.items) ...[
      item.id,
      item.name,
      item.isChecked,
      item.unit.name,
      item.category,
      for (final source in item.sources) ...[source.label, source.amount],
    ],
  ].join('\u0001');

  /// [syncShared] pulls the open list's shared document first, when it has
  /// one: opening a list is when another account's changes should show.
  Future<void> _load(
    Emitter<GroceryListState> emit, {
    bool syncShared = false,
  }) async {
    try {
      var resolved = await _resolve();
      final plans = await getMealPlansUseCase();
      // The local copy first — the screen must not wait on Firestore —
      // then the shared document, and the screen again if it changed.
      emit(.loaded(resolved.list, plans: plans, lists: resolved.lists));
      final uid = UserScope().uid;
      if (syncShared &&
          resolved.list.isShared &&
          uid != null &&
          sharing != null) {
        try {
          final before = resolved.list;
          final synced = await sharing!.lists.sync(before, uid: uid);
          if (identical(synced, before)) return;
          resolved = await _resolve();
          if (_activeId != resolved.list.id) return;
          emit(.loaded(resolved.list, plans: plans, lists: resolved.lists));
        } catch (e) {
          debugPrint('Shared list refresh failed: $e');
        }
      }
    } catch (e) {
      debugPrint('Grocery list error: $e');
      emit(.errorMessage(e.toString()));
    }
  }

  /// Meal plans are only reloaded where they might have changed; every other
  /// write reuses the ones already in state so the selector keeps its labels.
  Future<void> _persist(
    GroceryListEntity list,
    Emitter<GroceryListState> emit, {
    List<MealPlanEntity>? plans,
  }) async {
    // A read-only shared list: the page hides the actions, this is the
    // backstop.
    if (!list.canEdit) return;
    await _save(list);
    final current = state;
    final lists = current is GroceryListLoaded
        ? current.lists
        : const <GroceryListEntity>[];
    emit(
      .loaded(
        list,
        plans:
            plans ?? (current is GroceryListLoaded ? current.plans : const []),
        lists: _withList(lists, list),
      ),
    );
  }

  Future<void> _updateItem(
    Emitter<GroceryListState> emit,
    String itemId,
    GroceryItemEntity Function(GroceryItemEntity item) transform,
  ) async {
    final current = state;
    if (current is! GroceryListLoaded) return;
    if (!current.list.canEdit) return;
    final updated = current.list.copyWith(
      items: current.list.items
          .map((item) => item.id == itemId ? transform(item) : item)
          .toList(),
    );
    // Shown first, written after: a checkbox that waits for the disk (and
    // the cloud push queued behind it) reads as a tap that did not land.
    emit(
      current.copyWith(list: updated, lists: _withList(current.lists, updated)),
    );
    await _save(updated);
  }

  Future<void> _init(_Init event, Emitter<GroceryListState> emit) =>
      _load(emit, syncShared: true);

  /// Stores the choice and rebuilds straight away, so picking menus has a
  /// visible effect without a second tap on regenerate.
  Future<void> _selectPlans(
    _SelectPlans event,
    Emitter<GroceryListState> emit,
  ) async {
    final existing = await _currentList();
    await _save(
      existing.copyWith(selectedPlanIds: event.planIds),
    );
    await _regenerate(const _Regenerate(), emit);
  }

  /// Rebuilds the list from what it is made of — its meal plans, or its
  /// recipe — keeping the lines added by hand and whatever the shopper has
  /// already ticked. A hand-made list has nothing to rebuild from.
  Future<void> _regenerate(
    _Regenerate event,
    Emitter<GroceryListState> emit,
  ) async {
    final existing = await _currentList();
    final plans = await getMealPlansUseCase();

    final List<GroceryItemEntity> built;
    switch (existing.source) {
      case GroceryListSource.manual:
        await _persist(existing, emit, plans: plans);
        return;
      case GroceryListSource.recipe:
        final fromRecipe = existing.recipeId == null
            ? null
            : await buildAggregateGroceryListUseCase.forRecipe(
                existing.recipeId!,
                scale: existing.recipeScale,
              );
        // The recipe is gone, or was a community post never kept here:
        // the lines the list was made with are the best there is.
        if (fromRecipe == null) {
          await _persist(existing, emit, plans: plans);
          return;
        }
        built = fromRecipe;
      case GroceryListSource.plans:
        // An empty selection means "all plans", which is also what a plan
        // list that has since been deleted degrades to rather than an
        // empty basket.
        final selected = existing.includesAllPlans
            ? plans
            : plans
                  .where((p) => existing.selectedPlanIds.contains(p.id))
                  .toList();
        built = await buildAggregateGroceryListUseCase(selected);
    }

    final checkedIds = existing.items
        .where((i) => i.isChecked)
        .map((i) => i.id)
        .toSet();
    final adHocItems = existing.items.where((i) => i.isAdHoc).toList();

    final merged = [
      ...built.map(
        (item) => checkedIds.contains(item.id)
            ? item.copyWith(isChecked: true)
            : item,
      ),
      ...adHocItems,
    ];

    await _persist(existing.copyWith(items: merged), emit, plans: plans);
  }

  Future<void> _selectList(
    _SelectList event,
    Emitter<GroceryListState> emit,
  ) async {
    if (event.listId == _activeId && state is GroceryListLoaded) return;
    _activeId = event.listId;
    await activeListStore.write(event.listId);
    await _load(emit, syncShared: true);
  }

  Future<void> _createList(
    _CreateList event,
    Emitter<GroceryListState> emit,
  ) async {
    final list = _newList(event.name, event.source);
    _activeId = list.id;
    await _save(list);
    await activeListStore.write(list.id);
    if (list.canRegenerate) {
      // A plans list is only useful filled: built from every menu at once,
      // narrowed afterwards with the picker if need be.
      await _regenerate(const _Regenerate(), emit);
    } else {
      await _load(emit);
    }
  }

  Future<void> _createRecipeList(
    _CreateRecipeList event,
    Emitter<GroceryListState> emit,
  ) async {
    final list = await createRecipeGroceryListUseCase(
      event.recipe,
      name: event.name,
      scale: event.scale,
    );
    _activeId = list.id;
    await _load(emit);
  }

  Future<void> _renameList(
    _RenameList event,
    Emitter<GroceryListState> emit,
  ) async {
    final current = state;
    if (current is! GroceryListLoaded) return;
    final name = event.name.trim();
    if (name.isEmpty) return;
    final target = current.lists.where((l) => l.id == event.listId).firstOrNull;
    if (target == null || !target.canEdit) return;
    final renamed = target.copyWith(name: name);
    await _save(renamed);
    emit(
      current.copyWith(
        list: current.list.id == renamed.id ? renamed : current.list,
        lists: _withList(current.lists, renamed),
      ),
    );
  }

  /// Deleting the open list opens the oldest one left — or, with none
  /// left, a fresh meal-plan list.
  Future<void> _deleteList(
    _DeleteList event,
    Emitter<GroceryListState> emit,
  ) async {
    // The owner takes the shared document down with it; a member only
    // leaves.
    final current = state;
    final target = current is GroceryListLoaded
        ? current.lists.where((l) => l.id == event.listId).firstOrNull
        : null;
    final uid = UserScope().uid;
    if (target != null && target.isShared && uid != null) {
      await sharing?.lists.retire(target, uid: uid);
    }
    await deleteGroceryListUseCase(event.listId);
    if (event.listId == _activeId) {
      final remaining = _ordered(
        await getGroceryListsUseCase(),
      ).where((l) => l.id != event.listId);
      _activeId = remaining.firstOrNull?.id;
      if (_activeId != null) await activeListStore.write(_activeId!);
    }
    await _load(emit);
  }

  /// Rescales only the lines the recipe put there: a line's share from the
  /// recipe moves with the new scale, extra amounts and hand-added lines
  /// stay as the shopper left them. Works whether or not the recipe is
  /// still on this device.
  Future<void> _setRecipeScale(
    _SetRecipeScale event,
    Emitter<GroceryListState> emit,
  ) async {
    final current = state;
    if (current is! GroceryListLoaded) return;
    final list = current.list;
    if (list.source != GroceryListSource.recipe || event.scale <= 0) return;
    if (event.scale == list.recipeScale) return;
    final factor = event.scale / list.recipeScale;
    final rescaled = list.copyWith(
      recipeScale: event.scale,
      items: [
        for (final item in list.items)
          item.isAdHoc
              ? item
              : item.copyWith(
                  sources: [
                    for (final s in item.sources)
                      s.recipeId != null && s.recipeId == list.recipeId
                          ? GroceryItemSourceEntity(
                              recipeId: s.recipeId,
                              label: s.label,
                              amount: s.amount * factor,
                            )
                          : s,
                  ],
                ),
      ],
    );
    emit(
      current.copyWith(
        list: rescaled,
        lists: _withList(current.lists, rescaled),
      ),
    );
    await _save(rescaled);
  }

  Future<void> _toggleItem(_ToggleItem event, Emitter<GroceryListState> emit) {
    return _updateItem(
      emit,
      event.itemId,
      (item) => item.copyWith(isChecked: !item.isChecked),
    );
  }

  /// Ad-hoc lines get a single manual source so they carry a quantity and can
  /// be edited through exactly the same breakdown sheet as recipe-derived ones.
  Future<void> _addAdHocItem(
    _AddAdHocItem event,
    Emitter<GroceryListState> emit,
  ) async {
    final current = state;
    if (current is! GroceryListLoaded) return;
    final item = GroceryItemEntity(
      id: _uuid.v4(),
      name: event.name,
      unit: event.unit,
      sources: [
        GroceryItemSourceEntity(label: event.name, amount: event.amount),
      ],
      category: 'כללי',
      isAdHoc: true,
    );
    await _persist(
      current.list.copyWith(items: [...current.list.items, item]),
      emit,
    );
  }

  /// Drops one contributing source, but never the last one — an item with no
  /// sources would silently lose its quantity.
  Future<void> _removeSource(
    _RemoveSource event,
    Emitter<GroceryListState> emit,
  ) {
    return _updateItem(emit, event.itemId, (item) {
      if (item.sources.length <= 1) return item;
      if (event.sourceIndex < 0 || event.sourceIndex >= item.sources.length) {
        return item;
      }
      final sources = [...item.sources]..removeAt(event.sourceIndex);
      return item.copyWith(sources: sources);
    });
  }

  Future<void> _changeUnit(_ChangeUnit event, Emitter<GroceryListState> emit) {
    return _updateItem(
      emit,
      event.itemId,
      (item) => item.copyWith(unit: event.unit),
    );
  }

  Future<void> _setAllChecked(
    _SetAllChecked event,
    Emitter<GroceryListState> emit,
  ) async {
    final current = state;
    if (current is! GroceryListLoaded) return;
    await _persist(
      current.list.copyWith(
        items: current.list.items
            .map((i) => i.copyWith(isChecked: event.checked))
            .toList(),
      ),
      emit,
    );
  }

  Future<void> _deleteCheckedItems(
    _DeleteCheckedItems event,
    Emitter<GroceryListState> emit,
  ) async {
    final current = state;
    if (current is! GroceryListLoaded) return;
    await _persist(
      current.list.copyWith(
        items: current.list.items.where((i) => !i.isChecked).toList(),
      ),
      emit,
    );
  }

  Future<void> _removeItem(
    _RemoveItem event,
    Emitter<GroceryListState> emit,
  ) async {
    final current = state;
    if (current is! GroceryListLoaded) return;
    await _persist(
      current.list.copyWith(
        items: current.list.items.where((i) => i.id != event.itemId).toList(),
      ),
      emit,
    );
  }

  Future<void> _addBuffer(_AddBuffer event, Emitter<GroceryListState> emit) {
    return _updateItem(emit, event.itemId, (item) {
      return item.copyWith(
        sources: [
          ...item.sources,
          GroceryItemSourceEntity(label: 'תוספת', amount: event.amount),
        ],
      );
    });
  }

  Future<void> _adjustSource(
    _AdjustSource event,
    Emitter<GroceryListState> emit,
  ) {
    return _updateItem(emit, event.itemId, (item) {
      final sources = [...item.sources];
      if (event.sourceIndex < 0 || event.sourceIndex >= sources.length) {
        return item;
      }
      final source = sources[event.sourceIndex];
      sources[event.sourceIndex] = GroceryItemSourceEntity(
        recipeId: source.recipeId,
        label: source.label,
        amount: event.amount,
      );
      return item.copyWith(sources: sources);
    });
  }

  @override
  Future<void> close() async {
    await _contentChanges?.cancel();
    await _plans?.cancel();
    await _listsStream?.cancel();
    await _activeStream?.cancel();
    return super.close();
  }
}
