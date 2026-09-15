import 'price_record_entity.dart';
import 'price_unit.dart';

/// Which of a product's prices the grocery list should use.
enum PricingMode {
  /// The most recent record (the default).
  latest,

  /// The mean of every record.
  average,

  /// The most recent record from one store.
  store,

  /// The mean of the records from chosen receipts.
  receipts,
}

/// The user's choice for one product (name + unit): the price book keeps
/// every price ever paid, and this says which of them counts. Absent means
/// [PricingMode.latest].
class ProductPricingEntity {
  /// `normalizedName|unit`, see [keyFor].
  final String key;
  final PricingMode mode;
  final String? store;
  final List<String> receiptIds;

  const ProductPricingEntity({
    required this.key,
    required this.mode,
    this.store,
    this.receiptIds = const [],
  });

  static String keyFor(String normalizedName, PriceUnit unit) =>
      '$normalizedName|${unit.name}';

  /// The price this policy picks out of [records] (all of one product), or
  /// null when the choice matches nothing — the caller then falls back to
  /// the latest, so a policy can never make a product priceless.
  double? resolve(List<PriceRecordEntity> records) {
    if (records.isEmpty) return null;
    switch (mode) {
      case PricingMode.latest:
        return _latest(records)?.unitPrice;
      case PricingMode.average:
        return _mean(records);
      case PricingMode.store:
        return _latest(
          records.where((r) => r.store == store).toList(),
        )?.unitPrice;
      case PricingMode.receipts:
        return _mean(
          records.where((r) => receiptIds.contains(r.receiptId)).toList(),
        );
    }
  }

  static PriceRecordEntity? _latest(List<PriceRecordEntity> records) {
    PriceRecordEntity? best;
    for (final r in records) {
      if (best == null || r.purchasedAt.isAfter(best.purchasedAt)) best = r;
    }
    return best;
  }

  static double? _mean(List<PriceRecordEntity> records) {
    if (records.isEmpty) return null;
    final sum = records.fold(0.0, (s, r) => s + r.unitPrice);
    return double.parse((sum / records.length).toStringAsFixed(2));
  }
}
