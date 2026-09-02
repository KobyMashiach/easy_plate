import '../../../../core/constants/app_enums.dart';

class UserPreferencesEntity {
  final ShoppingDay shoppingDay;
  final List<DietaryPreference> dietaryPreferences;
  final AppLanguage language;
  final bool soundEffectsEnabled;

  /// When on, jumping to a distant page rifles through the pages in between
  /// instead of cutting straight to the destination.
  final bool fastPageTurnEnabled;
  final bool onboardingComplete;

  const UserPreferencesEntity({
    required this.shoppingDay,
    required this.dietaryPreferences,
    this.language = AppLanguage.hebrew,
    this.soundEffectsEnabled = true,
    this.fastPageTurnEnabled = true,
    this.onboardingComplete = false,
  });

  UserPreferencesEntity copyWith({
    ShoppingDay? shoppingDay,
    List<DietaryPreference>? dietaryPreferences,
    AppLanguage? language,
    bool? soundEffectsEnabled,
    bool? fastPageTurnEnabled,
    bool? onboardingComplete,
  }) {
    return UserPreferencesEntity(
      shoppingDay: shoppingDay ?? this.shoppingDay,
      dietaryPreferences: dietaryPreferences ?? this.dietaryPreferences,
      language: language ?? this.language,
      soundEffectsEnabled: soundEffectsEnabled ?? this.soundEffectsEnabled,
      fastPageTurnEnabled: fastPageTurnEnabled ?? this.fastPageTurnEnabled,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
    );
  }
}
