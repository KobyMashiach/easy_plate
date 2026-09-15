import 'price_unit.dart';

/// What the model read off a receipt. Every line is either an item with a
/// price or something it could not make out; nothing is silently dropped,
/// so the review screen can show both.
class ReceiptScanEntity {
  final String? store;
  final DateTime? purchasedAt;
  final String currency;
  final double? total;
  final List<ReceiptLineEntity> items;

  /// Lines the model saw but could not turn into a product and a price —
  /// smudged, torn, or not a product at all (a deposit, a coupon).
  final List<String> unreadable;

  const ReceiptScanEntity({
    required this.store,
    required this.purchasedAt,
    required this.currency,
    required this.total,
    required this.items,
    required this.unreadable,
  });

  static const empty = ReceiptScanEntity(
    store: null,
    purchasedAt: null,
    currency: 'ILS',
    total: null,
    items: [],
    unreadable: [],
  );

  double get itemsTotal => items.fold(0, (sum, i) => sum + i.lineTotal);

  ReceiptScanEntity copyWith({
    String? store,
    DateTime? purchasedAt,
    double? total,
    List<ReceiptLineEntity>? items,
    List<String>? unreadable,
  }) => ReceiptScanEntity(
    store: store ?? this.store,
    purchasedAt: purchasedAt ?? this.purchasedAt,
    currency: currency,
    total: total ?? this.total,
    items: items ?? this.items,
    unreadable: unreadable ?? this.unreadable,
  );
}

/// One product on the receipt.
///
/// [name] is the generic product ("אנטריקוט"), which is what the grocery
/// list will ask for; [printedName] is the line as the till printed it
/// ("אנטריקוט ח. טרי מיושן"), kept for the record. [unitPrice] is per one
/// [unit]: per package, per kilogram or per litre, and [quantity] is how
/// many of that unit — 0.85 for 850 grams of steak.
class ReceiptLineEntity {
  final String name;
  final String printedName;
  final double quantity;
  final double unitPrice;
  final PriceUnit unit;

  const ReceiptLineEntity({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    this.unit = PriceUnit.unit,
    String? printedName,
  }) : printedName = printedName ?? name;

  double get lineTotal => unitPrice * quantity;

  ReceiptLineEntity copyWith({
    String? name,
    String? printedName,
    double? quantity,
    double? unitPrice,
    PriceUnit? unit,
  }) => ReceiptLineEntity(
    name: name ?? this.name,
    printedName: printedName ?? this.printedName,
    quantity: quantity ?? this.quantity,
    unitPrice: unitPrice ?? this.unitPrice,
    unit: unit ?? this.unit,
  );
}
