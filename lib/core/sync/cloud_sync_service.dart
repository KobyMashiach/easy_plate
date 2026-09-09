import 'package:flutter/foundation.dart';

import '../../features/grocery_list/data/models/grocery_list_model.dart';
import '../../features/meal_planner/data/models/meal_plan_model.dart';
import '../../features/my_recipes/data/models/recipe_model.dart';
import '../../features/recipe_books/data/models/recipe_book_model.dart';
import '../../features/user_profile/data/models/user_preferences_model.dart';
import '../monetization/daily_usage_model.dart';
import 'user_cloud_collection.dart';

/// Every per-account box that is mirrored to Firestore, in one place.
///
/// A singleton because the mirrors are handed to the repositories that write
/// through them *and* driven by [AuthSessionService] on sign-in; two sets of
/// instances would mean saves going through one and hydration through another.
class CloudSyncService {
  static final CloudSyncService _instance = CloudSyncService._internal();
  factory CloudSyncService() => _instance;
  CloudSyncService._internal();

  /// Preferences are a single record, so they get a collection with one fixed
  /// id rather than a shape of their own — the shopping day then travels the
  /// same path as everything else.
  late final UserCloudCollection<UserPreferencesModel> preferences = UserCloudCollection(
    boxName: UserPreferencesModel.hiveKey,
    collection: 'preferences',
    idOf: (_) => UserPreferencesModel.storageKey,
    toJson: (model) => model.toJson(),
    fromJson: UserPreferencesModel.fromJson,
  );

  late final UserCloudCollection<RecipeModel> recipes = UserCloudCollection(
    boxName: RecipeModel.hiveKey,
    collection: 'recipes',
    idOf: (model) => model.id,
    toJson: (model) => model.toJson(),
    fromJson: RecipeModel.fromJson,
  );

  late final UserCloudCollection<RecipeBookModel> books = UserCloudCollection(
    boxName: RecipeBookModel.hiveKey,
    collection: 'books',
    idOf: (model) => model.id,
    toJson: (model) => model.toJson(),
    fromJson: RecipeBookModel.fromJson,
  );

  late final UserCloudCollection<MealPlanModel> mealPlans = UserCloudCollection(
    boxName: MealPlanModel.hiveKey,
    collection: 'meal_plans',
    idOf: (model) => model.id,
    toJson: (model) => model.toJson(),
    fromJson: MealPlanModel.fromJson,
  );

  late final UserCloudCollection<GroceryListModel> groceryLists = UserCloudCollection(
    boxName: GroceryListModel.hiveKey,
    collection: 'grocery_lists',
    idOf: (model) => model.id,
    toJson: (model) => model.toJson(),
    fromJson: GroceryListModel.fromJson,
  );

  /// The day's quota spend, one record like the preferences. Mirrored so a
  /// second device — or a reinstall — continues today's count instead of
  /// starting a fresh one.
  late final UserCloudCollection<DailyUsageModel> dailyUsage = UserCloudCollection(
    boxName: DailyUsageModel.hiveKey,
    collection: 'usage',
    idOf: (_) => DailyUsageModel.storageKey,
    toJson: (model) => model.toJson(),
    fromJson: DailyUsageModel.fromJson,
  );

  List<CloudMirror> get _mirrors =>
      [preferences, recipes, books, mealPlans, groceryLists, dailyUsage];

  /// The account already hydrated in this session, so the repeated auth events
  /// that follow a credential link or an email confirmation do not re-read the
  /// whole account every time.
  String? _hydratedUid;

  /// Pulls [uid]'s cloud copy into the local boxes.
  ///
  /// Awaited by the auth gate, because the stage it picks depends on what comes
  /// back: preferences carry `onboardingComplete`, and a returning user sent
  /// back through onboarding is exactly the bug this fixes. Capped so a network
  /// that hangs rather than fails leaves the user on the splash for a few
  /// seconds and then in the app, working off whatever is local.
  Future<void> hydrate(String uid, {Duration timeout = const Duration(seconds: 12)}) async {
    if (_hydratedUid == uid) return;

    try {
      await Future.wait(_mirrors.map((mirror) => mirror.hydrate())).timeout(timeout);
      // Only on a clean pass: a timeout leaves some mirrors unread, and the
      // next auth event should get another go at them.
      _hydratedUid = uid;
    } catch (e) {
      debugPrint('Cloud hydrate incomplete: $e');
    }
  }

  /// Tests share the singleton, and a leftover uid would skip their hydrate.
  @visibleForTesting
  void resetForTest() => _hydratedUid = null;
}
