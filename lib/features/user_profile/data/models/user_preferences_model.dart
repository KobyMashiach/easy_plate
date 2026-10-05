import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_ce/hive.dart';

import '../../../../core/constants/app_enums.dart';
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
  }) = _UserPreferencesModel;

  factory UserPreferencesModel.fromJson(Map<String, dynamic> json) =>
      _$UserPreferencesModelFromJson(json);
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
  );
}
