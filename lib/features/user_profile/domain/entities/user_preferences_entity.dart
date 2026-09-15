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

  /// The first-run guided tour was finished or closed. Kept with the rest of
  /// the preferences so it travels to the cloud mirror and a reinstall does
  /// not replay the tour.
  final bool walkthroughSeen;

  /// When a grocery line has no price of the user's own, fall back to what
  /// other people paid. Off by default: an estimate from strangers' receipts
  /// is something to opt into.
  final bool communityPricesEnabled;

  const UserPreferencesEntity({
    required this.shoppingDay,
    required this.dietaryPreferences,
    this.language = AppLanguage.hebrew,
    this.soundEffectsEnabled = true,
    this.fastPageTurnEnabled = true,
    this.onboardingComplete = false,
    this.walkthroughSeen = false,
    this.communityPricesEnabled = false,
  });

  UserPreferencesEntity copyWith({
    ShoppingDay? shoppingDay,
    List<DietaryPreference>? dietaryPreferences,
    AppLanguage? language,
    bool? soundEffectsEnabled,
    bool? fastPageTurnEnabled,
    bool? onboardingComplete,
    bool? walkthroughSeen,
    bool? communityPricesEnabled,
  }) {
    return UserPreferencesEntity(
      shoppingDay: shoppingDay ?? this.shoppingDay,
      dietaryPreferences: dietaryPreferences ?? this.dietaryPreferences,
      language: language ?? this.language,
      soundEffectsEnabled: soundEffectsEnabled ?? this.soundEffectsEnabled,
      fastPageTurnEnabled: fastPageTurnEnabled ?? this.fastPageTurnEnabled,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      walkthroughSeen: walkthroughSeen ?? this.walkthroughSeen,
      communityPricesEnabled: communityPricesEnabled ?? this.communityPricesEnabled,
    );
  }
}
