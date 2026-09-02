// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'grocery_item_source_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GroceryItemSourceModelAdapter
    extends TypeAdapter<GroceryItemSourceModel> {
  @override
  final typeId = 9;

  @override
  GroceryItemSourceModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GroceryItemSourceModel(
      recipeId: fields[0] as String?,
      label: fields[1] as String,
      amount: (fields[2] as num).toDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, GroceryItemSourceModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.recipeId)
      ..writeByte(1)
      ..write(obj.label)
      ..writeByte(2)
      ..write(obj.amount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GroceryItemSourceModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GroceryItemSourceModel _$GroceryItemSourceModelFromJson(
  Map<String, dynamic> json,
) => _GroceryItemSourceModel(
  recipeId: json['recipeId'] as String?,
  label: json['label'] as String,
  amount: (json['amount'] as num).toDouble(),
);

Map<String, dynamic> _$GroceryItemSourceModelToJson(
  _GroceryItemSourceModel instance,
) => <String, dynamic>{
  'recipeId': instance.recipeId,
  'label': instance.label,
  'amount': instance.amount,
};
