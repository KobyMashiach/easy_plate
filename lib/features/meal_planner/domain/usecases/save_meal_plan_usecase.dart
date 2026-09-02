import '../entities/meal_plan_entity.dart';
import '../repositories/meal_plans_repository.dart';

class SaveMealPlanUseCase {
  final MealPlansRepository repository;
  SaveMealPlanUseCase(this.repository);

  Future<void> call(MealPlanEntity plan) => repository.savePlan(plan);
}
