import '../entities/meal_plan_entity.dart';
import '../repositories/meal_plans_repository.dart';

class WatchMealPlansUseCase {
  final MealPlansRepository repository;
  WatchMealPlansUseCase(this.repository);

  Stream<List<MealPlanEntity>> call() => repository.watchPlans();
}
