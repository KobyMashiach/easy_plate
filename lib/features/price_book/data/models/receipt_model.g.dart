// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receipt_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ReceiptModelAdapter extends TypeAdapter<ReceiptModel> {
  @override
  final typeId = 15;

  @override
  ReceiptModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ReceiptModel(
      id: fields[0] as String,
      store: fields[1] as String?,
      purchasedAt: fields[2] as DateTime,
      currency: fields[3] == null ? 'ILS' : fields[3] as String,
      total: (fields[4] as num).toDouble(),
      itemCount: fields[5] == null ? 0 : (fields[5] as num).toInt(),
      createdAt: fields[6] as DateTime,
      imageFileNames: fields[7] == null
          ? []
          : (fields[7] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, ReceiptModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.store)
      ..writeByte(2)
      ..write(obj.purchasedAt)
      ..writeByte(3)
      ..write(obj.currency)
      ..writeByte(4)
      ..write(obj.total)
      ..writeByte(5)
      ..write(obj.itemCount)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.imageFileNames);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReceiptModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ReceiptModel _$ReceiptModelFromJson(Map<String, dynamic> json) =>
    _ReceiptModel(
      id: json['id'] as String,
      store: json['store'] as String?,
      purchasedAt: DateTime.parse(json['purchasedAt'] as String),
      currency: json['currency'] as String? ?? 'ILS',
      total: (json['total'] as num).toDouble(),
      itemCount: (json['itemCount'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      imageFileNames:
          (json['imageFileNames'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$ReceiptModelToJson(_ReceiptModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'store': instance.store,
      'purchasedAt': instance.purchasedAt.toIso8601String(),
      'currency': instance.currency,
      'total': instance.total,
      'itemCount': instance.itemCount,
      'createdAt': instance.createdAt.toIso8601String(),
      'imageFileNames': instance.imageFileNames,
    };
