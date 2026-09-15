import '../entities/price_record_entity.dart';
import '../entities/product_pricing_entity.dart';
import '../entities/receipt_entity.dart';

abstract class PriceBookRepository {
  Future<List<PriceRecordEntity>> getRecords();
  Future<void> saveRecords(List<PriceRecordEntity> records);
  Future<void> deleteRecord(String id);

  /// Every record and every receipt. The pricing choices go with them.
  Future<void> deleteAllRecords();

  Future<Map<String, ProductPricingEntity>> getPricing();
  Future<void> savePricing(ProductPricingEntity pricing);
  Future<void> deletePricing(String key);

  Future<List<ReceiptEntity>> getReceipts();
  Future<void> saveReceipt(ReceiptEntity receipt);

  /// The receipt, and with [keepRecords] false every record that came from
  /// it; with it true the prices stay and only the receipt goes.
  Future<void> deleteReceipt(String id, {bool keepRecords = false});

  /// The community's figure for a normalised product name, or null when
  /// nobody has shared one. Cached per name for the session.
  Future<CommunityPriceEntity?> communityPrice(String normalizedName);

  /// Adds these prices to the community aggregates. Names and prices only —
  /// never the store, the date or who paid.
  Future<void> sharePrices(List<PriceRecordEntity> records);
}
