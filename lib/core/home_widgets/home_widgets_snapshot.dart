import 'dart:convert';

import '../../features/grocery_list/domain/entities/grocery_list_entity.dart';
import '../../features/meal_planner/domain/entities/meal_plan_entity.dart';
import '../constants/app_enums.dart';
import '../features/features_flags.dart';
import '../utils/amount_format.dart';
import '../utils/i18n/strings.g.dart';
import '../widgets/measurement_unit_label.dart';

/// What the home-screen widgets draw, as one JSON document the app writes
/// to the platform's shared store (SharedPreferences on Android, the app
/// group's UserDefaults on iOS) and the native widgets read back.
///
/// The widgets run without the app — a Dart isolate cannot be started
/// from a widget without opening the account's Hive boxes a second time —
/// so everything they show has to be in here already, in the app's own
/// language: the lists with every line, every plan with all seven days
/// (the widget picks today itself, so midnight needs no app), and the
/// labels. The contract is versioned by [version]; `WidgetSnapshot.kt`
/// and `WidgetSnapshot.swift` read exactly this shape.
class HomeWidgetsSnapshot {
  static const version = 1;

  final bool signedIn;
  final FeatureAccess access;

  /// Shefi's own gate (`ff_assistant`, Premium-only in the console): the
  /// Shefi widget says "Premium only" to a free account instead of a door
  /// that leads to the paywall.
  final FeatureAccess assistantAccess;
  final String language;
  final bool rtl;

  /// Whether the app itself is in its dark look right now, for widgets set
  /// to follow the app.
  final bool dark;
  final HomeWidgetDefaults defaults;
  final List<GroceryListEntity> lists;
  final List<MealPlanEntity> plans;

  /// Recipe titles by id, for plan items that point at a recipe.
  final Map<String, String> recipeTitles;
  final DateTime now;

  const HomeWidgetsSnapshot({
    required this.signedIn,
    required this.access,
    this.assistantAccess = FeatureAccess.enabled,
    required this.language,
    required this.rtl,
    required this.dark,
    required this.defaults,
    required this.lists,
    required this.plans,
    required this.recipeTitles,
    required this.now,
  });

  /// A signed-out snapshot: nothing of the account, only the words the
  /// widget needs to say "sign in".
  factory HomeWidgetsSnapshot.signedOut({
    required String language,
    required bool rtl,
    required bool dark,
    DateTime? now,
  }) => HomeWidgetsSnapshot(
    signedIn: false,
    access: FeatureAccess.enabled,
    language: language,
    rtl: rtl,
    dark: dark,
    defaults: const HomeWidgetDefaults(),
    lists: const [],
    plans: const [],
    recipeTitles: const {},
    now: now ?? DateTime.now(),
  );

  Map<String, Object?> toJson() => {
    'v': version,
    'at': now.millisecondsSinceEpoch,
    'signedIn': signedIn,
    'access': access.name,
    'assistantAccess': assistantAccess.name,
    'lang': language,
    'rtl': rtl,
    'dark': dark,
    'defaults': defaults.toJson(),
    's': strings(),
    'weekdays': [
      t.weekday.sunday,
      t.weekday.monday,
      t.weekday.tuesday,
      t.weekday.wednesday,
      t.weekday.thursday,
      t.weekday.friday,
      t.weekday.saturday,
    ],
    'prompts': [
      t.homeWidgets.prompt1,
      t.homeWidgets.prompt2,
      t.homeWidgets.prompt3,
    ],
    'lists': [for (final list in lists) _list(list)],
    'plans': [for (final plan in plans) _plan(plan)],
  };

  String encode() => jsonEncode(toJson());

  /// Every label the native side draws, in the app's language. The
  /// widgets never see the device locale; they say what the app says.
  static Map<String, String> strings() => {
    'appName': t.appName,
    'askShefi': t.homeWidgets.askShefi,
    'tapToAsk': t.homeWidgets.tapToAsk,
    'speak': t.homeWidgets.speak,
    'quickAdd': t.homeWidgets.quickAdd,
    'addItem': t.homeWidgets.addItem,
    'itemHint': t.homeWidgets.itemHint,
    'add': t.homeWidgets.add,
    'cancel': t.common.cancel,
    'save': t.common.save,
    'todayMenu': t.homeWidgets.todayMenu,
    'today': t.homeWidgets.today,
    'noMeals': t.homeWidgets.noMeals,
    'noPlan': t.homeWidgets.noPlan,
    'noLists': t.homeWidgets.noLists,
    'emptyList': t.homeWidgets.emptyList,
    'allDone': t.homeWidgets.allDone,
    'remaining': t.homeWidgets.remainingNative,
    'signIn': t.homeWidgets.signIn,
    'openApp': t.homeWidgets.openApp,
    'comingSoon': t.feature.comingSoonMessage,
    'premiumOnly': t.feature.premiumOnlyMessage,
    'unavailable': t.feature.unavailable,
    'showChecked': t.homeWidgets.showChecked,
    'listLabel': t.homeWidgets.defaultList,
    'planLabel': t.homeWidgets.defaultPlan,
    'appearance': t.settings.appearance,
    'followApp': t.homeWidgets.followApp,
    'system': t.settings.themeSystem,
    'light': t.settings.themeLight,
    'dark': t.settings.themeDark,
    'voiceOpen': t.homeWidgets.voiceOpen,
    'pending': t.homeWidgets.pendingSync,
    'configTitle': t.homeWidgets.configTitle,
    'groceryList': t.groceryList.title,
    'mealPlan': t.mealPlanner.title,
  };

  static Map<String, Object?> _list(GroceryListEntity list) => {
    'id': list.id,
    'name': list.name,
    'total': list.items.length,
    'checked': list.checkedCount,
    'items': [
      for (final item in list.items)
        {
          'id': item.id,
          'name': item.name,
          'qty': quantityLabel(item.totalAmount, item.unit),
          'checked': item.isChecked,
        },
    ],
  };

  /// "2 kg", or "" when nothing meaningful is known.
  static String quantityLabel(double amount, MeasurementUnit unit) {
    final unitLabel = measurementUnitLabel(unit);
    if (amount <= 0) return unitLabel;
    final number = formatAmount(amount);
    if (unitLabel.isEmpty) return number;
    return '$number $unitLabel';
  }

  Map<String, Object?> _plan(MealPlanEntity plan) => {
    'id': plan.id,
    'name': plan.name,
    'days': [
      for (var weekday = 0; weekday < 7; weekday++)
        [
          for (final meal in plan.mealsForWeekday(weekday))
            {
              'id': meal.id,
              'name': meal.name,
              'items': [
                for (final item in meal.items)
                  {
                    'id': item.id,
                    'label': item.recipeId != null
                        ? (recipeTitles[item.recipeId] ?? item.displayLabel)
                        : item.displayLabel,
                    'recipeId': ?item.recipeId,
                  },
              ],
            },
        ],
    ],
  };

  /// Sunday is 0, as in [ShoppingDay] and the plan's `weekday`.
  static int weekdayIndex(DateTime date) => date.weekday % 7;
}

/// What a widget shows before it is configured, chosen in the app's own
/// widgets screen. Device-wide, like the theme: widgets belong to the
/// phone, not to the account.
class HomeWidgetDefaults {
  /// The grocery list new list widgets open on; null is the open list.
  final String? listId;

  /// The plan new menu widgets show; null is the first plan.
  final String? planId;

  /// Whether the Shefi button opens the copilot already listening.
  final bool voice;

  /// `app` follows the app's theme; the rest are the widget's own.
  final HomeWidgetAppearance appearance;

  const HomeWidgetDefaults({
    this.listId,
    this.planId,
    this.voice = false,
    this.appearance = HomeWidgetAppearance.app,
  });

  HomeWidgetDefaults copyWith({
    String? listId,
    bool clearListId = false,
    String? planId,
    bool clearPlanId = false,
    bool? voice,
    HomeWidgetAppearance? appearance,
  }) => HomeWidgetDefaults(
    listId: clearListId ? null : (listId ?? this.listId),
    planId: clearPlanId ? null : (planId ?? this.planId),
    voice: voice ?? this.voice,
    appearance: appearance ?? this.appearance,
  );

  Map<String, Object?> toJson() => {
    'listId': listId,
    'planId': planId,
    'voice': voice,
    'appearance': appearance.name,
  };

  factory HomeWidgetDefaults.fromJson(Map<String, Object?> json) =>
      HomeWidgetDefaults(
        listId: json['listId'] as String?,
        planId: json['planId'] as String?,
        voice: json['voice'] == true,
        appearance: HomeWidgetAppearance.values
                .where((a) => a.name == json['appearance'])
                .firstOrNull ??
            HomeWidgetAppearance.app,
      );
}

enum HomeWidgetAppearance { app, system, light, dark }
