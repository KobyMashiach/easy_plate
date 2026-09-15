import '../../my_recipes/domain/entities/nutrition_entity.dart';
import '../../my_recipes/domain/entities/recipe_entity.dart';
import 'entities/meal_entity.dart';
import 'entities/meal_plan_entity.dart';

/// What a day of a plan adds up to, and how much of it is actually known.
///
/// Every planned recipe item counts as one serving of that recipe — the plan
/// has no per-item servings, and one plate per person per meal is what a
/// meal plan means. Quick-entry items (free text, no recipe) and recipes
/// with no nutrition yet are counted in [missingItems] rather than as zero,
/// so a total is never quietly smaller than the day.
class DayNutrition {
  final int weekday;
  final NutritionEntity total;

  /// Recipe items that contributed.
  final int countedItems;

  /// Items with no figures: free text, or a recipe not estimated yet.
  final int missingItems;
  final List<MealNutrition> meals;

  const DayNutrition({
    required this.weekday,
    required this.total,
    required this.countedItems,
    required this.missingItems,
    required this.meals,
  });

  bool get hasData => countedItems > 0;
}

class MealNutrition {
  final MealEntity meal;
  final NutritionEntity total;
  final int countedItems;
  final int missingItems;

  const MealNutrition({
    required this.meal,
    required this.total,
    required this.countedItems,
    required this.missingItems,
  });
}

/// A whole plan, day by day, plus the roll-ups the dashboard shows.
class PlanNutrition {
  final List<DayNutrition> days;

  const PlanNutrition(this.days);

  static const weekdays = 7;

  NutritionEntity get weekTotal =>
      days.fold(NutritionEntity.zero, (sum, day) => sum + day.total);

  /// Days with at least one counted item — the ones an average is over.
  int get plannedDays => days.where((d) => d.hasData).length;

  /// Per planned day, or zero when nothing is planned. Averaging over all
  /// seven would punish a plan that only covers weekdays.
  NutritionEntity get dailyAverage =>
      plannedDays == 0 ? NutritionEntity.zero : weekTotal.scaled(1 / plannedDays);

  int get missingItems => days.fold(0, (n, d) => n + d.missingItems);

  bool get hasData => plannedDays > 0;

  /// The largest day, for scaling the week chart. Never zero, so a bar
  /// division is always safe.
  int get peakCalories =>
      days.fold(1, (peak, d) => d.total.calories > peak ? d.total.calories : peak);

  DayNutrition day(int weekday) => days[weekday];

  /// Pure: everything comes from [plan] and the recipes it references.
  static PlanNutrition of(MealPlanEntity plan, Map<String, RecipeEntity> recipes) {
    return PlanNutrition([
      for (var weekday = 0; weekday < weekdays; weekday++) _day(weekday, plan, recipes),
    ]);
  }

  static DayNutrition _day(int weekday, MealPlanEntity plan, Map<String, RecipeEntity> recipes) {
    final meals = <MealNutrition>[];
    var total = NutritionEntity.zero;
    var counted = 0;
    var missing = 0;
    for (final meal in plan.mealsForWeekday(weekday)) {
      var mealTotal = NutritionEntity.zero;
      var mealCounted = 0;
      var mealMissing = 0;
      for (final item in meal.items) {
        final nutrition = item.recipeId == null ? null : recipes[item.recipeId]?.nutrition;
        if (nutrition == null) {
          mealMissing++;
        } else {
          mealTotal += nutrition;
          mealCounted++;
        }
      }
      meals.add(MealNutrition(
        meal: meal,
        total: mealTotal,
        countedItems: mealCounted,
        missingItems: mealMissing,
      ));
      total += mealTotal;
      counted += mealCounted;
      missing += mealMissing;
    }
    return DayNutrition(
      weekday: weekday,
      total: total,
      countedItems: counted,
      missingItems: missing,
      meals: meals,
    );
  }
}
