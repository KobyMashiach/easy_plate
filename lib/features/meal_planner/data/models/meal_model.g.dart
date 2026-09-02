// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meal_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MealModelAdapter extends TypeAdapter<MealModel> {
  @override
  final typeId = 7;

  @override
  MealModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MealModel(
      id: fields[0] as String,
      weekday: (fields[1] as num).toInt(),
      name: fields[2] as String,
      order: (fields[3] as num).toInt(),
      items: (fields[4] as List).cast<MealItemModel>(),
    );
  }

  @override
  void write(BinaryWriter writer, MealModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.weekday)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.order)
      ..writeByte(4)
      ..write(obj.items);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MealModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MealModel _$MealModelFromJson(Map<String, dynamic> json) => _MealModel(
  id: json['id'] as String,
  weekday: (json['weekday'] as num).toInt(),
  name: json['name'] as String,
  order: (json['order'] as num).toInt(),
  items: (json['items'] as List<dynamic>)
      .map((e) => MealItemModel.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$MealModelToJson(_MealModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'weekday': instance.weekday,
      'name': instance.name,
      'order': instance.order,
      'items': instance.items,
    };
