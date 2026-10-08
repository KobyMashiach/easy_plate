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
      selectedPlanIds: fields[5] == null
          ? []
          : (fields[5] as List).cast<String>(),
      contentLang: fields[6] as String?,
      contentVersion: fields[7] == null ? 0 : (fields[7] as num).toInt(),
      source: fields[8] == null ? 'plans' : fields[8] as String,
      recipeId: fields[9] as String?,
      recipeScale: fields[10] == null ? 1.0 : (fields[10] as num).toDouble(),
      recipeServings: (fields[11] as num?)?.toInt(),
      recipeTitle: fields[12] as String?,
      collabId: fields[13] as String?,
      collabRole: fields[14] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, GroceryListModel obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.items)
      ..writeByte(3)
      ..write(obj.collaborators)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.selectedPlanIds)
      ..writeByte(6)
      ..write(obj.contentLang)
      ..writeByte(7)
      ..write(obj.contentVersion)
      ..writeByte(8)
      ..write(obj.source)
      ..writeByte(9)
      ..write(obj.recipeId)
      ..writeByte(10)
      ..write(obj.recipeScale)
      ..writeByte(11)
      ..write(obj.recipeServings)
      ..writeByte(12)
      ..write(obj.recipeTitle)
      ..writeByte(13)
      ..write(obj.collabId)
      ..writeByte(14)
      ..write(obj.collabRole);
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
      selectedPlanIds:
          (json['selectedPlanIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      contentLang: json['contentLang'] as String?,
      contentVersion: (json['contentVersion'] as num?)?.toInt() ?? 0,
      source: json['source'] as String? ?? 'plans',
      recipeId: json['recipeId'] as String?,
      recipeScale: (json['recipeScale'] as num?)?.toDouble() ?? 1.0,
      recipeServings: (json['recipeServings'] as num?)?.toInt(),
      recipeTitle: json['recipeTitle'] as String?,
      collabId: json['collabId'] as String?,
      collabRole: json['collabRole'] as String?,
    );

Map<String, dynamic> _$GroceryListModelToJson(_GroceryListModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'items': instance.items.map((e) => e.toJson()).toList(),
      'collaborators': instance.collaborators,
      'createdAt': instance.createdAt.toIso8601String(),
      'selectedPlanIds': instance.selectedPlanIds,
      'contentLang': instance.contentLang,
      'contentVersion': instance.contentVersion,
      'source': instance.source,
      'recipeId': instance.recipeId,
      'recipeScale': instance.recipeScale,
      'recipeServings': instance.recipeServings,
      'recipeTitle': instance.recipeTitle,
      'collabId': instance.collabId,
      'collabRole': instance.collabRole,
    };
