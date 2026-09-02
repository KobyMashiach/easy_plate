import '../../../../core/constants/app_enums.dart';

class UserPreferencesEntity {
  final ShoppingDay shoppingDay;
  final List<DietaryPreference> dietaryPreferences;
  final bool soundEffectsEnabled;
  final bool onboardingComplete;

  const UserPreferencesEntity({
    required this.shoppingDay,
    required this.dietaryPreferences,
    this.soundEffectsEnabled = true,
    this.onboardingComplete = false,
  });

  UserPreferencesEntity copyWith({
    ShoppingDay? shoppingDay,
    List<DietaryPreference>? dietaryPreferences,
    bool? soundEffectsEnabled,
    bool? onboardingComplete,
  }) {
    return UserPreferencesEntity(
      shoppingDay: shoppingDay ?? this.shoppingDay,
      dietaryPreferences: dietaryPreferences ?? this.dietaryPreferences,
      soundEffectsEnabled: soundEffectsEnabled ?? this.soundEffectsEnabled,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
    );
  }
}
