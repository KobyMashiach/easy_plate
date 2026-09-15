import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_ce/hive.dart';

import '../../domain/entities/receipt_entity.dart';

part 'receipt_model.freezed.dart';
part 'receipt_model.g.dart';

/// Type id 15, after PriceRecordModel (14).
@freezed
@HiveType(typeId: 15)
sealed class ReceiptModel with _$ReceiptModel {
  static const hiveKey = 'receiptsBox';

  const factory ReceiptModel({
    @HiveField(0) required String id,
    @HiveField(1) String? store,
    @HiveField(2) required DateTime purchasedAt,
    @HiveField(3) @Default('ILS') String currency,
    @HiveField(4) required double total,
    @HiveField(5) @Default(0) int itemCount,
    @HiveField(6) required DateTime createdAt,
    @HiveField(7) @Default([]) List<String> imageFileNames,
  }) = _ReceiptModel;

  factory ReceiptModel.fromJson(Map<String, dynamic> json) =>
      _$ReceiptModelFromJson(json);
}

extension ReceiptModelMapper on ReceiptModel {
  ReceiptEntity toEntity() => ReceiptEntity(
    id: id,
    store: store,
    purchasedAt: purchasedAt,
    currency: currency,
    total: total,
    itemCount: itemCount,
    createdAt: createdAt,
    imageFileNames: imageFileNames,
  );
}

extension ReceiptEntityMapper on ReceiptEntity {
  ReceiptModel toModel() => ReceiptModel(
    id: id,
    store: store,
    purchasedAt: purchasedAt,
    currency: currency,
    total: total,
    itemCount: itemCount,
    createdAt: createdAt,
    imageFileNames: imageFileNames,
  );
}
