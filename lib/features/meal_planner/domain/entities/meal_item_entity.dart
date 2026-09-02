class MealItemEntity {
  final String id;
  final String? recipeId;
  final String? freeText;

  const MealItemEntity({required this.id, this.recipeId, this.freeText});

  String get displayLabel => freeText ?? '';
}
