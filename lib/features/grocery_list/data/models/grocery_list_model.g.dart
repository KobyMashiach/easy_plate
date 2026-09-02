// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'grocery_list_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GroceryListModelAdapter extends TypeAdapter<GroceryListModel> {
  @override
  final typeId = 11;

  @override
  GroceryListModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GroceryListModel(
      id: fields[0] as String,
      name: fields[1] as String,
      items: (fields[2] as List).cast<GroceryItemModel>(),
      collaborators: fields[3] == null
          ? {}
          : (fields[3] as Map).cast<String, String>(),
      createdAt: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, GroceryListModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.items)
      ..writeByte(3)
      ..write(obj.collaborators)
      ..writeByte(4)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GroceryListModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GroceryListModel _$GroceryListModelFromJson(Map<String, dynamic> json) =>
    _GroceryListModel(
      id: json['id'] as String,
      name: json['name'] as String,
      items: (json['items'] as List<dynamic>)
          .map((e) => GroceryItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      collaborators:
          (json['collaborators'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const {},
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$GroceryListModelToJson(_GroceryListModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'items': instance.items,
      'collaborators': instance.collaborators,
      'createdAt': instance.createdAt.toIso8601String(),
    };
