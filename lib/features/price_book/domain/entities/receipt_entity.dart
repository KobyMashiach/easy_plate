/// One scanned receipt, kept so the list of receipts can be browsed and a
/// whole receipt undone. Its lines are the [PriceRecordEntity]s that share
/// its id.
class ReceiptEntity {
  final String id;
  final String? store;
  final DateTime purchasedAt;
  final String currency;

  /// The total as printed; falls back to the sum of the lines.
  final double total;
  final int itemCount;
  final DateTime createdAt;

  /// The photos (or the PDF) the receipt was read from, as file names in
  /// the app's image directory. Local to this device.
  final List<String> imageFileNames;

  const ReceiptEntity({
    required this.id,
    required this.store,
    required this.purchasedAt,
    required this.currency,
    required this.total,
    required this.itemCount,
    required this.createdAt,
    this.imageFileNames = const [],
  });

  bool get hasImages => imageFileNames.isNotEmpty;
  bool get isPdf => imageFileNames.any((f) => f.endsWith('.pdf'));
}
