// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'price_record_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PriceRecordModelAdapter extends TypeAdapter<PriceRecordModel> {
  @override
  final typeId = 14;

  @override
  PriceRecordModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PriceRecordModel(
      id: fields[0] as String,
      name: fields[1] as String,
      normalizedName: fields[2] as String,
      unitPrice: (fields[3] as num).toDouble(),
      quantity: fields[4] == null ? 1 : (fields[4] as num).toDouble(),
      currency: fields[5] == null ? 'ILS' : fields[5] as String,
      store: fields[6] as String?,
      purchasedAt: fields[7] as DateTime,
      receiptId: fields[8] as String,
      printedName: fields[9] as String?,
      unit: fields[10] == null ? 'unit' : fields[10] as String,
    );
  }

  @override
  void write(BinaryWriter writer, PriceRecordModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.normalizedName)
      ..writeByte(3)
      ..write(obj.unitPrice)
      ..writeByte(4)
      ..write(obj.quantity)
      ..writeByte(5)
      ..write(obj.currency)
      ..writeByte(6)
      ..write(obj.store)
      ..writeByte(7)
      ..write(obj.purchasedAt)
      ..writeByte(8)
      ..write(obj.receiptId)
      ..writeByte(9)
      ..write(obj.printedName)
      ..writeByte(10)
      ..write(obj.unit);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PriceRecordModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PriceRecordModel _$PriceRecordModelFromJson(Map<String, dynamic> json) =>
    _PriceRecordModel(
      id: json['id'] as String,
      name: json['name'] as String,
      normalizedName: json['normalizedName'] as String,
      unitPrice: (json['unitPrice'] as num).toDouble(),
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1,
      currency: json['currency'] as String? ?? 'ILS',
      store: json['store'] as String?,
      purchasedAt: DateTime.parse(json['purchasedAt'] as String),
      receiptId: json['receiptId'] as String,
      printedName: json['printedName'] as String?,
      unit: json['unit'] as String? ?? 'unit',
    );

Map<String, dynamic> _$PriceRecordModelToJson(_PriceRecordModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'normalizedName': instance.normalizedName,
      'unitPrice': instance.unitPrice,
      'quantity': instance.quantity,
      'currency': instance.currency,
      'store': instance.store,
      'purchasedAt': instance.purchasedAt.toIso8601String(),
      'receiptId': instance.receiptId,
      'printedName': instance.printedName,
      'unit': instance.unit,
    };
