// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'book_recipe_ref_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BookRecipeRefModelAdapter extends TypeAdapter<BookRecipeRefModel> {
  @override
  final typeId = 4;

  @override
  BookRecipeRefModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BookRecipeRefModel(
      recipeId: fields[0] as String,
      order: (fields[1] as num).toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, BookRecipeRefModel obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.recipeId)
      ..writeByte(1)
      ..write(obj.order);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookRecipeRefModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BookRecipeRefModel _$BookRecipeRefModelFromJson(Map<String, dynamic> json) =>
    _BookRecipeRefModel(
      recipeId: json['recipeId'] as String,
      order: (json['order'] as num).toInt(),
    );

Map<String, dynamic> _$BookRecipeRefModelToJson(_BookRecipeRefModel instance) =>
    <String, dynamic>{'recipeId': instance.recipeId, 'order': instance.order};
