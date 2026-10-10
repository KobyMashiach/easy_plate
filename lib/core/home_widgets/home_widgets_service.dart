import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../features/collab_containers/domain/container_sharing_service.dart';
import '../../features/grocery_list/data/datasources/active_grocery_list_store.dart';
import '../../features/grocery_list/domain/entities/grocery_item_entity.dart';
import '../../features/grocery_list/domain/entities/grocery_item_source_entity.dart';
import '../../features/grocery_list/domain/entities/grocery_list_entity.dart';
import '../../features/grocery_list/domain/repositories/grocery_lists_repository.dart';
import '../../features/meal_planner/domain/entities/meal_plan_entity.dart';
import '../../features/meal_planner/domain/repositories/meal_plans_repository.dart';
import '../../features/my_recipes/domain/entities/recipe_entity.dart';
import '../../features/my_recipes/domain/repositories/recipes_repository.dart';
import '../constants/app_enums.dart';
import '../features/features_flags.dart';
import '../hive/user_scope.dart';
import '../services/auth_session_service.dart';
import '../theme/theme_controller.dart';
import '../utils/i18n/strings.g.dart';
import 'home_widget_defaults_store.dart';
import 'home_widgets_channel.dart';
import 'home_widgets_snapshot.dart';

/// Keeps the home-screen widgets in step with the account.
///
/// Publishing: once a session is ready, the lists, plans and recipe titles
/// are watched (the same box streams the tabs follow), and every change —
/// theirs, the theme's, the language's, the console flags', the widget
/// defaults' — rewrites the snapshot after a short quiet period. Signing
/// out clears it, so nothing of the account stays on the home screen.
///
/// Draining: a widget cannot write to the account's boxes itself (a
/// second isolate on the same Hive file is how a box gets corrupted), so
/// a line added from the Android quick-add dialog or a tick on an iOS
/// widget is queued in the shared store, drawn optimistically by the
/// widget, and applied here — through the same repositories the screens
/// use, so the tabs and the cloud mirror see it — as soon as the app is
/// alive: at once when it is open (the native side nudges the channel),
/// else on the next launch or resume.
class HomeWidgetsService {
  static final HomeWidgetsService _instance = HomeWidgetsService._internal();
  factory HomeWidgetsService() => _instance;
  HomeWidgetsService._internal();

  /// For tests: everything the service talks to can be swapped.
  @visibleForTesting
  HomeWidgetsService.forTest({
    required HomeWidgetsChannel channel,
    required this.groceries,
    required this.plans,
    required this.recipes,
    this.sharing,
    this.activeList,
  }) : _channel = channel;

  late HomeWidgetsChannel _channel = HomeWidgetsChannel();
  GroceryListsRepository? groceries;
  MealPlansRepository? plans;
  RecipesRepository? recipes;
  ContainerSharingService? sharing;
  ActiveGroceryListStore? activeList;

  static const _uuid = Uuid();

  bool _bound = false;
  bool _ready = false;
  StreamSubscription<List<GroceryListEntity>>? _listsSub;
  StreamSubscription<List<MealPlanEntity>>? _plansSub;
  StreamSubscription<List<RecipeEntity>>? _recipesSub;
  StreamSubscription<AppLocale>? _localeSub;
  List<GroceryListEntity> _lists = const [];
  List<MealPlanEntity> _plans = const [];
  Map<String, String> _recipeTitles = const {};
  Timer? _publishTimer;
  bool _draining = false;

  /// Wires the repositories and starts following the session. Safe to
  /// call more than once.
  void bind({
    required GroceryListsRepository groceries,
    required MealPlansRepository plans,
    required RecipesRepository recipes,
    ContainerSharingService? sharing,
    ActiveGroceryListStore? activeList,
  }) {
    this.groceries = groceries;
    this.plans = plans;
    this.recipes = recipes;
    this.sharing = sharing;
    this.activeList = activeList;
    if (_bound) return;
    _bound = true;
    _channel.onPendingChanged = () => unawaited(drain());
    AuthSessionService().addListener(_onSession);
    ThemeController().addListener(schedulePublish);
    FeaturesFlags.listenable.addListener(schedulePublish);
    HomeWidgetDefaultsStore().listenable.addListener(schedulePublish);
    _localeSub ??= LocaleSettings.getLocaleStream().listen(
      (_) => schedulePublish(),
    );
    unawaited(HomeWidgetDefaultsStore().read());
    _onSession();
  }

  void _onSession() {
    final stage = AuthSessionService().stage;
    if (stage == AuthStage.ready) {
      if (!_ready) _start();
      return;
    }
    if (_ready) _stop();
    // Only a real sign-out empties the home screen: a session that is
    // merely waiting (another device, an expired month) keeps what it
    // had until it resolves one way or the other.
    if (stage == AuthStage.signedOut) {
      _lists = const [];
      _plans = const [];
      _recipeTitles = const {};
      unawaited(_channel.clear());
    }
  }

  void _start() {
    _ready = true;
    final groceries = this.groceries;
    final plans = this.plans;
    final recipes = this.recipes;
    if (groceries == null || plans == null || recipes == null) return;
    _listsSub = groceries.watchLists().listen((lists) {
      _lists = lists;
      schedulePublish();
    }, onError: (Object e) => debugPrint('Widget lists stream: $e'));
    _plansSub = plans.watchPlans().listen((plans) {
      _plans = plans;
      schedulePublish();
    }, onError: (Object e) => debugPrint('Widget plans stream: $e'));
    _recipesSub = recipes.watchRecipes().listen((recipes) {
      _recipeTitles = {for (final r in recipes) r.id: r.title};
      schedulePublish();
    }, onError: (Object e) => debugPrint('Widget recipes stream: $e'));
    // Whatever the widgets wrote while the app was away, before the first
    // snapshot overwrites their optimistic view of it.
    unawaited(drain());
  }

  void _stop() {
    _ready = false;
    _listsSub?.cancel();
    _plansSub?.cancel();
    _recipesSub?.cancel();
    _listsSub = _plansSub = _recipesSub = null;
    _publishTimer?.cancel();
  }

  /// Rewrites the snapshot soon. Bursts (a cloud hydrate, a theme flip
  /// that rebuilds everything) collapse into one write.
  void schedulePublish() {
    if (!_bound) return;
    _publishTimer?.cancel();
    _publishTimer = Timer(const Duration(milliseconds: 250), () {
      unawaited(publishNow());
    });
  }

  /// The snapshot as things stand, written out.
  Future<void> publishNow() async {
    _publishTimer?.cancel();
    try {
      await _channel.publish(buildSnapshot().encode());
    } catch (e) {
      debugPrint('Home widgets publish failed: $e');
    }
  }

  @visibleForTesting
  HomeWidgetsSnapshot buildSnapshot({DateTime? now}) {
    final locale = LocaleSettings.currentLocale;
    final rtl = locale == AppLocale.he || locale == AppLocale.ar;
    final theme = ThemeController();
    final dark = theme.resolvesDark(theme.mode);
    final signedIn =
        AuthSessionService().stage == AuthStage.ready && _ready;
    if (!signedIn) {
      return HomeWidgetsSnapshot.signedOut(
        language: locale.languageCode,
        rtl: rtl,
        dark: dark,
        now: now,
      );
    }
    final lists = [..._lists]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final plans = [..._plans]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return HomeWidgetsSnapshot(
      signedIn: true,
      access: FeaturesFlags.homeWidgets.access,
      assistantAccess: FeaturesFlags.assistant.access,
      language: locale.languageCode,
      rtl: rtl,
      dark: dark,
      defaults: HomeWidgetDefaultsStore().value,
      lists: lists,
      plans: plans,
      recipeTitles: _recipeTitles,
      now: now ?? DateTime.now(),
    );
  }

  /// Applies the widgets' queued writes through the repositories, then
  /// removes them from the queue. Entries that cannot be applied (a list
  /// that no longer exists) are dropped rather than retried forever.
  Future<void> drain() async {
    if (_draining || !_ready) return;
    final groceries = this.groceries;
    if (groceries == null) return;
    _draining = true;
    try {
      final pending = await _channel.readPending();
      if (pending.isEmpty) return;
      final done = <String>[];
      for (final entry in pending) {
        final id = entry['id'];
        try {
          await applyPending(entry, groceries);
        } catch (e) {
          debugPrint('Widget action failed: $e');
        }
        if (id is String) done.add(id);
      }
      await _channel.removePending(done);
    } finally {
      _draining = false;
    }
  }

  /// One queued action. `add` appends a line, as the groceries tab's add
  /// sheet would, with a quantity of one unit; `toggle` ticks or unticks
  /// a line. A missing list id, or one that is gone, falls back to the
  /// list the widgets default to, then the open one, then the oldest, and
  /// for an add with no list at all the meal-plan list is created, as the
  /// groceries tab does on its first write.
  @visibleForTesting
  Future<void> applyPending(
    Map<String, Object?> entry,
    GroceryListsRepository groceries,
  ) async {
    final type = entry['type'];
    final list = await _resolveList(entry['listId'] as String?, groceries);
    if (list == null) return;
    GroceryListEntity? updated;
    switch (type) {
      case 'add':
        final name = (entry['name'] as String? ?? '').trim();
        if (name.isEmpty) return;
        updated = list.copyWith(
          items: [
            ...list.items,
            GroceryItemEntity(
              id: _uuid.v4(),
              name: name,
              unit: MeasurementUnit.unit,
              sources: [GroceryItemSourceEntity(label: name, amount: 1)],
              category: 'כללי',
              isAdHoc: true,
            ),
          ],
        );
      case 'toggle':
        final itemId = entry['itemId'];
        final checked = entry['checked'];
        if (itemId is! String) return;
        final items = [
          for (final item in list.items)
            if (item.id == itemId)
              item.copyWith(
                isChecked: checked is bool ? checked : !item.isChecked,
              )
            else
              item,
        ];
        updated = list.copyWith(items: items);
      default:
        return;
    }
    await groceries.saveList(updated);
    final uid = UserScope().uid;
    if (updated.isShared && uid != null && sharing != null) {
      try {
        await sharing!.lists.publish(updated, uid: uid);
      } catch (e) {
        debugPrint('Widget shared list publish failed: $e');
      }
    }
  }

  Future<GroceryListEntity?> _resolveList(
    String? wanted,
    GroceryListsRepository groceries,
  ) async {
    if (wanted != null) {
      final exact = await groceries.getListById(wanted);
      if (exact != null) return exact;
    }
    final lists = await groceries.getLists()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final defaultId = HomeWidgetDefaultsStore().value.listId;
    final activeId = await activeList?.read();
    for (final id in [defaultId, activeId]) {
      final match = lists.where((l) => l.id == id).firstOrNull;
      if (match != null) return match;
    }
    if (lists.isNotEmpty) return lists.first;
    return GroceryListEntity(
      id: 'primary',
      name: t.groceryList.defaultListName,
      items: const [],
      createdAt: DateTime.now(),
    );
  }

  /// The app came to the front: whatever the widgets did meanwhile.
  void onResumed() {
    unawaited(drain());
  }
}
