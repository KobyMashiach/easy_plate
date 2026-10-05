import '../entities/meal_plan_entity.dart';

abstract class MealPlansRepository {
  Future<List<MealPlanEntity>> getPlans();

  /// The plans, kept current as they are written from anywhere — the
  /// planner tab itself, an accepted invite, the resume refresh. Both the
  /// planner and the grocery list's plan picker follow it.
  Stream<List<MealPlanEntity>> watchPlans();
  Future<MealPlanEntity?> getPlanById(String id);

  /// See [RecipesRepository.saveRecipe] for [stampLanguage].
  Future<void> savePlan(MealPlanEntity plan, {bool stampLanguage = true});
  Future<void> deletePlan(String id);
}
