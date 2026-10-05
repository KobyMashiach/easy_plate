import '../../../../core/hive/box_stream.dart';
import '../../../../core/hive/user_scope.dart';

import '../models/meal_plan_model.dart';

abstract class MealPlansLocalDataSource {
  Future<List<MealPlanModel>> getPlans();

  /// The plans, now and after every write — see [watchBoxValues].
  Stream<List<MealPlanModel>> watchPlans();
  Future<MealPlanModel?> getPlanById(String id);
  Future<void> savePlan(MealPlanModel plan);
  Future<void> deletePlan(String id);
}

class MealPlansLocalDataSourceImpl implements MealPlansLocalDataSource {
  @override
  Future<List<MealPlanModel>> getPlans() async {
    final box = await UserScope().open<MealPlanModel>(MealPlanModel.hiveKey);
    return box.values.toList();
  }

  @override
  Stream<List<MealPlanModel>> watchPlans() => watchBoxValues(
    () => UserScope().open<MealPlanModel>(MealPlanModel.hiveKey),
  );

  @override
  Future<MealPlanModel?> getPlanById(String id) async {
    final box = await UserScope().open<MealPlanModel>(MealPlanModel.hiveKey);
    return box.get(id);
  }

  @override
  Future<void> savePlan(MealPlanModel plan) async {
    final box = await UserScope().open<MealPlanModel>(MealPlanModel.hiveKey);
    await box.put(plan.id, plan);
  }

  @override
  Future<void> deletePlan(String id) async {
    final box = await UserScope().open<MealPlanModel>(MealPlanModel.hiveKey);
    await box.delete(id);
  }
}
