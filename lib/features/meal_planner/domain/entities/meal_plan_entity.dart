import 'meal_entity.dart';

class MealPlanEntity {
  final String id;
  final String name;
  final List<MealEntity> meals;
  final DateTime createdAt;

  const MealPlanEntity({
    required this.id,
    required this.name,
    required this.meals,
    required this.createdAt,
  });

  List<MealEntity> mealsForWeekday(int weekday) {
    final dayMeals = meals.where((m) => m.weekday == weekday).toList();
    dayMeals.sort((a, b) => a.order.compareTo(b.order));
    return dayMeals;
  }

  MealPlanEntity copyWith({String? name, List<MealEntity>? meals}) {
    return MealPlanEntity(
      id: id,
      name: name ?? this.name,
      meals: meals ?? this.meals,
      createdAt: createdAt,
    );
  }
}
