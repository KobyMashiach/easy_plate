import 'package:hive_ce/hive.dart';

import '../../../../core/hive/user_scope.dart';
import '../models/price_record_model.dart';
import '../models/product_pricing_model.dart';
import '../models/receipt_model.dart';

/// The account's price records, in its own scoped box like every other
/// per-user collection.
class PriceRecordsLocalDataSource {
  Future<Box<PriceRecordModel>> _box() =>
      UserScope().open<PriceRecordModel>(PriceRecordModel.hiveKey);

  Future<List<PriceRecordModel>> getAll() async =>
      (await _box()).values.toList();

  Future<void> putAll(List<PriceRecordModel> records) async {
    final box = await _box();
    await box.putAll({for (final r in records) r.id: r});
  }

  Future<void> delete(String id) async => (await _box()).delete(id);

  Future<void> deleteMany(Iterable<String> ids) async =>
      (await _box()).deleteAll(ids);

  Future<Box<ReceiptModel>> _receipts() =>
      UserScope().open<ReceiptModel>(ReceiptModel.hiveKey);

  Future<List<ReceiptModel>> getReceipts() async =>
      (await _receipts()).values.toList();

  Future<void> putReceipt(ReceiptModel receipt) async =>
      (await _receipts()).put(receipt.id, receipt);

  Future<void> deleteReceipt(String id) async => (await _receipts()).delete(id);

  Future<void> clearAll() async {
    await (await _box()).clear();
    await (await _receipts()).clear();
    await (await _pricing()).clear();
  }

  Future<Box<ProductPricingModel>> _pricing() =>
      UserScope().open<ProductPricingModel>(ProductPricingModel.hiveKey);

  Future<List<ProductPricingModel>> getPricing() async =>
      (await _pricing()).values.toList();

  Future<void> putPricing(ProductPricingModel pricing) async =>
      (await _pricing()).put(pricing.key, pricing);

  Future<void> deletePricing(String key) async =>
      (await _pricing()).delete(key);
}
