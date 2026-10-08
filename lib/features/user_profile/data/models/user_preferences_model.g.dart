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
      walkthroughSeen: fields[6] == null ? false : fields[6] as bool,
      communityPricesEnabled: fields[7] == null ? false : fields[7] as bool,
      shoppingReminderSlots: (fields[8] as List?)?.cast<String>(),
      pushEnabled: fields[9] == null ? true : fields[9] as bool,
      notifyRepliesOnMyPosts: fields[10] == null ? true : fields[10] as bool,
      notifyRepliesOnThreads: fields[11] == null ? true : fields[11] as bool,
      notifyShareInvites: fields[12] == null ? true : fields[12] as bool,
      notifySharedRecipeUpdates: fields[13] == null ? true : fields[13] as bool,
      notifyAdminReplies: fields[14] == null ? true : fields[14] as bool,
      notifyAnnouncements: fields[15] == null ? true : fields[15] as bool,
      foregroundPopupsEnabled: fields[16] == null ? true : fields[16] as bool,
      themeMode: fields[17] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, UserPreferencesModel obj) {
    writer
      ..writeByte(18)
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
      ..write(obj.fastPageTurnEnabled)
      ..writeByte(6)
      ..write(obj.walkthroughSeen)
      ..writeByte(7)
      ..write(obj.communityPricesEnabled)
      ..writeByte(8)
      ..write(obj.shoppingReminderSlots)
      ..writeByte(9)
      ..write(obj.pushEnabled)
      ..writeByte(10)
      ..write(obj.notifyRepliesOnMyPosts)
      ..writeByte(11)
      ..write(obj.notifyRepliesOnThreads)
      ..writeByte(12)
      ..write(obj.notifyShareInvites)
      ..writeByte(13)
      ..write(obj.notifySharedRecipeUpdates)
      ..writeByte(14)
      ..write(obj.notifyAdminReplies)
      ..writeByte(15)
      ..write(obj.notifyAnnouncements)
      ..writeByte(16)
      ..write(obj.foregroundPopupsEnabled)
      ..writeByte(17)
      ..write(obj.themeMode);
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
  walkthroughSeen: json['walkthroughSeen'] as bool? ?? false,
  communityPricesEnabled: json['communityPricesEnabled'] as bool? ?? false,
  shoppingReminderSlots: (json['shoppingReminderSlots'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  pushEnabled: json['pushEnabled'] as bool? ?? true,
  notifyRepliesOnMyPosts: json['notifyRepliesOnMyPosts'] as bool? ?? true,
  notifyRepliesOnThreads: json['notifyRepliesOnThreads'] as bool? ?? true,
  notifyShareInvites: json['notifyShareInvites'] as bool? ?? true,
  notifySharedRecipeUpdates: json['notifySharedRecipeUpdates'] as bool? ?? true,
  notifyAdminReplies: json['notifyAdminReplies'] as bool? ?? true,
  notifyAnnouncements: json['notifyAnnouncements'] as bool? ?? true,
  foregroundPopupsEnabled: json['foregroundPopupsEnabled'] as bool? ?? true,
  themeMode: json['themeMode'] as String?,
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
  'walkthroughSeen': instance.walkthroughSeen,
  'communityPricesEnabled': instance.communityPricesEnabled,
  'shoppingReminderSlots': instance.shoppingReminderSlots,
  'pushEnabled': instance.pushEnabled,
  'notifyRepliesOnMyPosts': instance.notifyRepliesOnMyPosts,
  'notifyRepliesOnThreads': instance.notifyRepliesOnThreads,
  'notifyShareInvites': instance.notifyShareInvites,
  'notifySharedRecipeUpdates': instance.notifySharedRecipeUpdates,
  'notifyAdminReplies': instance.notifyAdminReplies,
  'notifyAnnouncements': instance.notifyAnnouncements,
  'foregroundPopupsEnabled': instance.foregroundPopupsEnabled,
  'themeMode': instance.themeMode,
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
