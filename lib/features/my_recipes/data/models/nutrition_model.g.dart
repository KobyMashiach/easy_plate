// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nutrition_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NutritionModelAdapter extends TypeAdapter<NutritionModel> {
  @override
  final typeId = 13;

  @override
  NutritionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NutritionModel(
      calories: (fields[0] as num).toInt(),
      proteinGrams: fields[1] == null ? 0 : (fields[1] as num).toDouble(),
      carbsGrams: fields[2] == null ? 0 : (fields[2] as num).toDouble(),
      fatGrams: fields[3] == null ? 0 : (fields[3] as num).toDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, NutritionModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.calories)
      ..writeByte(1)
      ..write(obj.proteinGrams)
      ..writeByte(2)
      ..write(obj.carbsGrams)
      ..writeByte(3)
      ..write(obj.fatGrams);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NutritionModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_NutritionModel _$NutritionModelFromJson(Map<String, dynamic> json) =>
    _NutritionModel(
      calories: (json['calories'] as num).toInt(),
      proteinGrams: (json['proteinGrams'] as num?)?.toDouble() ?? 0,
      carbsGrams: (json['carbsGrams'] as num?)?.toDouble() ?? 0,
      fatGrams: (json['fatGrams'] as num?)?.toDouble() ?? 0,
    );

Map<String, dynamic> _$NutritionModelToJson(_NutritionModel instance) =>
    <String, dynamic>{
      'calories': instance.calories,
      'proteinGrams': instance.proteinGrams,
      'carbsGrams': instance.carbsGrams,
      'fatGrams': instance.fatGrams,
    };
