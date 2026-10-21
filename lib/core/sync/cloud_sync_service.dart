import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../features/grocery_list/data/models/grocery_list_model.dart';
import '../../features/price_book/data/models/price_record_model.dart';
import '../../features/price_book/data/models/product_pricing_model.dart';
import '../../features/price_book/data/models/receipt_model.dart';
import '../../features/meal_planner/data/models/meal_plan_model.dart';
import '../../features/my_recipes/data/models/recipe_model.dart';
import '../../features/recipe_books/data/models/recipe_book_model.dart';
import '../../features/user_profile/data/models/user_preferences_model.dart';
import '../hive/user_scope.dart';
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

  static const preferencesCollection = 'preferences';

  /// Preferences are a single record, so they get a collection with one fixed
  /// id rather than a shape of their own — the shopping day then travels the
  /// same path as everything else.
  late final UserCloudCollection<UserPreferencesModel> preferences =
      UserCloudCollection(
        boxName: UserPreferencesModel.hiveKey,
        collection: preferencesCollection,
        shared: false,
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

  late final UserCloudCollection<GroceryListModel> groceryLists =
      UserCloudCollection(
        boxName: GroceryListModel.hiveKey,
        collection: 'grocery_lists',
        idOf: (model) => model.id,
        toJson: (model) => model.toJson(),
        fromJson: GroceryListModel.fromJson,
      );

  /// The day's quota spend, one record like the preferences. Mirrored so a
  /// second device — or a reinstall — continues today's count instead of
  /// starting a fresh one.
  late final UserCloudCollection<DailyUsageModel> dailyUsage =
      UserCloudCollection(
        boxName: DailyUsageModel.hiveKey,
        collection: 'usage',
        shared: false,
        idOf: (_) => DailyUsageModel.storageKey,
        toJson: (model) => model.toJson(),
        fromJson: DailyUsageModel.fromJson,
      );

  /// The personal price book, one record per receipt line.
  late final UserCloudCollection<PriceRecordModel> priceRecords =
      UserCloudCollection(
        boxName: PriceRecordModel.hiveKey,
        collection: 'price_records',
        idOf: (model) => model.id,
        toJson: (model) => model.toJson(),
        fromJson: PriceRecordModel.fromJson,
      );

  late final UserCloudCollection<ReceiptModel> receipts = UserCloudCollection(
    boxName: ReceiptModel.hiveKey,
    collection: 'receipts',
    idOf: (model) => model.id,
    toJson: (model) => model.toJson(),
    fromJson: ReceiptModel.fromJson,
  );

  late final UserCloudCollection<ProductPricingModel> productPricing =
      UserCloudCollection(
        boxName: ProductPricingModel.hiveKey,
        collection: 'product_pricing',
        idOf: (model) => model.key,
        toJson: (model) => model.toJson(),
        fromJson: ProductPricingModel.fromJson,
      );

  /// Tests only: stands in for the real mirrors, which need Firestore.
  @visibleForTesting
  List<CloudMirror>? mirrorsForTest;

  List<CloudMirror> get _mirrors =>
      mirrorsForTest ??
      [
        preferences,
        recipes,
        books,
        mealPlans,
        groceryLists,
        dailyUsage,
        priceRecords,
        receipts,
        productPricing,
      ];

  /// The account already hydrated in this session, so the repeated auth events
  /// that follow a credential link or an email confirmation do not re-read the
  /// whole account every time.
  String? _hydratedUid;

  /// The pass under way, and for whom: the auth events that follow each
  /// other within a second (a credential link, an email confirmation, the
  /// sign-in itself) share one pass instead of each reading the whole
  /// account in parallel.
  Future<void>? _inFlight;
  String? _inFlightUid;

  /// Pulls [uid]'s cloud copy into the local boxes.
  ///
  /// Awaited by the auth gate, because the stage it picks depends on what comes
  /// back: preferences carry `onboardingComplete`, and a returning user sent
  /// back through onboarding is exactly the bug this fixes. Capped so a network
  /// that hangs rather than fails leaves the user on the splash for a few
  /// seconds and then in the app, working off whatever is local.
  Future<void> hydrate(
    String uid, {
    Duration timeout = const Duration(seconds: 12),
  }) {
    if (_hydratedUid == uid) return Future.value();
    if (_inFlight case final running? when _inFlightUid == uid) return running;
    return _track(uid, _pass(uid, timeout));
  }

  /// Resume re-reads are spaced at least this far apart (from the last
  /// pass of any kind), like the shared-recipe pull.
  static const refreshInterval = Duration(minutes: 2);

  @visibleForTesting
  DateTime Function() clock = DateTime.now;

  DateTime? _lastPass;

  /// Re-reads the account's cloud copy on a return to the app, so an edit
  /// made on the website (or another device) while this one sat in the
  /// background shows up without a relaunch. Same merge as sign-in: the
  /// cloud wins per record, a record only the box has is pushed back, and
  /// a key saved on this device during the read is left alone.
  ///
  /// The household's shared mirrors are skipped while their listeners are
  /// open — those already follow the server live. Nothing runs before the
  /// sign-in pass has finished for [uid], nor while another pass is out.
  ///
  /// Returns the collections whose boxes changed, so the caller can
  /// re-apply what is not box-watched (the preferences).
  ///
  /// Cost: one billed read per document in every mirror it reads (recipes,
  /// books, plans, lists, price lines, receipts, pricing, plus the two
  /// single-record ones), at most once per [refreshInterval]. A heavy
  /// account (500 recipes, 2,000 price lines) is a few thousand reads per
  /// resume. There is no cheap "unchanged" signal to skip a collection on:
  /// the records carry no `updatedAt` (and the website writes every one of
  /// these collections), nothing counts them on the account document, and
  /// a `count()` aggregation sees adds and deletes but not an edit — the
  /// very thing this pass exists to pick up. Skipping would need every
  /// writer (app, website, functions) to stamp a server time first.
  Future<Set<String>> refresh(
    String uid, {
    Duration timeout = const Duration(seconds: 12),
  }) {
    if (_hydratedUid != uid || _inFlight != null) return Future.value({});
    final now = clock();
    if (_lastPass case final last?
        when now.difference(last) < refreshInterval) {
      return Future.value({});
    }
    _lastPass = now;
    return _track(
      uid,
      _pass(uid, timeout, skip: (mirror) => _listening && mirror.shared),
    );
  }

  /// Registers [run] as the pass in flight for [uid] until it settles.
  Future<T> _track<T>(String uid, Future<T> pass) {
    late final Future<T> run;
    run = pass.whenComplete(() {
      // Only this pass clears itself: a later one for the same account may
      // already be in its place.
      if (identical(_inFlight, run)) {
        _inFlight = null;
        _inFlightUid = null;
      }
    });
    _inFlight = run;
    _inFlightUid = uid;
    return run;
  }

  /// One pass over every mirror but those [skip] names; never throws.
  /// Returns the collections whose boxes it wrote to.
  Future<Set<String>> _pass(
    String uid,
    Duration timeout, {
    bool Function(CloudMirror mirror)? skip,
  }) async {
    // The scope this pass reads into. A sign-out wipe and a sign-in back to
    // the same account during the pass leave the uid as it was, but the
    // boxes this pass filled are gone.
    final scope = UserScope().generation;
    try {
      // Resolved inside the try: building the real mirrors touches
      // Firestore, and a failure there is an incomplete pass, not a throw.
      final mirrors = [
        for (final mirror in _mirrors)
          if (!(skip?.call(mirror) ?? false)) mirror,
      ];
      final changed = await Future.wait(
        mirrors.map((mirror) => mirror.hydrate()),
      ).timeout(timeout);
      // Only on a clean pass: a timeout leaves some mirrors unread, and the
      // next auth event should get another go at them. And only while this
      // is still the signed-in account: a pass that finishes after a quick
      // account switch (or a wipe and a re-sign-in) must not mark the
      // account now signed in as done.
      if (UserScope().uid != uid || UserScope().generation != scope) {
        return {};
      }
      _hydratedUid = uid;
      _lastPass = clock();
      return {
        for (final (index, mirror) in mirrors.indexed)
          if (changed[index]) mirror.collection,
      };
    } catch (e) {
      debugPrint('Cloud hydrate incomplete: $e');
      return {};
    }
  }

  /// On sign-out, once the local boxes are deleted: the next sign-in of the
  /// same account has to pull everything back, not skip it as already done.
  void forget() {
    _hydratedUid = null;
    _lastPass = null;
    // A pass still running belongs to the account that left; the next
    // sign-in starts its own rather than inherit one that read into boxes
    // since deleted.
    _inFlight = null;
    _inFlightUid = null;
    // Only when listeners exist: touching the mirrors builds them, and
    // tests without Firebase sign out too.
    if (_listening) unawaited(stopListening());
  }

  bool _listening = false;

  /// Live mirroring, on while the account is in a household: a plan one
  /// member changes is on the other's phone a moment later.
  ///
  /// Kept open in the background on purpose. A listener reopened after a
  /// pause starts from a fresh snapshot, which never reports a deletion
  /// made during the gap, and a reconciling hydrate cannot apply one either:
  /// a record missing from the server may as well be one this device has
  /// not pushed yet (offline save, a push before the root resolved), and
  /// only records in the device's ledger (see `CloudSyncLedger`) carry a
  /// "confirmed" mark to tell the two apart. Closing them would lean on that
  /// ledger alone for every deletion a member made during the gap.
  Future<void> startListening() async {
    _listening = true;
    for (final mirror in _mirrors) {
      if (mirror.shared) await mirror.listen();
    }
  }

  Future<void> stopListening() async {
    if (!_listening) return;
    _listening = false;
    for (final mirror in _mirrors) {
      await mirror.stopListening();
    }
  }

  bool get isListening => _listening;

  /// The account moved roots (joined, left or opened a household): the
  /// shared mirrors are read again from the new root. Joining merges what
  /// the box holds into the household (hydrate pushes back what the root
  /// lacks); leaving first empties the shared boxes, or the household's data
  /// would be pushed into the member's own root.
  Future<void> rehome(String uid, {required bool wipeShared}) async {
    await stopListening();
    // A pass from the old root still running would be shared by the hydrate
    // below and read the wrong root: let it finish first.
    if (_inFlight case final running?) await running;
    _hydratedUid = null;
    if (wipeShared) {
      for (final mirror in _mirrors) {
        if (mirror.shared) await mirror.clearLocal();
      }
    }
    await hydrate(uid);
    if (CloudRoot.householdId != null) await startListening();
  }

  /// Tests share the singleton, and a leftover uid would skip their hydrate.
  @visibleForTesting
  void resetForTest() {
    _hydratedUid = null;
    _lastPass = null;
    clock = DateTime.now;
    _inFlight = null;
    _inFlightUid = null;
  }
}
