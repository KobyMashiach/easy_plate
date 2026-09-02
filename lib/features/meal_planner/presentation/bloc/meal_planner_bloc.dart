import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../my_recipes/domain/repositories/recipes_repository.dart';
import '../../domain/entities/meal_entity.dart';
import '../../domain/entities/meal_item_entity.dart';
import '../../domain/entities/meal_plan_entity.dart';
import '../../domain/usecases/delete_meal_plan_usecase.dart';
import '../../domain/usecases/get_meal_plans_usecase.dart';
import '../../domain/usecases/save_meal_plan_usecase.dart';

part 'meal_planner_bloc.freezed.dart';

@freezed
sealed class MealPlannerEvent with _$MealPlannerEvent {
  const factory MealPlannerEvent.init() = _Init;
  const factory MealPlannerEvent.createPlan(String name) = _CreatePlan;
  const factory MealPlannerEvent.selectPlan(String planId) = _SelectPlan;
  const factory MealPlannerEvent.deletePlan(String planId) = _DeletePlan;
  const factory MealPlannerEvent.addMeal(int weekday, String name) = _AddMeal;
  const factory MealPlannerEvent.removeMeal(String mealId) = _RemoveMeal;
  const factory MealPlannerEvent.addRecipeItem(String mealId, String recipeId) = _AddRecipeItem;
  const factory MealPlannerEvent.addFreeTextItem(String mealId, String text) = _AddFreeTextItem;
  const factory MealPlannerEvent.removeItem(String mealId, String itemId) = _RemoveItem;
}

@freezed
sealed class MealPlannerState with _$MealPlannerState {
  const factory MealPlannerState.loading() = MealPlannerLoading;
  const factory MealPlannerState.loaded(
    List<MealPlanEntity> plans, {
    MealPlanEntity? selectedPlan,
    @Default({}) Map<String, String> recipeTitles,
  }) = MealPlannerLoaded;
  const factory MealPlannerState.errorMessage(String error) = MealPlannerError;
}

class MealPlannerBloc extends Bloc<MealPlannerEvent, MealPlannerState> {
  final GetMealPlansUseCase getMealPlansUseCase;
  final SaveMealPlanUseCase saveMealPlanUseCase;
  final DeleteMealPlanUseCase deleteMealPlanUseCase;
  final RecipesRepository recipesRepository;
  static const _uuid = Uuid();

  MealPlannerBloc({
    required this.getMealPlansUseCase,
    required this.saveMealPlanUseCase,
    required this.deleteMealPlanUseCase,
    required this.recipesRepository,
  }) : super(const MealPlannerState.loading()) {
    on<_Init>(_init);
    on<_CreatePlan>(_createPlan);
    on<_SelectPlan>(_selectPlan);
    on<_DeletePlan>(_deletePlan);
    on<_AddMeal>(_addMeal);
    on<_RemoveMeal>(_removeMeal);
    on<_AddRecipeItem>(_addRecipeItem);
    on<_AddFreeTextItem>(_addFreeTextItem);
    on<_RemoveItem>(_removeItem);
    add(const MealPlannerEvent.init());
  }

  factory MealPlannerBloc.fromContext(BuildContext context) {
    return MealPlannerBloc(
      getMealPlansUseCase: GetMealPlansUseCase(context.read()),
      saveMealPlanUseCase: SaveMealPlanUseCase(context.read()),
      deleteMealPlanUseCase: DeleteMealPlanUseCase(context.read()),
      recipesRepository: context.read(),
    );
  }

  Future<Map<String, String>> _recipeTitles() async {
    final recipes = await recipesRepository.getRecipes();
    return {for (final recipe in recipes) recipe.id: recipe.title};
  }

  Future<void> _reload(Emitter<MealPlannerState> emit, {String? selectedPlanId}) async {
    try {
      final plans = await getMealPlansUseCase();
      final selectedId = selectedPlanId ??
          (state is MealPlannerLoaded ? (state as MealPlannerLoaded).selectedPlan?.id : null);
      final selected = plans.where((p) => p.id == selectedId).firstOrNull ?? plans.firstOrNull;
      emit(.loaded(plans, selectedPlan: selected, recipeTitles: await _recipeTitles()));
    } catch (e) {
      debugPrint('Meal planner error: $e');
      emit(.errorMessage(e.toString()));
    }
  }

  Future<void> _updateSelectedPlan(
    Emitter<MealPlannerState> emit,
    MealPlanEntity Function(MealPlanEntity plan) transform,
  ) async {
    final current = state;
    if (current is! MealPlannerLoaded || current.selectedPlan == null) return;
    final updated = transform(current.selectedPlan!);
    await saveMealPlanUseCase(updated);
    await _reload(emit, selectedPlanId: updated.id);
  }

  Future<void> _init(_Init event, Emitter<MealPlannerState> emit) => _reload(emit);

  Future<void> _createPlan(_CreatePlan event, Emitter<MealPlannerState> emit) async {
    final plan = MealPlanEntity(
      id: _uuid.v4(),
      name: event.name,
      meals: const [],
      createdAt: DateTime.now(),
    );
    await saveMealPlanUseCase(plan);
    await _reload(emit, selectedPlanId: plan.id);
  }

  Future<void> _selectPlan(_SelectPlan event, Emitter<MealPlannerState> emit) =>
      _reload(emit, selectedPlanId: event.planId);

  Future<void> _deletePlan(_DeletePlan event, Emitter<MealPlannerState> emit) async {
    await deleteMealPlanUseCase(event.planId);
    await _reload(emit);
  }

  Future<void> _addMeal(_AddMeal event, Emitter<MealPlannerState> emit) {
    return _updateSelectedPlan(emit, (plan) {
      final order = plan.mealsForWeekday(event.weekday).length;
      return plan.copyWith(meals: [
        ...plan.meals,
        MealEntity(
          id: _uuid.v4(),
          weekday: event.weekday,
          name: event.name,
          order: order,
          items: const [],
        ),
      ]);
    });
  }

  Future<void> _removeMeal(_RemoveMeal event, Emitter<MealPlannerState> emit) {
    return _updateSelectedPlan(
      emit,
      (plan) => plan.copyWith(meals: plan.meals.where((m) => m.id != event.mealId).toList()),
    );
  }

  MealPlanEntity _withItemAdded(MealPlanEntity plan, String mealId, MealItemEntity item) {
    return plan.copyWith(
      meals: plan.meals
          .map((meal) => meal.id == mealId ? meal.copyWith(items: [...meal.items, item]) : meal)
          .toList(),
    );
  }

  Future<void> _addRecipeItem(_AddRecipeItem event, Emitter<MealPlannerState> emit) {
    return _updateSelectedPlan(
      emit,
      (plan) => _withItemAdded(
        plan,
        event.mealId,
        MealItemEntity(id: _uuid.v4(), recipeId: event.recipeId),
      ),
    );
  }

  Future<void> _addFreeTextItem(_AddFreeTextItem event, Emitter<MealPlannerState> emit) {
    return _updateSelectedPlan(
      emit,
      (plan) => _withItemAdded(
        plan,
        event.mealId,
        MealItemEntity(id: _uuid.v4(), freeText: event.text),
      ),
    );
  }

  Future<void> _removeItem(_RemoveItem event, Emitter<MealPlannerState> emit) {
    return _updateSelectedPlan(emit, (plan) {
      return plan.copyWith(
        meals: plan.meals.map((meal) {
          if (meal.id != event.mealId) return meal;
          return meal.copyWith(items: meal.items.where((i) => i.id != event.itemId).toList());
        }).toList(),
      );
    });
  }
}
