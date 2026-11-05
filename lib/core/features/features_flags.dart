import 'package:flutter/foundation.dart';

import '../monetization/entitlement_service.dart';
import '../services/admin_access.dart';
import '../services/auth_session_service.dart';
import '../services/firebase_service.dart';
import '../utils/i18n/strings.g.dart';

/// What the console says about a feature: the five values of every
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
  premiumOnly,

  /// `4` — drawn, disabled, marked "maintenance": a feature that was open
  /// and is switched off for a while, for everyone, Premium included.
  maintenance
  ;

  static FeatureFlagValue fromInt(int value) => switch (value) {
    0 => hidden,
    1 => comingSoon,
    3 => premiumOnly,
    4 => maintenance,
    _ => enabled,
  };
}

/// What to draw for *this* account: the console's value with the plan
/// applied to it, which is the only thing a screen has to look at.
///
/// The order is from least to most open: [FeaturesFlags.ofAny] takes the
/// highest.
enum FeatureAccess {
  hidden,
  comingSoon,

  /// Under maintenance: drawn disabled for every account.
  maintenance,

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

  /// The pictures that come with a recipe read from a video: the post's
  /// cover goes on the recipe by itself, and the stills of the food the
  /// server cut are offered on the review screen. Hidden, the recipe is
  /// saved without a picture, as before.
  socialVideoPhoto('ff_social_video_photo'),
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

  /// The "original recipe" row on the recipe screen, opening the page or
  /// the video the recipe was imported from.
  recipeSourceLink('ff_recipe_source_link'),
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

  /// More than one shopping day a week in the preferences, each with its
  /// own reminders. Closed, the picker takes one day, as before.
  multiShoppingDays('ff_multi_shopping_days'),

  // Across the app.
  assistant('ff_assistant'),
  assistantScoped('ff_assistant_scoped'),
  assistantVoice('ff_assistant_voice'),
  notifications('ff_notifications'),

  /// One push kind each, under התראות in the console: read by the server
  /// after ff_notifications (a closed kind keeps the inbox item, the phone
  /// does not ring) and by the settings screen, which hides or locks the
  /// kind's switch.
  pushReplyMyPost('ff_push_reply_my_post'),
  pushReplyThread('ff_push_reply_thread'),
  pushShareInvite('ff_push_share_invite'),
  pushSharedUpdate('ff_push_shared_update'),
  pushAdminReply('ff_push_admin_reply'),
  pushAnnouncements('ff_push_announcements'),
  premium('ff_premium'),
  contentTranslation('ff_content_translation'),
  theming('ff_theming'),
  walkthrough('ff_walkthrough'),
  tutorialBook('ff_tutorial_book'),
  feedback('ff_feedback'),

  /// One device per account: not a screen but a policy the server enforces;
  /// 2 refuses a second device, anything else lets them share.
  singleSession('ff_single_session'),

  /// The home-screen widgets (Shefi button, quick add, the list, today's
  /// menu) and the settings screen that places them. Hidden, the widgets
  /// on the phone show only a way into the app.
  homeWidgets('ff_home_widgets'),

  /// "Hey Shefi": the wake words open a spoken Shefi conversation, while
  /// the app is open and (Android) after it is closed. Rides on
  /// [assistant] and [assistantVoice]: listening needs all three.
  wakeWord('ff_wake_word'),

  /// Shefi through the system assistants: Siri (CarPlay included) runs a
  /// request in the background and reads the answer out; the Android side
  /// is ready for Gemini once Google opens app functions. Rides on
  /// [assistant].
  voiceAssistants('ff_voice_assistants'),

  /// Android: the "שפי" app-drawer icon that opens Shefi listening, which
  /// also lets "Hey Google, open Shefi" start a conversation with no
  /// microphone of ours open. Shown only where [assistant] is open too.
  shefiLauncher('ff_shefi_launcher'),

  /// "What's new": the book of release highlights a returning account is
  /// shown once after an update, drawn from the `whats_new_releases`
  /// collection the web console edits. Hidden, nothing is shown and the
  /// seen-build pointer is left where it is.
  whatsNew('ff_whats_new'),

  /// The support conversation: the user's follow-ups and the chat screen
  /// behind a message from the support form, the list of their
  /// conversations, and Shefi's contact_support tool. Hidden, the form
  /// still sends a one-off message that is answered through the inbox.
  supportChat('ff_support_chat'),

  /// The store's own "rate this app" sheet (App Store / Google Play
  /// in-app review), asked once after the second saved recipe and then
  /// no more than once a season. Hidden, the sheet is never requested.
  storeReview('ff_store_review'),

  /// The app icon's long-press menu: talk to Shefi, add to the grocery
  /// list, add a receipt, contact support. Each shortcut also needs its
  /// own feature visible; hidden, the menu is empty.
  quickActions('ff_quick_actions'),

  /// The bin on a recipe's own screen: deletes the recipe (and, when it was
  /// never published or shared, its photo) after a confirmation. On a shared
  /// recipe it removes only this account's copy. Hidden, recipes can still
  /// be removed through Shefi and a saved community copy from its card.
  deleteRecipe('ff_delete_recipe'),

  /// Headings over the groups of a divided ingredient list ("רוטב", "בשר")
  /// on the recipe screen, the review, cook mode and the book page. Hidden,
  /// the list is drawn as one run; the sections stay in the data, and a
  /// heading never reaches a grocery list either way.
  ingredientSections('ff_ingredient_sections'),

  /// "Suggestions for me" on the web-search channel: up to ten recipes
  /// found for the account's diet and the dishes it keeps, opened and
  /// analysed one at a time, a save returning to the list for the next.
  recipeSuggestions('ff_recipe_suggestions'),

  /// Premium bought on the website (aieasyplate.app/app) through PayPlus
  /// (Israeli accounts) or RevenueCat's Paddle checkout (abroad; per-provider switches
  /// ff_web_checkout_il / ff_web_checkout_intl live on the website only)
  /// instead of the stores: the "upgrade / manage on the web" row in the
  /// account menu and the paywall's web hand-off. The server reads the same
  /// flag, so hidden here also refuses checkout and upgrade links there.
  /// Store policy on linking out to an external purchase differs by
  /// region, which is why this one ships hidden.
  webCheckout('ff_web_checkout')
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
    // The permission (superuser, admin with "all features") rides on the
    // profile the session resolves.
    AuthSessionService(),
  ]);

  /// The console's value, resolved on every read in the manner of
  /// `MonetizationConfig`.
  FeatureFlagValue get value {
    final override = overrides?[this];
    if (override != null) return override;
    return FeatureFlagValue.fromInt(FirebaseService().remoteInt(key));
  }

  /// [value] with this account's plan applied: the answer a screen draws.
  FeatureAccess get access => resolve(
    value,
    EntitlementService().isPremium,
    allFeatures: AdminAccess.hasAllFeatures,
  );

  /// The rule on its own, for tests. [allFeatures] is the superuser (or the
  /// administrator with `admin_all_features`): nothing is hidden, coming
  /// soon or locked for them.
  static FeatureAccess resolve(
    FeatureFlagValue value,
    bool premium, {
    bool allFeatures = false,
  }) => allFeatures
      ? FeatureAccess.enabled
      : switch (value) {
          FeatureFlagValue.hidden => FeatureAccess.hidden,
          FeatureFlagValue.comingSoon => FeatureAccess.comingSoon,
          FeatureFlagValue.maintenance => FeatureAccess.maintenance,
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
