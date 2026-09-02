// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'grocery_item_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GroceryItemModelAdapter extends TypeAdapter<GroceryItemModel> {
  @override
  final typeId = 10;

  @override
  GroceryItemModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GroceryItemModel(
      id: fields[0] as String,
      name: fields[1] as String,
      unit: fields[2] == null
          ? MeasurementUnit.unspecified
          : fields[2] as MeasurementUnit,
      sources: (fields[3] as List).cast<GroceryItemSourceModel>(),
      isChecked: fields[4] == null ? false : fields[4] as bool,
      category: fields[5] == null ? 'כללי' : fields[5] as String,
      isAdHoc: fields[6] == null ? false : fields[6] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, GroceryItemModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.unit)
      ..writeByte(3)
      ..write(obj.sources)
      ..writeByte(4)
      ..write(obj.isChecked)
      ..writeByte(5)
      ..write(obj.category)
      ..writeByte(6)
      ..write(obj.isAdHoc);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GroceryItemModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GroceryItemModel _$GroceryItemModelFromJson(Map<String, dynamic> json) =>
    _GroceryItemModel(
      id: json['id'] as String,
      name: json['name'] as String,
      unit:
          $enumDecodeNullable(_$MeasurementUnitEnumMap, json['unit']) ??
          MeasurementUnit.unspecified,
      sources: (json['sources'] as List<dynamic>)
          .map(
            (e) => GroceryItemSourceModel.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      isChecked: json['isChecked'] as bool? ?? false,
      category: json['category'] as String? ?? 'כללי',
      isAdHoc: json['isAdHoc'] as bool? ?? false,
    );

Map<String, dynamic> _$GroceryItemModelToJson(_GroceryItemModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'unit': _$MeasurementUnitEnumMap[instance.unit]!,
      'sources': instance.sources,
      'isChecked': instance.isChecked,
      'category': instance.category,
      'isAdHoc': instance.isAdHoc,
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
