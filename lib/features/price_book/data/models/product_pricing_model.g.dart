// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_pricing_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProductPricingModelAdapter extends TypeAdapter<ProductPricingModel> {
  @override
  final typeId = 16;

  @override
  ProductPricingModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProductPricingModel(
      key: fields[0] as String,
      mode: fields[1] == null ? 'latest' : fields[1] as String,
      store: fields[2] as String?,
      receiptIds: fields[3] == null ? [] : (fields[3] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, ProductPricingModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.key)
      ..writeByte(1)
      ..write(obj.mode)
      ..writeByte(2)
      ..write(obj.store)
      ..writeByte(3)
      ..write(obj.receiptIds);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductPricingModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProductPricingModel _$ProductPricingModelFromJson(Map<String, dynamic> json) =>
    _ProductPricingModel(
      key: json['key'] as String,
      mode: json['mode'] as String? ?? 'latest',
      store: json['store'] as String?,
      receiptIds:
          (json['receiptIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$ProductPricingModelToJson(
  _ProductPricingModel instance,
) => <String, dynamic>{
  'key': instance.key,
  'mode': instance.mode,
  'store': instance.store,
  'receiptIds': instance.receiptIds,
};
