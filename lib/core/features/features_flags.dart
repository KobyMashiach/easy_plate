import 'package:flutter/foundation.dart';

import '../monetization/entitlement_service.dart';
import '../services/firebase_service.dart';
import '../utils/i18n/strings.g.dart';

/// What the console says about a feature: the four values of every
/// `ff_*` Remote Config parameter.
enum FeatureFlagValue {
  /// `0` — the entry point is not drawn at all.
  hidden,

  /// `1` — drawn, disabled, marked "coming soon".
  comingSoon,

  /// `2` — the feature as built, for everyone. The default everywhere.
  enabled,

  /// `3` — for paying accounts; a free account sees it locked, and a tap
  /// opens the paywall.
  premiumOnly
  ;

  static FeatureFlagValue fromInt(int value) => switch (value) {
    0 => hidden,
    1 => comingSoon,
    3 => premiumOnly,
    _ => enabled,
  };
}

/// What to draw for *this* account: the console's value with the plan
/// applied to it, which is the only thing a screen has to look at.
enum FeatureAccess {
  hidden,
  comingSoon,

  /// Premium-only, and this account is not: drawn locked, taps go to the
  /// paywall.
  locked,
  enabled
  ;

  bool get isVisible => this != hidden;
  bool get isEnabled => this == enabled;
  bool get isLocked => this == locked;
}

/// Every user-facing feature the console can switch, one parameter each,
/// all in the `featureFlags` parameter group of the Remote Config template
/// (`remoteconfig.template.json`, where the Hebrew descriptions live).
///
/// `FeaturesFlags.notifications.access` is what a screen asks; the
/// [FeatureGate] widget draws the answer. The recipes tab is not here: it
/// is the home screen, and an app with no home has nothing to show a
/// "coming soon" on.
enum FeaturesFlags {
  // Main tabs.
  books('ff_books'),
  mealPlans('ff_meal_plans'),
  groceryLists('ff_grocery_lists'),
  community('ff_community'),

  // Ways a recipe comes in.
  ingestText('ff_ingest_text'),
  ingestWebSearch('ff_ingest_web_search'),
  ingestLink('ff_ingest_link'),
  ingestSocialVideo('ff_ingest_social_video'),
  ingestAiRequest('ff_ingest_ai_request'),
  ingestFile('ff_ingest_file'),
  shareIn('ff_share_in'),
  saveWithAi('ff_save_with_ai'),

  // On a recipe.
  cookMode('ff_cook_mode'),
  cookTimers('ff_cook_timers'),
  nutrition('ff_nutrition'),
  recipeImageAi('ff_recipe_image_ai'),
  recipeImageSearch('ff_recipe_image_search'),
  groceryFromRecipe('ff_grocery_from_recipe'),

  // Community.
  sharedRecipes('ff_shared_recipes'),
  forum('ff_forum'),
  likes('ff_likes'),

  // Sharing with other accounts.
  shareRecipes('ff_share_recipes'),
  shareBooks('ff_share_books'),
  sharePlans('ff_share_plans'),
  shareGroceryLists('ff_share_grocery_lists'),
  shareCodes('ff_share_codes'),
  households('ff_households'),

  // Groceries and prices.
  priceBook('ff_price_book'),
  receiptScan('ff_receipt_scan'),
  groceryCost('ff_grocery_cost'),
  shoppingReminder('ff_shopping_reminder'),

  // Across the app.
  assistant('ff_assistant'),
  assistantScoped('ff_assistant_scoped'),
  assistantVoice('ff_assistant_voice'),
  notifications('ff_notifications'),
  premium('ff_premium'),
  contentTranslation('ff_content_translation'),
  theming('ff_theming'),
  walkthrough('ff_walkthrough'),
  tutorialBook('ff_tutorial_book'),
  feedback('ff_feedback'),

  /// One device per account: not a screen but a policy the server enforces;
  /// 2 refuses a second device, anything else lets them share.
  singleSession('ff_single_session')
  ;

  /// The Remote Config parameter name.
  final String key;

  /// The feature's name in the UI's language, for "X is Premium only".
  String get label => switch (t['featureName.$name']) {
    final String text => text,
    _ => name,
  };

  const FeaturesFlags(this.key);

  static const defaultValue = 2;

  /// The in-app defaults for [FirebaseService.remoteDefaults]: every
  /// feature on for everyone, so a build that never reaches the console
  /// hides nothing.
  static Map<String, int> get remoteDefaults => {
    for (final feature in values) feature.key: defaultValue,
  };

  /// Overrides for tests and the walkthrough; null reads the console.
  @visibleForTesting
  static Map<FeaturesFlags, FeatureFlagValue>? overrides;

  /// Ticks when Remote Config activates or the plan changes — the two
  /// things an answer here depends on.
  static final Listenable listenable = Listenable.merge([
    FirebaseService().configRevision,
    EntitlementService(),
  ]);

  /// The console's value, resolved on every read in the manner of
  /// `MonetizationConfig`.
  FeatureFlagValue get value {
    final override = overrides?[this];
    if (override != null) return override;
    return FeatureFlagValue.fromInt(FirebaseService().remoteInt(key));
  }

  /// [value] with this account's plan applied: the answer a screen draws.
  FeatureAccess get access => resolve(value, EntitlementService().isPremium);

  /// The rule on its own, for tests.
  static FeatureAccess resolve(FeatureFlagValue value, bool premium) =>
      switch (value) {
        FeatureFlagValue.hidden => FeatureAccess.hidden,
        FeatureFlagValue.comingSoon => FeatureAccess.comingSoon,
        FeatureFlagValue.enabled => FeatureAccess.enabled,
        FeatureFlagValue.premiumOnly =>
          premium ? FeatureAccess.enabled : FeatureAccess.locked,
      };

  bool get isVisible => access.isVisible;
  bool get isEnabled => access.isEnabled;

  /// Premium-only in the console, and this account is not paying.
  bool get isLocked => access.isLocked;

  /// The most permissive access among [features]: an entry point that
  /// serves several of them stays as long as one of them does.
  static FeatureAccess ofAny(List<FeaturesFlags> features) {
    var best = FeatureAccess.hidden;
    for (final feature in features) {
      final state = feature.access;
      if (state.index > best.index) best = state;
    }
    return features.isEmpty ? FeatureAccess.enabled : best;
  }
}
