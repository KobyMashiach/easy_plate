import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_ce/hive.dart';

import '../../domain/entities/product_pricing_entity.dart';

part 'product_pricing_model.freezed.dart';
part 'product_pricing_model.g.dart';

/// Type id 16, after ReceiptModel (15). Keyed by the product key.
@freezed
@HiveType(typeId: 16)
sealed class ProductPricingModel with _$ProductPricingModel {
  static const hiveKey = 'productPricingBox';

  const factory ProductPricingModel({
    @HiveField(0) required String key,
    @HiveField(1) @Default('latest') String mode,
    @HiveField(2) String? store,
    @HiveField(3) @Default([]) List<String> receiptIds,
  }) = _ProductPricingModel;

  factory ProductPricingModel.fromJson(Map<String, dynamic> json) =>
      _$ProductPricingModelFromJson(json);
}

extension ProductPricingModelMapper on ProductPricingModel {
  ProductPricingEntity toEntity() => ProductPricingEntity(
    key: key,
    mode:
        PricingMode.values.where((m) => m.name == mode).firstOrNull ??
        PricingMode.latest,
    store: store,
    receiptIds: receiptIds,
  );
}

extension ProductPricingEntityMapper on ProductPricingEntity {
  ProductPricingModel toModel() => ProductPricingModel(
    key: key,
    mode: mode.name,
    store: store,
    receiptIds: receiptIds,
  );
}
