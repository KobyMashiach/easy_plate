import 'dart:async';

import '../../../../core/sync/user_cloud_collection.dart';
import '../../domain/entities/price_record_entity.dart';
import '../../domain/entities/product_pricing_entity.dart';
import '../../domain/entities/receipt_entity.dart';
import '../../domain/repositories/price_book_repository.dart';
import '../datasources/community_prices_remote_datasource.dart';
import '../datasources/price_records_local_datasource.dart';
import '../models/price_record_model.dart';
import '../models/product_pricing_model.dart';
import '../models/receipt_model.dart';

class PriceBookRepositoryImpl implements PriceBookRepository {
  final PriceRecordsLocalDataSource localDataSource;
  final CommunityPricesRemoteDataSource remoteDataSource;
  final UserCloudCollection<PriceRecordModel>? cloud;
  final UserCloudCollection<ReceiptModel>? receiptsCloud;
  final UserCloudCollection<ProductPricingModel>? pricingCloud;

  /// One lookup per name per session: the aggregates move slowly and the
  /// grocery list asks for every line on every rebuild.
  final _communityCache = <String, Future<CommunityPriceEntity?>>{};

  PriceBookRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    this.cloud,
    this.receiptsCloud,
    this.pricingCloud,
  });

  @override
  Future<List<PriceRecordEntity>> getRecords() async =>
      (await localDataSource.getAll()).map((m) => m.toEntity()).toList();

  @override
  Future<void> saveRecords(List<PriceRecordEntity> records) async {
    final models = records.map((r) => r.toModel()).toList();
    await localDataSource.putAll(models);
    for (final model in models) {
      unawaited(cloud?.push(model));
    }
  }

  @override
  Future<void> deleteRecord(String id) async {
    await localDataSource.delete(id);
    unawaited(cloud?.remove(id));
  }

  @override
  Future<List<ReceiptEntity>> getReceipts() async =>
      (await localDataSource.getReceipts()).map((m) => m.toEntity()).toList();

  @override
  Future<void> saveReceipt(ReceiptEntity receipt) async {
    final model = receipt.toModel();
    await localDataSource.putReceipt(model);
    unawaited(receiptsCloud?.push(model));
  }

  @override
  Future<void> deleteReceipt(String id, {bool keepRecords = false}) async {
    if (!keepRecords) {
      final records = (await localDataSource.getAll())
          .where((r) => r.receiptId == id)
          .toList();
      await localDataSource.deleteMany(records.map((r) => r.id));
      for (final r in records) {
        unawaited(cloud?.remove(r.id));
      }
    }
    await localDataSource.deleteReceipt(id);
    unawaited(receiptsCloud?.remove(id));
  }

  @override
  Future<void> deleteAllRecords() async {
    final records = await localDataSource.getAll();
    final receipts = await localDataSource.getReceipts();
    final pricing = await localDataSource.getPricing();
    await localDataSource.clearAll();
    for (final r in records) {
      unawaited(cloud?.remove(r.id));
    }
    for (final r in receipts) {
      unawaited(receiptsCloud?.remove(r.id));
    }
    for (final p in pricing) {
      unawaited(pricingCloud?.remove(p.key));
    }
  }

  @override
  Future<Map<String, ProductPricingEntity>> getPricing() async => {
    for (final m in await localDataSource.getPricing()) m.key: m.toEntity(),
  };

  @override
  Future<void> savePricing(ProductPricingEntity pricing) async {
    final model = pricing.toModel();
    await localDataSource.putPricing(model);
    unawaited(pricingCloud?.push(model));
  }

  @override
  Future<void> deletePricing(String key) async {
    await localDataSource.deletePricing(key);
    unawaited(pricingCloud?.remove(key));
  }

  @override
  Future<CommunityPriceEntity?> communityPrice(String normalizedName) =>
      _communityCache.putIfAbsent(
        normalizedName,
        () => remoteDataSource.lookup(normalizedName),
      );

  @override
  Future<void> sharePrices(List<PriceRecordEntity> records) async {
    await remoteDataSource.share(records);
    // What was just shared changes the aggregates; forget the cached answers.
    for (final r in records) {
      _communityCache.remove(r.normalizedName);
    }
  }
}
