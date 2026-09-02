import 'package:hive_ce/hive.dart';

import '../models/meal_plan_model.dart';

abstract class MealPlansLocalDataSource {
  Future<List<MealPlanModel>> getPlans();
  Future<MealPlanModel?> getPlanById(String id);
  Future<void> savePlan(MealPlanModel plan);
  Future<void> deletePlan(String id);
}

class MealPlansLocalDataSourceImpl implements MealPlansLocalDataSource {
  @override
  Future<List<MealPlanModel>> getPlans() async {
    final box = await Hive.openBox<MealPlanModel>(MealPlanModel.hiveKey);
    return box.values.toList();
  }

  @override
  Future<MealPlanModel?> getPlanById(String id) async {
    final box = await Hive.openBox<MealPlanModel>(MealPlanModel.hiveKey);
    return box.get(id);
  }

  @override
  Future<void> savePlan(MealPlanModel plan) async {
    final box = await Hive.openBox<MealPlanModel>(MealPlanModel.hiveKey);
    await box.put(plan.id, plan);
  }

  @override
  Future<void> deletePlan(String id) async {
    final box = await Hive.openBox<MealPlanModel>(MealPlanModel.hiveKey);
    await box.delete(id);
  }
}
