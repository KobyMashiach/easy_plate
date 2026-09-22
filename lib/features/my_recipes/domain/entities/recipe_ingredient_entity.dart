import '../../../../core/constants/app_enums.dart';
import '../../../../core/utils/amount_format.dart';

class RecipeIngredientEntity {
  final String name;
  final double? amount;
  final MeasurementUnit unit;

  const RecipeIngredientEntity({
    required this.name,
    required this.amount,
    this.unit = MeasurementUnit.unspecified,
  });

  bool get isAmountMissing => amount == null;

  /// The amount as a cook reads it; see [formatAmount].
  String get displayAmount => formatAmount(amount);
}
