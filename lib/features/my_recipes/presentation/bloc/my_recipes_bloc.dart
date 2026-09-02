import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/constants/app_enums.dart';
import '../../domain/entities/recipe_entity.dart';
import '../../domain/usecases/delete_recipe_usecase.dart';
import '../../domain/usecases/get_recipes_usecase.dart';

part 'my_recipes_bloc.freezed.dart';

@freezed
sealed class MyRecipesEvent with _$MyRecipesEvent {
  const factory MyRecipesEvent.init() = _Init;
  const factory MyRecipesEvent.search(String query) = _Search;
  const factory MyRecipesEvent.filterByDietary(List<DietaryPreference> preferences) = _FilterByDietary;
  const factory MyRecipesEvent.deleteRecipe(String id) = _DeleteRecipe;
}

@freezed
sealed class MyRecipesState with _$MyRecipesState {
  const factory MyRecipesState.loading() = MyRecipesLoading;
  const factory MyRecipesState.loaded(
    List<RecipeEntity> recipes, {
    @Default('') String query,
    @Default([]) List<DietaryPreference> dietaryFilters,
  }) = MyRecipesLoaded;
  const factory MyRecipesState.errorMessage(String error) = MyRecipesError;
}

class MyRecipesBloc extends Bloc<MyRecipesEvent, MyRecipesState> {
  final GetRecipesUseCase getRecipesUseCase;
  final DeleteRecipeUseCase deleteRecipeUseCase;
  List<RecipeEntity> _allRecipes = [];

  MyRecipesBloc({required this.getRecipesUseCase, required this.deleteRecipeUseCase})
      : super(const MyRecipesState.loading()) {
    on<_Init>(_init);
    on<_Search>(_search);
    on<_FilterByDietary>(_filterByDietary);
    on<_DeleteRecipe>(_deleteRecipe);
    add(const MyRecipesEvent.init());
  }

  factory MyRecipesBloc.fromContext(BuildContext context) {
    return MyRecipesBloc(
      getRecipesUseCase: GetRecipesUseCase(context.read()),
      deleteRecipeUseCase: DeleteRecipeUseCase(context.read()),
    );
  }

  List<RecipeEntity> _applyFilters(String query, List<DietaryPreference> filters) {
    return _allRecipes.where((recipe) {
      final matchesQuery = query.isEmpty || recipe.title.toLowerCase().contains(query.toLowerCase());
      final matchesDietary = filters.isEmpty || filters.every((f) => recipe.dietaryTags.contains(f));
      return matchesQuery && matchesDietary;
    }).toList();
  }

  Future<void> _init(_Init event, Emitter<MyRecipesState> emit) async {
    try {
      _allRecipes = await getRecipesUseCase();
      emit(.loaded(_allRecipes));
    } catch (e) {
      debugPrint('My recipes error: $e');
      emit(.errorMessage(e.toString()));
    }
  }

  Future<void> _search(_Search event, Emitter<MyRecipesState> emit) async {
    final current = state;
    if (current is! MyRecipesLoaded) return;
    emit(.loaded(
      _applyFilters(event.query, current.dietaryFilters),
      query: event.query,
      dietaryFilters: current.dietaryFilters,
    ));
  }

  Future<void> _filterByDietary(_FilterByDietary event, Emitter<MyRecipesState> emit) async {
    final current = state;
    if (current is! MyRecipesLoaded) return;
    emit(.loaded(
      _applyFilters(current.query, event.preferences),
      query: current.query,
      dietaryFilters: event.preferences,
    ));
  }

  Future<void> _deleteRecipe(_DeleteRecipe event, Emitter<MyRecipesState> emit) async {
    await deleteRecipeUseCase(event.id);
    _allRecipes = _allRecipes.where((r) => r.id != event.id).toList();
    final current = state;
    if (current is! MyRecipesLoaded) return;
    emit(.loaded(
      _applyFilters(current.query, current.dietaryFilters),
      query: current.query,
      dietaryFilters: current.dietaryFilters,
    ));
  }
}
