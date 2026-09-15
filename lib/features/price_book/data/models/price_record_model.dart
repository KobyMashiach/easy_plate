import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_ce/hive.dart';

import '../../domain/entities/price_record_entity.dart';
import '../../domain/entities/price_unit.dart';

part 'price_record_model.freezed.dart';
part 'price_record_model.g.dart';

/// Type id 14: the next free one after NutritionModel (13).
@freezed
@HiveType(typeId: 14)
sealed class PriceRecordModel with _$PriceRecordModel {
  static const hiveKey = 'priceRecordsBox';

  const factory PriceRecordModel({
    @HiveField(0) required String id,
    @HiveField(1) required String name,
    @HiveField(2) required String normalizedName,
    @HiveField(3) required double unitPrice,
    @HiveField(4) @Default(1) double quantity,
    @HiveField(5) @Default('ILS') String currency,
    @HiveField(6) String? store,
    @HiveField(7) required DateTime purchasedAt,
    @HiveField(8) required String receiptId,
    // Appended: the printed line and the price unit by name.
    @HiveField(9) String? printedName,
    @HiveField(10) @Default('unit') String unit,
  }) = _PriceRecordModel;

  factory PriceRecordModel.fromJson(Map<String, dynamic> json) =>
      _$PriceRecordModelFromJson(json);
}

extension PriceRecordModelMapper on PriceRecordModel {
  PriceRecordEntity toEntity() => PriceRecordEntity(
    id: id,
    name: name,
    normalizedName: normalizedName,
    unitPrice: unitPrice,
    quantity: quantity,
    currency: currency,
    store: store,
    purchasedAt: purchasedAt,
    receiptId: receiptId,
    printedName: printedName,
    unit: PriceUnit.fromName(unit),
  );
}

extension PriceRecordEntityMapper on PriceRecordEntity {
  PriceRecordModel toModel() => PriceRecordModel(
    id: id,
    name: name,
    normalizedName: normalizedName,
    unitPrice: unitPrice,
    quantity: quantity,
    currency: currency,
    store: store,
    purchasedAt: purchasedAt,
    receiptId: receiptId,
    printedName: printedName,
    unit: unit.name,
  );
}
