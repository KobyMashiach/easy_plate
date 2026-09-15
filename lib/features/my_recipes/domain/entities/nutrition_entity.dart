/// Nutrition of one serving of a recipe.
///
/// Estimates, not lab values: the model derives them from the ingredient
/// list when a recipe is extracted, and the user may overwrite them in the
/// editor. Everything is per serving so a meal plan can add servings up.
class NutritionEntity {
  final int calories;
  final double proteinGrams;
  final double carbsGrams;
  final double fatGrams;

  const NutritionEntity({
    required this.calories,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
  });

  static const zero = NutritionEntity(calories: 0, proteinGrams: 0, carbsGrams: 0, fatGrams: 0);

  bool get isEmpty => calories == 0 && proteinGrams == 0 && carbsGrams == 0 && fatGrams == 0;

  NutritionEntity operator +(NutritionEntity other) => NutritionEntity(
        calories: calories + other.calories,
        proteinGrams: proteinGrams + other.proteinGrams,
        carbsGrams: carbsGrams + other.carbsGrams,
        fatGrams: fatGrams + other.fatGrams,
      );

  NutritionEntity scaled(double factor) => NutritionEntity(
        calories: (calories * factor).round(),
        proteinGrams: proteinGrams * factor,
        carbsGrams: carbsGrams * factor,
        fatGrams: fatGrams * factor,
      );

  /// Calories the three macros account for (4/4/9 kcal per gram). Usually a
  /// little under [calories] — alcohol, fibre and rounding make up the rest.
  double get macroCalories => proteinGrams * 4 + carbsGrams * 4 + fatGrams * 9;

  /// The share of [macroCalories] each macro contributes, in 0..1, all zero
  /// when there is nothing to split.
  ({double protein, double carbs, double fat}) get macroShares {
    final total = macroCalories;
    if (total <= 0) return (protein: 0, carbs: 0, fat: 0);
    return (
      protein: proteinGrams * 4 / total,
      carbs: carbsGrams * 4 / total,
      fat: fatGrams * 9 / total,
    );
  }

  /// The shape every Firestore document carries it in (`nutrition` field).
  Map<String, dynamic> toJson() => {
        'calories': calories,
        'proteinGrams': proteinGrams,
        'carbsGrams': carbsGrams,
        'fatGrams': fatGrams,
      };

  /// Null for a document written before nutrition existed, or one carrying
  /// garbage in the field.
  static NutritionEntity? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final calories = (raw['calories'] as num?)?.toInt();
    if (calories == null) return null;
    return NutritionEntity(
      calories: calories,
      proteinGrams: (raw['proteinGrams'] as num?)?.toDouble() ?? 0,
      carbsGrams: (raw['carbsGrams'] as num?)?.toDouble() ?? 0,
      fatGrams: (raw['fatGrams'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is NutritionEntity &&
      other.calories == calories &&
      other.proteinGrams == proteinGrams &&
      other.carbsGrams == carbsGrams &&
      other.fatGrams == fatGrams;

  @override
  int get hashCode => Object.hash(calories, proteinGrams, carbsGrams, fatGrams);

  @override
  String toString() =>
      'NutritionEntity($calories kcal, P $proteinGrams, C $carbsGrams, F $fatGrams)';
}
