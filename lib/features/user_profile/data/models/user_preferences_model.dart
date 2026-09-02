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
  }) = _UserPreferencesModel;

  factory UserPreferencesModel.fromJson(Map<String, dynamic> json) =>
      _$UserPreferencesModelFromJson(json);
}

extension UserPreferencesModelMapper on UserPreferencesModel {
  UserPreferencesEntity toEntity() => UserPreferencesEntity(
        shoppingDay: shoppingDay,
        dietaryPreferences: dietaryPreferences,
        soundEffectsEnabled: soundEffectsEnabled,
        onboardingComplete: onboardingComplete,
      );
}

extension UserPreferencesEntityMapper on UserPreferencesEntity {
  UserPreferencesModel toModel() => UserPreferencesModel(
        shoppingDay: shoppingDay,
        dietaryPreferences: dietaryPreferences,
        soundEffectsEnabled: soundEffectsEnabled,
        onboardingComplete: onboardingComplete,
      );
}
