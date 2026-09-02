import '../../domain/entities/meal_plan_entity.dart';
import '../../domain/repositories/meal_plans_repository.dart';
import '../datasources/meal_plans_local_datasource.dart';
import '../models/meal_plan_model.dart';

class MealPlansRepositoryImpl implements MealPlansRepository {
  final MealPlansLocalDataSource localDataSource;

  MealPlansRepositoryImpl({required this.localDataSource});

  @override
  Future<List<MealPlanEntity>> getPlans() async {
    final models = await localDataSource.getPlans();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<MealPlanEntity?> getPlanById(String id) async {
    final model = await localDataSource.getPlanById(id);
    return model?.toEntity();
  }

  @override
  Future<void> savePlan(MealPlanEntity plan) {
    return localDataSource.savePlan(plan.toModel());
  }

  @override
  Future<void> deletePlan(String id) {
    return localDataSource.deletePlan(id);
  }
}
