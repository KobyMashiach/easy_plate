import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_enums.dart';
import '../../../meal_planner/domain/usecases/get_meal_plans_usecase.dart';
import '../../domain/entities/grocery_item_entity.dart';
import '../../domain/entities/grocery_item_source_entity.dart';
import '../../domain/entities/grocery_list_entity.dart';
import '../../domain/usecases/build_aggregate_grocery_list_usecase.dart';
import '../../domain/usecases/get_grocery_lists_usecase.dart';
import '../../domain/usecases/save_grocery_list_usecase.dart';

part 'grocery_list_bloc.freezed.dart';

@freezed
sealed class GroceryListEvent with _$GroceryListEvent {
  const factory GroceryListEvent.init() = _Init;
  const factory GroceryListEvent.regenerate() = _Regenerate;
  const factory GroceryListEvent.toggleItem(String itemId) = _ToggleItem;
  const factory GroceryListEvent.addAdHocItem(
    String name,
    double amount,
    MeasurementUnit unit,
  ) = _AddAdHocItem;
  const factory GroceryListEvent.removeItem(String itemId) = _RemoveItem;
  const factory GroceryListEvent.addBuffer(String itemId, double amount) = _AddBuffer;
  const factory GroceryListEvent.adjustSource(String itemId, int sourceIndex, double amount) =
      _AdjustSource;
  const factory GroceryListEvent.removeSource(String itemId, int sourceIndex) = _RemoveSource;
  const factory GroceryListEvent.changeUnit(String itemId, MeasurementUnit unit) = _ChangeUnit;
  const factory GroceryListEvent.setAllChecked(bool checked) = _SetAllChecked;
  const factory GroceryListEvent.deleteCheckedItems() = _DeleteCheckedItems;
}

@freezed
sealed class GroceryListState with _$GroceryListState {
  const factory GroceryListState.loading() = GroceryListLoading;
  const factory GroceryListState.loaded(GroceryListEntity list) = GroceryListLoaded;
  const factory GroceryListState.errorMessage(String error) = GroceryListError;
}

class GroceryListBloc extends Bloc<GroceryListEvent, GroceryListState> {
  final GetGroceryListsUseCase getGroceryListsUseCase;
  final SaveGroceryListUseCase saveGroceryListUseCase;
  final BuildAggregateGroceryListUseCase buildAggregateGroceryListUseCase;
  final GetMealPlansUseCase getMealPlansUseCase;
  static const _uuid = Uuid();
  static const _defaultListId = 'primary';

  GroceryListBloc({
    required this.getGroceryListsUseCase,
    required this.saveGroceryListUseCase,
    required this.buildAggregateGroceryListUseCase,
    required this.getMealPlansUseCase,
  }) : super(const GroceryListState.loading()) {
    on<_Init>(_init);
    on<_Regenerate>(_regenerate);
    on<_ToggleItem>(_toggleItem);
    on<_AddAdHocItem>(_addAdHocItem);
    on<_RemoveItem>(_removeItem);
    on<_AddBuffer>(_addBuffer);
    on<_AdjustSource>(_adjustSource);
    on<_RemoveSource>(_removeSource);
    on<_ChangeUnit>(_changeUnit);
    on<_SetAllChecked>(_setAllChecked);
    on<_DeleteCheckedItems>(_deleteCheckedItems);
    add(const GroceryListEvent.init());
  }

  factory GroceryListBloc.fromContext(BuildContext context) {
    return GroceryListBloc(
      getGroceryListsUseCase: GetGroceryListsUseCase(context.read()),
      saveGroceryListUseCase: SaveGroceryListUseCase(context.read()),
      buildAggregateGroceryListUseCase: BuildAggregateGroceryListUseCase(context.read()),
      getMealPlansUseCase: GetMealPlansUseCase(context.read()),
    );
  }

  Future<GroceryListEntity> _currentList() async {
    final lists = await getGroceryListsUseCase();
    return lists.where((l) => l.id == _defaultListId).firstOrNull ??
        GroceryListEntity(
          id: _defaultListId,
          name: 'רשימת קניות',
          items: const [],
          createdAt: DateTime.now(),
        );
  }

  Future<void> _persist(GroceryListEntity list, Emitter<GroceryListState> emit) async {
    await saveGroceryListUseCase(list);
    emit(.loaded(list));
  }

  Future<void> _updateItem(
    Emitter<GroceryListState> emit,
    String itemId,
    GroceryItemEntity Function(GroceryItemEntity item) transform,
  ) async {
    final current = state;
    if (current is! GroceryListLoaded) return;
    final updated = current.list.copyWith(
      items: current.list.items.map((item) => item.id == itemId ? transform(item) : item).toList(),
    );
    await _persist(updated, emit);
  }

  Future<void> _init(_Init event, Emitter<GroceryListState> emit) async {
    try {
      emit(.loaded(await _currentList()));
    } catch (e) {
      debugPrint('Grocery list error: $e');
      emit(.errorMessage(e.toString()));
    }
  }

  /// Rebuilds the aggregated lines from the active meal plans while keeping
  /// ad-hoc products and any already-checked state the shopper has set.
  Future<void> _regenerate(_Regenerate event, Emitter<GroceryListState> emit) async {
    final existing = await _currentList();
    final plans = await getMealPlansUseCase();
    final aggregated = await buildAggregateGroceryListUseCase(plans);

    final checkedIds = existing.items.where((i) => i.isChecked).map((i) => i.id).toSet();
    final adHocItems = existing.items.where((i) => i.isAdHoc).toList();

    final merged = [
      ...aggregated.map(
        (item) => checkedIds.contains(item.id) ? item.copyWith(isChecked: true) : item,
      ),
      ...adHocItems,
    ];

    await _persist(existing.copyWith(items: merged), emit);
  }

  Future<void> _toggleItem(_ToggleItem event, Emitter<GroceryListState> emit) {
    return _updateItem(emit, event.itemId, (item) => item.copyWith(isChecked: !item.isChecked));
  }

  /// Ad-hoc lines get a single manual source so they carry a quantity and can
  /// be edited through exactly the same breakdown sheet as recipe-derived ones.
  Future<void> _addAdHocItem(_AddAdHocItem event, Emitter<GroceryListState> emit) async {
    final current = state;
    if (current is! GroceryListLoaded) return;
    final item = GroceryItemEntity(
      id: _uuid.v4(),
      name: event.name,
      unit: event.unit,
      sources: [GroceryItemSourceEntity(label: event.name, amount: event.amount)],
      category: 'כללי',
      isAdHoc: true,
    );
    await _persist(current.list.copyWith(items: [...current.list.items, item]), emit);
  }

  /// Drops one contributing source, but never the last one — an item with no
  /// sources would silently lose its quantity.
  Future<void> _removeSource(_RemoveSource event, Emitter<GroceryListState> emit) {
    return _updateItem(emit, event.itemId, (item) {
      if (item.sources.length <= 1) return item;
      if (event.sourceIndex < 0 || event.sourceIndex >= item.sources.length) return item;
      final sources = [...item.sources]..removeAt(event.sourceIndex);
      return item.copyWith(sources: sources);
    });
  }

  Future<void> _changeUnit(_ChangeUnit event, Emitter<GroceryListState> emit) {
    return _updateItem(emit, event.itemId, (item) => item.copyWith(unit: event.unit));
  }

  Future<void> _setAllChecked(_SetAllChecked event, Emitter<GroceryListState> emit) async {
    final current = state;
    if (current is! GroceryListLoaded) return;
    await _persist(
      current.list.copyWith(
        items: current.list.items.map((i) => i.copyWith(isChecked: event.checked)).toList(),
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

  Future<void> _removeItem(_RemoveItem event, Emitter<GroceryListState> emit) async {
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
      return item.copyWith(sources: [
        ...item.sources,
        GroceryItemSourceEntity(label: 'תוספת', amount: event.amount),
      ]);
    });
  }

  Future<void> _adjustSource(_AdjustSource event, Emitter<GroceryListState> emit) {
    return _updateItem(emit, event.itemId, (item) {
      final sources = [...item.sources];
      if (event.sourceIndex < 0 || event.sourceIndex >= sources.length) return item;
      final source = sources[event.sourceIndex];
      sources[event.sourceIndex] = GroceryItemSourceEntity(
        recipeId: source.recipeId,
        label: source.label,
        amount: event.amount,
      );
      return item.copyWith(sources: sources);
    });
  }
}
