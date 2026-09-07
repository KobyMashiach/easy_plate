// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_book_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RecipeBookModelAdapter extends TypeAdapter<RecipeBookModel> {
  @override
  final typeId = 5;

  @override
  RecipeBookModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RecipeBookModel(
      id: fields[0] as String,
      title: fields[1] as String,
      recipeRefs: (fields[2] as List).cast<BookRecipeRefModel>(),
      collaborators: fields[3] == null
          ? {}
          : (fields[3] as Map).cast<String, String>(),
      createdAt: fields[4] as DateTime,
      coverImageFileName: fields[5] as String?,
      coverImageStoragePath: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, RecipeBookModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.recipeRefs)
      ..writeByte(3)
      ..write(obj.collaborators)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.coverImageFileName)
      ..writeByte(6)
      ..write(obj.coverImageStoragePath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecipeBookModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RecipeBookModel _$RecipeBookModelFromJson(Map<String, dynamic> json) =>
    _RecipeBookModel(
      id: json['id'] as String,
      title: json['title'] as String,
      recipeRefs: (json['recipeRefs'] as List<dynamic>)
          .map((e) => BookRecipeRefModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      collaborators:
          (json['collaborators'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const {},
      createdAt: DateTime.parse(json['createdAt'] as String),
      coverImageFileName: json['coverImageFileName'] as String?,
      coverImageStoragePath: json['coverImageStoragePath'] as String?,
    );

Map<String, dynamic> _$RecipeBookModelToJson(_RecipeBookModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'recipeRefs': instance.recipeRefs.map((e) => e.toJson()).toList(),
      'collaborators': instance.collaborators,
      'createdAt': instance.createdAt.toIso8601String(),
      'coverImageFileName': instance.coverImageFileName,
      'coverImageStoragePath': instance.coverImageStoragePath,
    };
