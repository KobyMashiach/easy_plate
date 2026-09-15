import 'price_unit.dart';

/// One price this account paid for one product, lifted from a receipt (or
/// typed on the review screen). The personal price book is the list of
/// these; the grocery list's estimates come from the most recent match.
class PriceRecordEntity {
  final String id;

  /// The generic product name — what a grocery line will be matched on.
  final String name;

  /// The line as the till printed it, for the record.
  final String printedName;

  /// [name] through `normalizeProductName`, stored so lookups never
  /// re-normalise a thousand records.
  final String normalizedName;

  /// Per one [unit].
  final double unitPrice;
  final PriceUnit unit;
  final double quantity;
  final String currency;
  final String? store;
  final DateTime purchasedAt;

  /// Groups the records of one receipt, so a scan can be undone as a whole.
  /// [manualReceiptId] marks a price typed in without a receipt.
  final String receiptId;

  static const manualReceiptId = 'manual';

  const PriceRecordEntity({
    required this.id,
    required this.name,
    required this.normalizedName,
    required this.unitPrice,
    required this.quantity,
    this.unit = PriceUnit.unit,
    String? printedName,
    required this.currency,
    required this.store,
    required this.purchasedAt,
    required this.receiptId,
  }) : printedName = printedName ?? name;

  PriceRecordEntity copyWith({
    String? name,
    String? normalizedName,
    double? unitPrice,
    PriceUnit? unit,
  }) => PriceRecordEntity(
    id: id,
    name: name ?? this.name,
    printedName: printedName,
    normalizedName: normalizedName ?? this.normalizedName,
    unitPrice: unitPrice ?? this.unitPrice,
    unit: unit ?? this.unit,
    quantity: quantity,
    currency: currency,
    store: store,
    purchasedAt: purchasedAt,
    receiptId: receiptId,
  );
}

/// What the community knows about one product: the middle of the prices
/// people shared, and how many did.
class CommunityPriceEntity {
  final String normalizedName;
  final double median;
  final double average;
  final int count;

  const CommunityPriceEntity({
    required this.normalizedName,
    required this.median,
    required this.average,
    required this.count,
  });
}
