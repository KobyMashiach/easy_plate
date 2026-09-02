// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_preferences_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserPreferencesModelAdapter extends TypeAdapter<UserPreferencesModel> {
  @override
  final typeId = 1;

  @override
  UserPreferencesModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserPreferencesModel(
      shoppingDay: fields[0] as ShoppingDay,
      dietaryPreferences: (fields[1] as List).cast<DietaryPreference>(),
      soundEffectsEnabled: fields[2] == null ? true : fields[2] as bool,
      onboardingComplete: fields[3] == null ? false : fields[3] as bool,
      language: fields[4] == null
          ? AppLanguage.hebrew
          : fields[4] as AppLanguage,
      fastPageTurnEnabled: fields[5] == null ? true : fields[5] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, UserPreferencesModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.shoppingDay)
      ..writeByte(1)
      ..write(obj.dietaryPreferences)
      ..writeByte(2)
      ..write(obj.soundEffectsEnabled)
      ..writeByte(3)
      ..write(obj.onboardingComplete)
      ..writeByte(4)
      ..write(obj.language)
      ..writeByte(5)
      ..write(obj.fastPageTurnEnabled);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserPreferencesModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserPreferencesModel _$UserPreferencesModelFromJson(
  Map<String, dynamic> json,
) => _UserPreferencesModel(
  shoppingDay: $enumDecode(_$ShoppingDayEnumMap, json['shoppingDay']),
  dietaryPreferences: (json['dietaryPreferences'] as List<dynamic>)
      .map((e) => $enumDecode(_$DietaryPreferenceEnumMap, e))
      .toList(),
  soundEffectsEnabled: json['soundEffectsEnabled'] as bool? ?? true,
  onboardingComplete: json['onboardingComplete'] as bool? ?? false,
  language:
      $enumDecodeNullable(_$AppLanguageEnumMap, json['language']) ??
      AppLanguage.hebrew,
  fastPageTurnEnabled: json['fastPageTurnEnabled'] as bool? ?? true,
);

Map<String, dynamic> _$UserPreferencesModelToJson(
  _UserPreferencesModel instance,
) => <String, dynamic>{
  'shoppingDay': _$ShoppingDayEnumMap[instance.shoppingDay]!,
  'dietaryPreferences': instance.dietaryPreferences
      .map((e) => _$DietaryPreferenceEnumMap[e]!)
      .toList(),
  'soundEffectsEnabled': instance.soundEffectsEnabled,
  'onboardingComplete': instance.onboardingComplete,
  'language': _$AppLanguageEnumMap[instance.language]!,
  'fastPageTurnEnabled': instance.fastPageTurnEnabled,
};

const _$ShoppingDayEnumMap = {
  ShoppingDay.sunday: 'sunday',
  ShoppingDay.monday: 'monday',
  ShoppingDay.tuesday: 'tuesday',
  ShoppingDay.wednesday: 'wednesday',
  ShoppingDay.thursday: 'thursday',
  ShoppingDay.friday: 'friday',
  ShoppingDay.saturday: 'saturday',
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

const _$AppLanguageEnumMap = {
  AppLanguage.hebrew: 'hebrew',
  AppLanguage.english: 'english',
  AppLanguage.arabic: 'arabic',
  AppLanguage.french: 'french',
  AppLanguage.russian: 'russian',
};
