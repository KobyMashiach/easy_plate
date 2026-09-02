// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_ingredient_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RecipeIngredientModelAdapter extends TypeAdapter<RecipeIngredientModel> {
  @override
  final typeId = 2;

  @override
  RecipeIngredientModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RecipeIngredientModel(
      name: fields[0] as String,
      amount: (fields[1] as num?)?.toDouble(),
      unit: fields[2] == null
          ? MeasurementUnit.unspecified
          : fields[2] as MeasurementUnit,
    );
  }

  @override
  void write(BinaryWriter writer, RecipeIngredientModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.amount)
      ..writeByte(2)
      ..write(obj.unit);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecipeIngredientModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RecipeIngredientModel _$RecipeIngredientModelFromJson(
  Map<String, dynamic> json,
) => _RecipeIngredientModel(
  name: json['name'] as String,
  amount: (json['amount'] as num?)?.toDouble(),
  unit:
      $enumDecodeNullable(_$MeasurementUnitEnumMap, json['unit']) ??
      MeasurementUnit.unspecified,
);

Map<String, dynamic> _$RecipeIngredientModelToJson(
  _RecipeIngredientModel instance,
) => <String, dynamic>{
  'name': instance.name,
  'amount': instance.amount,
  'unit': _$MeasurementUnitEnumMap[instance.unit]!,
};

const _$MeasurementUnitEnumMap = {
  MeasurementUnit.gram: 'gram',
  MeasurementUnit.kilogram: 'kilogram',
  MeasurementUnit.milliliter: 'milliliter',
  MeasurementUnit.liter: 'liter',
  MeasurementUnit.teaspoon: 'teaspoon',
  MeasurementUnit.tablespoon: 'tablespoon',
  MeasurementUnit.cup: 'cup',
  MeasurementUnit.unit: 'unit',
  MeasurementUnit.pinch: 'pinch',
  MeasurementUnit.unspecified: 'unspecified',
};
