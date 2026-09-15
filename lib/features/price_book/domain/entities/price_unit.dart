import '../../../../core/constants/app_enums.dart';

/// What a receipt price is per: one package, a kilogram, or a litre. A
/// receipt says so on weighed lines ("0.850 ק"ג × 119.00"); everything
/// else is per package. Stored by name.
enum PriceUnit {
  unit,
  kg,
  liter
  ;

  static PriceUnit fromName(String? name) =>
      PriceUnit.values.where((u) => u.name == name).firstOrNull ??
      PriceUnit.unit;

  /// How many of this price unit a grocery line amounts to, or null when
  /// the two do not convert (a per-package price against grams). Null
  /// means "price the line once", which is the honest fallback.
  double? multiplierFor(MeasurementUnit groceryUnit, double amount) {
    if (amount <= 0) return null;
    switch (this) {
      case PriceUnit.unit:
        return groceryUnit == MeasurementUnit.unit ? amount : null;
      case PriceUnit.kg:
        return switch (groceryUnit) {
          MeasurementUnit.kilogram => amount,
          MeasurementUnit.gram => amount / 1000,
          _ => null,
        };
      case PriceUnit.liter:
        return switch (groceryUnit) {
          MeasurementUnit.liter => amount,
          MeasurementUnit.milliliter => amount / 1000,
          _ => null,
        };
    }
  }

  PriceUnit get next => PriceUnit.values[(index + 1) % PriceUnit.values.length];
}
