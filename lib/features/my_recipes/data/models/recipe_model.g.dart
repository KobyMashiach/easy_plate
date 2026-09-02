// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RecipeModelAdapter extends TypeAdapter<RecipeModel> {
  @override
  final typeId = 3;

  @override
  RecipeModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RecipeModel(
      id: fields[0] as String,
      title: fields[1] as String,
      prepTimeMinutes: (fields[2] as num?)?.toInt(),
      cookTimeMinutes: (fields[3] as num?)?.toInt(),
      ingredients: (fields[4] as List).cast<RecipeIngredientModel>(),
      steps: (fields[5] as List).cast<String>(),
      dietaryTags: fields[6] == null
          ? []
          : (fields[6] as List).cast<DietaryPreference>(),
      sourceChannel: fields[7] as String?,
      sourceUrl: fields[8] as String?,
      createdAt: fields[9] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, RecipeModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.prepTimeMinutes)
      ..writeByte(3)
      ..write(obj.cookTimeMinutes)
      ..writeByte(4)
      ..write(obj.ingredients)
      ..writeByte(5)
      ..write(obj.steps)
      ..writeByte(6)
      ..write(obj.dietaryTags)
      ..writeByte(7)
      ..write(obj.sourceChannel)
      ..writeByte(8)
      ..write(obj.sourceUrl)
      ..writeByte(9)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecipeModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RecipeModel _$RecipeModelFromJson(Map<String, dynamic> json) => _RecipeModel(
  id: json['id'] as String,
  title: json['title'] as String,
  prepTimeMinutes: (json['prepTimeMinutes'] as num?)?.toInt(),
  cookTimeMinutes: (json['cookTimeMinutes'] as num?)?.toInt(),
  ingredients: (json['ingredients'] as List<dynamic>)
      .map((e) => RecipeIngredientModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  steps: (json['steps'] as List<dynamic>).map((e) => e as String).toList(),
  dietaryTags:
      (json['dietaryTags'] as List<dynamic>?)
          ?.map((e) => $enumDecode(_$DietaryPreferenceEnumMap, e))
          .toList() ??
      const [],
  sourceChannel: json['sourceChannel'] as String?,
  sourceUrl: json['sourceUrl'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$RecipeModelToJson(_RecipeModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'prepTimeMinutes': instance.prepTimeMinutes,
      'cookTimeMinutes': instance.cookTimeMinutes,
      'ingredients': instance.ingredients,
      'steps': instance.steps,
      'dietaryTags': instance.dietaryTags
          .map((e) => _$DietaryPreferenceEnumMap[e]!)
          .toList(),
      'sourceChannel': instance.sourceChannel,
      'sourceUrl': instance.sourceUrl,
      'createdAt': instance.createdAt.toIso8601String(),
    };

const _$DietaryPreferenceEnumMap = {
  DietaryPreference.meat: 'meat',
  DietaryPreference.dairy: 'dairy',
  DietaryPreference.vegetarian: 'vegetarian',
  DietaryPreference.vegan: 'vegan',
  DietaryPreference.kosher: 'kosher',
  DietaryPreference.glutenFree: 'glutenFree',
  DietaryPreference.allergy: 'allergy',
};
