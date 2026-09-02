import '../entities/meal_plan_entity.dart';
import '../repositories/meal_plans_repository.dart';

class GetMealPlansUseCase {
  final MealPlansRepository repository;
  GetMealPlansUseCase(this.repository);

  Future<List<MealPlanEntity>> call() => repository.getPlans();
}
