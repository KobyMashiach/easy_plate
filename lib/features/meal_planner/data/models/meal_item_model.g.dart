// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meal_item_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MealItemModelAdapter extends TypeAdapter<MealItemModel> {
  @override
  final typeId = 6;

  @override
  MealItemModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MealItemModel(
      id: fields[0] as String,
      recipeId: fields[1] as String?,
      freeText: fields[2] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, MealItemModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.recipeId)
      ..writeByte(2)
      ..write(obj.freeText);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MealItemModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MealItemModel _$MealItemModelFromJson(Map<String, dynamic> json) =>
    _MealItemModel(
      id: json['id'] as String,
      recipeId: json['recipeId'] as String?,
      freeText: json['freeText'] as String?,
    );

Map<String, dynamic> _$MealItemModelToJson(_MealItemModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'recipeId': instance.recipeId,
      'freeText': instance.freeText,
    };
