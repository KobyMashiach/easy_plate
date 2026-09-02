class GroceryItemSourceEntity {
  final String? recipeId;
  final String label;
  final double amount;

  const GroceryItemSourceEntity({required this.label, required this.amount, this.recipeId});

  bool get isManualBuffer => recipeId == null;
}
