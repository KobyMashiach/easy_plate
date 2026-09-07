import 'dart:async';

import '../../../../core/sync/user_cloud_collection.dart';
import '../../domain/entities/meal_plan_entity.dart';
import '../../domain/repositories/meal_plans_repository.dart';
import '../datasources/meal_plans_local_datasource.dart';
import '../models/meal_plan_model.dart';

class MealPlansRepositoryImpl implements MealPlansRepository {
  final MealPlansLocalDataSource localDataSource;

  /// Mirrors every write into the account's own Firestore subtree, so a plan
  /// survives the device it was built on.
  final UserCloudCollection<MealPlanModel>? cloud;

  MealPlansRepositoryImpl({required this.localDataSource, this.cloud});

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
  Future<void> savePlan(MealPlanEntity plan) async {
    final model = plan.toModel();
    await localDataSource.savePlan(model);
    unawaited(cloud?.push(model) ?? Future.value());
  }

  @override
  Future<void> deletePlan(String id) async {
    await localDataSource.deletePlan(id);
    unawaited(cloud?.remove(id) ?? Future.value());
  }
}
