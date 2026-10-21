import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_ce/hive.dart';

import '../../../../core/constants/app_enums.dart';
import '../../../community/data/doc_fields.dart';
import '../../domain/entities/user_preferences_entity.dart';

part 'user_preferences_model.freezed.dart';
part 'user_preferences_model.g.dart';

@freezed
@HiveType(typeId: 1)
sealed class UserPreferencesModel with _$UserPreferencesModel {
  static const hiveKey = 'userPreferencesBox';
  static const storageKey = 'current';

  const factory UserPreferencesModel({
    @HiveField(0) required ShoppingDay shoppingDay,
    @HiveField(1) required List<DietaryPreference> dietaryPreferences,
    @HiveField(2) @Default(true) bool soundEffectsEnabled,
    @HiveField(3) @Default(false) bool onboardingComplete,
    @HiveField(4) @Default(AppLanguage.hebrew) AppLanguage language,
    @HiveField(5) @Default(true) bool fastPageTurnEnabled,
    // Appended: preferences stored before the tour existed decode as false,
    // which correctly reads as "not seen yet".
    @HiveField(6) @Default(false) bool walkthroughSeen,
    @HiveField(7) @Default(false) bool communityPricesEnabled,
    // Slot names; null (older records) reads as the defaults.
    @HiveField(8) List<String>? shoppingReminderSlots,
    // Notification choices, appended in one go. Records written before them
    // decode as "on", which is what every account had until now. The json
    // keys below are what the Cloud Functions read from the cloud mirror,
    // so they are named exactly as the entity's fields.
    @HiveField(9) @Default(true) bool pushEnabled,
    @HiveField(10) @Default(true) bool notifyRepliesOnMyPosts,
    @HiveField(11) @Default(true) bool notifyRepliesOnThreads,
    @HiveField(12) @Default(true) bool notifyShareInvites,
    @HiveField(13) @Default(true) bool notifySharedRecipeUpdates,
    @HiveField(14) @Default(true) bool notifyAdminReplies,
    @HiveField(15) @Default(true) bool notifyAnnouncements,
    @HiveField(16) @Default(true) bool foregroundPopupsEnabled,

    /// An `AppThemeMode` name; see the entity.
    @HiveField(17) String? themeMode,

    /// The build number whose "what's new" book was acknowledged; null
    /// (older records) reads as "never".
    @HiveField(18) int? whatsNewSeenBuild,
  }) = _UserPreferencesModel;

  factory UserPreferencesModel.fromJson(Map<String, dynamic> json) =>
      _$UserPreferencesModelFromJson(tolerantJson(json));

  static const _flags = [
    'soundEffectsEnabled',
    'onboardingComplete',
    'fastPageTurnEnabled',
    'walkthroughSeen',
    'communityPricesEnabled',
    'pushEnabled',
    'notifyRepliesOnMyPosts',
    'notifyRepliesOnThreads',
    'notifyShareInvites',
    'notifySharedRecipeUpdates',
    'notifyAdminReplies',
    'notifyAnnouncements',
    'foregroundPopupsEnabled',
  ];

  /// The cloud record with anything this build cannot decode put back to
  /// its default. The website writes the same document, and the generated
  /// decoder throws on an unknown enum name or a field of the wrong type —
  /// which cost the device every preference in the record, not just the
  /// odd field.
  @visibleForTesting
  static Map<String, dynamic> tolerantJson(Map<String, dynamic> json) {
    final out = Map<String, dynamic>.of(json);
    out['shoppingDay'] =
        (docEnum(ShoppingDay.values, json['shoppingDay']) ?? ShoppingDay.sunday)
            .name;
    out['dietaryPreferences'] = [
      for (final name in docStrings(json['dietaryPreferences']))
        if (docEnum(DietaryPreference.values, name) != null) name,
    ];
    if (docEnum(AppLanguage.values, json['language']) == null) {
      out.remove('language');
    }
    for (final key in _flags) {
      if (out[key] is! bool) out.remove(key);
    }
    if (json['shoppingReminderSlots'] is List) {
      out['shoppingReminderSlots'] = docStrings(json['shoppingReminderSlots']);
    } else {
      out.remove('shoppingReminderSlots');
    }
    if (json['themeMode'] is! String) out.remove('themeMode');
    final seen = docInt(json['whatsNewSeenBuild']);
    if (seen == null) {
      out.remove('whatsNewSeenBuild');
    } else {
      out['whatsNewSeenBuild'] = seen;
    }
    return out;
  }
}

extension UserPreferencesModelMapper on UserPreferencesModel {
  UserPreferencesEntity toEntity() => UserPreferencesEntity(
    shoppingDay: shoppingDay,
    dietaryPreferences: dietaryPreferences,
    language: language,
    soundEffectsEnabled: soundEffectsEnabled,
    fastPageTurnEnabled: fastPageTurnEnabled,
    onboardingComplete: onboardingComplete,
    walkthroughSeen: walkthroughSeen,
    communityPricesEnabled: communityPricesEnabled,
    shoppingReminderSlots: shoppingReminderSlots == null
        ? ShoppingReminderSlot.defaults
        : ShoppingReminderSlot.fromNames(shoppingReminderSlots!),
    pushEnabled: pushEnabled,
    notifyRepliesOnMyPosts: notifyRepliesOnMyPosts,
    notifyRepliesOnThreads: notifyRepliesOnThreads,
    notifyShareInvites: notifyShareInvites,
    notifySharedRecipeUpdates: notifySharedRecipeUpdates,
    notifyAdminReplies: notifyAdminReplies,
    notifyAnnouncements: notifyAnnouncements,
    foregroundPopupsEnabled: foregroundPopupsEnabled,
    themeMode: themeMode,
    whatsNewSeenBuild: whatsNewSeenBuild,
  );
}

extension UserPreferencesEntityMapper on UserPreferencesEntity {
  UserPreferencesModel toModel() => UserPreferencesModel(
    shoppingDay: shoppingDay,
    dietaryPreferences: dietaryPreferences,
    language: language,
    soundEffectsEnabled: soundEffectsEnabled,
    fastPageTurnEnabled: fastPageTurnEnabled,
    onboardingComplete: onboardingComplete,
    walkthroughSeen: walkthroughSeen,
    communityPricesEnabled: communityPricesEnabled,
    shoppingReminderSlots: [for (final s in shoppingReminderSlots) s.name],
    pushEnabled: pushEnabled,
    notifyRepliesOnMyPosts: notifyRepliesOnMyPosts,
    notifyRepliesOnThreads: notifyRepliesOnThreads,
    notifyShareInvites: notifyShareInvites,
    notifySharedRecipeUpdates: notifySharedRecipeUpdates,
    notifyAdminReplies: notifyAdminReplies,
    notifyAnnouncements: notifyAnnouncements,
    foregroundPopupsEnabled: foregroundPopupsEnabled,
    themeMode: themeMode,
    whatsNewSeenBuild: whatsNewSeenBuild,
  );
}
