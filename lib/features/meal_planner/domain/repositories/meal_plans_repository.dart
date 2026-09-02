import '../entities/meal_plan_entity.dart';

abstract class MealPlansRepository {
  Future<List<MealPlanEntity>> getPlans();
  Future<MealPlanEntity?> getPlanById(String id);
  Future<void> savePlan(MealPlanEntity plan);
  Future<void> deletePlan(String id);
}
