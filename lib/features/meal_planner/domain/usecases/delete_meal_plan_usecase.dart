import '../repositories/meal_plans_repository.dart';

class DeleteMealPlanUseCase {
  final MealPlansRepository repository;
  DeleteMealPlanUseCase(this.repository);

  Future<void> call(String id) => repository.deletePlan(id);
}
