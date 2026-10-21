import 'package:uuid/uuid.dart';

import '../entities/price_record_entity.dart';
import '../entities/receipt_entity.dart';
import '../entities/receipt_scan_entity.dart';
import '../product_name.dart';
import '../repositories/price_book_repository.dart';

class GetPriceRecordsUseCase {
  final PriceBookRepository repository;
  GetPriceRecordsUseCase(this.repository);
  Future<List<PriceRecordEntity>> call() => repository.getRecords();
}

class DeletePriceRecordUseCase {
  final PriceBookRepository repository;
  DeletePriceRecordUseCase(this.repository);
  Future<void> call(String id) => repository.deleteRecord(id);
}

class GetReceiptsUseCase {
  final PriceBookRepository repository;
  GetReceiptsUseCase(this.repository);
  Future<List<ReceiptEntity>> call() => repository.getReceipts();
}

class DeleteReceiptUseCase {
  final PriceBookRepository repository;
  DeleteReceiptUseCase(this.repository);
  Future<void> call(String id) => repository.deleteReceipt(id);
}

class SharePricesUseCase {
  final PriceBookRepository repository;
  SharePricesUseCase(this.repository);

  /// Shekel prices only: the community median carries no currency, so a
  /// dollar receipt's $3.50 was counted as ₪3.50 for everyone. Returns how
  /// many were sent, so a receipt in another currency is not reported as
  /// shared.
  Future<int> call(List<PriceRecordEntity> records) async {
    final shekels = [
      for (final r in records)
        if (r.currency == 'ILS') r,
    ];
    if (shekels.isEmpty) return 0;
    await repository.sharePrices(shekels);
    return shekels.length;
  }
}

/// Turns a reviewed receipt into records and stores them. Returns what was
/// stored, so the caller can offer to share exactly that.
class SaveReceiptUseCase {
  static const _uuid = Uuid();
  final PriceBookRepository repository;
  SaveReceiptUseCase(this.repository);

  Future<List<PriceRecordEntity>> call(
    ReceiptScanEntity receipt, {
    List<String> imageFileNames = const [],
  }) async {
    final receiptId = _uuid.v4();
    final at = receipt.purchasedAt ?? DateTime.now();
    final records = [
      for (final line in receipt.items)
        if (line.name.trim().isNotEmpty && line.unitPrice > 0)
          PriceRecordEntity(
            id: _uuid.v4(),
            name: line.name.trim(),
            printedName: line.printedName.trim(),
            normalizedName: normalizeProductName(line.name),
            unitPrice: line.unitPrice,
            unit: line.unit,
            quantity: line.quantity,
            currency: receipt.currency,
            store: receipt.store,
            purchasedAt: at,
            receiptId: receiptId,
          ),
    ];
    await repository.saveRecords(records);
    await repository.saveReceipt(
      ReceiptEntity(
        id: receiptId,
        store: receipt.store,
        purchasedAt: at,
        currency: receipt.currency,
        total:
            receipt.total ??
            records.fold(0.0, (s, r) => s + r.unitPrice * r.quantity),
        itemCount: records.length,
        imageFileNames: imageFileNames,
        createdAt: DateTime.now(),
      ),
    );
    return records;
  }
}
