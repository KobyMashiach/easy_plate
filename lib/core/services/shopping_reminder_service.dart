import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../constants/app_enums.dart';
import '../monetization/monetization_config.dart';
import '../navigation/main_tabs.dart';
import '../utils/i18n/strings.g.dart';
import 'cook_session_service.dart';
import '../features/features_flags.dart';

/// Staggered reminders leading up to the configured shopping day (spec §6.5):
/// two days before (1), one day before (1), and the shopping day itself (2 —
/// morning and afternoon — prompting the user to finalize the menu).
class ShoppingReminderService {
  static final ShoppingReminderService _instance =
      ShoppingReminderService._internal();
  factory ShoppingReminderService() => _instance;
  ShoppingReminderService._internal();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _channelId = 'shopping_reminders';

  /// Built per schedule, not const: the channel name is what Android shows
  /// in its notification settings, and it has to follow the app's language
  /// like the reminder texts do.
  NotificationDetails get _details => NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      t.notificationSettings.reminders,
      importance: Importance.defaultImportance,
    ),
    iOS: const DarwinNotificationDetails(),
  );

  Future<void> initialize() async {
    if (_initialized) return;
    tz.initializeTimeZones();
    // The package starts on UTC and nothing told it otherwise: "18:00 the
    // day before" rang at 18:00 UTC — 21:00 in Israel in summer — and the
    // weekly repeat kept that hour. The device's zone is matched from the
    // database by its offsets across a year, which needs no extra plugin.
    final local = matchLocalLocation(
      tz.timeZoneDatabase.locations.values,
      now: DateTime.now(),
    );
    if (local != null) tz.setLocalLocation(local);
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      // A tap on a reminder lands on the grocery list, running or not. A
      // cook-mode timer carries its own payload and reopens the step.
      onDidReceiveNotificationResponse: (response) =>
          _openFor(response.payload),
    );
    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      _openFor(launch?.notificationResponse?.payload);
    }
    _initialized = true;
  }

  /// Switches to the grocery tab; if the main screen is not up yet, the
  /// tab notifier simply holds the value until it is.
  void _openGroceries() => MainTabs.index.value = MainTabs.groceries;

  void _openFor(String? payload) {
    if (!CookSessionService().handlePayload(payload)) _openGroceries();
  }

  /// The one plugin instance, shared with the cook-mode timers so a second
  /// `initialize` never overwrites the tap callback above.
  FlutterLocalNotificationsPlugin get plugin => _plugin;

  /// On sign-out: the reminders were the signed-out account's.
  Future<void> cancelAll() async {
    _lastKey = null;
    try {
      await initialize();
      await _plugin.cancelAll();
    } catch (e) {
      debugPrint('Cancelling reminders failed: $e');
    }
  }

  /// Reschedules the whole reminder set. Called on app start and whenever the
  /// shopping day changes in settings.
  /// What the last schedule was built from. Callers fire on settings
  /// changes, sign-in, plan changes and console flags, often for the same
  /// answer; only a different answer is worth the plugin round trips.
  String? _lastKey;

  /// Calls arrive close together (sign-in, then the first entitlement
  /// snapshot); run one after another so two cancel/schedule loops never
  /// interleave on the same ids.
  Future<void> _queue = Future.value();

  Future<void> scheduleForShoppingDay(
    ShoppingDay shoppingDay, {
    List<ShoppingReminderSlot> slots = ShoppingReminderSlot.defaults,
  }) {
    final next = _queue.then((_) => _scheduleIfChanged(shoppingDay, slots));
    _queue = next.then((_) {}, onError: (_) {});
    return next;
  }

  Future<void> _scheduleIfChanged(
    ShoppingDay shoppingDay,
    List<ShoppingReminderSlot> slots,
  ) async {
    // Premium gate, or the console's own switch for the reminders (and for
    // notifications as a whole): either way nothing is scheduled.
    final locked =
        MonetizationConfig.notificationsLocked ||
        !FeaturesFlags.shoppingReminder.isEnabled ||
        !FeaturesFlags.notifications.isEnabled;
    // The language is part of the key: the texts are baked into the scheduled
    // notifications, so a language switch has to write them again.
    final key =
        '$locked|$shoppingDay|$slots|${LocaleSettings.currentLocale.languageCode}';
    if (key == _lastKey) return;
    // Recorded only once the work below went through: a plugin hiccup must
    // not silence this key for the rest of the session.
    _lastKey = null;
    // Never thrown on: callers on the entitlement and console listeners do
    // not await this, and an escaped plugin error there is recorded as a
    // fatal crash. The key stays unset, so the next call tries again.
    try {
      await _schedule(shoppingDay, slots, locked);
    } catch (e) {
      debugPrint('Scheduling reminders failed: $e');
      return;
    }
    _lastKey = key;
  }

  Future<void> _schedule(
    ShoppingDay shoppingDay,
    List<ShoppingReminderSlot> slots,
    bool locked,
  ) async {
    await initialize();
    // Only this service's own slots: a blanket cancelAll would also drop
    // the cook-mode timer rings, which share the plugin.
    for (var i = 0; i < ShoppingReminderSlot.values.length; i++) {
      await _plugin.cancel(id: i);
    }
    // Reminders are Premium while the console says so; a free account's
    // slots are cleared and nothing new is set.
    if (locked) return;

    // Dart weekdays run Mon=1..Sun=7; ShoppingDay runs Sunday-first.
    final targetWeekday = shoppingDay.index == 0
        ? DateTime.sunday
        : shoppingDay.index;

    // Every slot the app knows; only the chosen ones are scheduled. The texts
    // come from the app's strings, in the language the app is in right now:
    // a reminder in a language the user never chose read as someone else's.
    final all =
        <ShoppingReminderSlot, ({int daysBefore, int hour, String body})>{
          ShoppingReminderSlot.twoDaysBefore: (
            daysBefore: 2,
            hour: 18,
            body: t.shoppingReminder.twoDaysBefore,
          ),
          ShoppingReminderSlot.dayBefore: (
            daysBefore: 1,
            hour: 18,
            body: t.shoppingReminder.dayBefore,
          ),
          ShoppingReminderSlot.sameDayMorning: (
            daysBefore: 0,
            hour: 9,
            body: t.shoppingReminder.sameDayMorning,
          ),
          ShoppingReminderSlot.sameDayAfternoon: (
            daysBefore: 0,
            hour: 16,
            body: t.shoppingReminder.sameDayAfternoon,
          ),
        };
    final schedule = [for (final slot in slots) all[slot]!];

    for (var i = 0; i < schedule.length; i++) {
      final entry = schedule[i];
      try {
        await _plugin.zonedSchedule(
          id: i,
          title: t.appName,
          body: entry.body,
          scheduledDate: _nextInstance(
            targetWeekday,
            entry.daysBefore,
            entry.hour,
          ),
          notificationDetails: _details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      } catch (e) {
        debugPrint('Failed to schedule reminder $i: $e');
      }
    }
  }

  /// The database zone that keeps this device's clock: the same UTC offset
  /// as the device's own at four points a season apart (so the same
  /// daylight-saving rule), preferring one whose abbreviation also matches
  /// ([abbreviation], the device's `timeZoneName`). Null when none does —
  /// the reminders then stay on UTC, as before.
  @visibleForTesting
  static tz.Location? matchLocalLocation(
    Iterable<tz.Location> candidates, {
    required DateTime now,
    Duration Function(DateTime instant)? offsetAt,
    String? abbreviation,
  }) {
    final localOffset =
        offsetAt ?? (instant) => instant.toLocal().timeZoneOffset;
    final name = abbreviation ?? now.toLocal().timeZoneName;
    final samples = [
      for (var quarter = 0; quarter < 4; quarter++)
        now.toUtc().add(Duration(days: 91 * quarter)),
    ];
    tz.Location? fallback;
    for (final location in candidates) {
      final fits = samples.every(
        (instant) =>
            location.timeZone(instant.millisecondsSinceEpoch).offset ==
            localOffset(instant),
      );
      if (!fits) continue;
      if (location.timeZone(now.millisecondsSinceEpoch).abbreviation == name) {
        return location;
      }
      // A region's own zone over the `Etc/` fixed offsets, which carry no
      // daylight-saving rule of their own.
      if (fallback == null || fallback.name.startsWith('Etc/')) {
        fallback = location;
      }
    }
    return fallback;
  }

  tz.TZDateTime _nextInstance(int targetWeekday, int daysBefore, int hour) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour);

    final reminderWeekday = ((targetWeekday - daysBefore - 1) % 7) + 1;
    while (scheduled.weekday != reminderWeekday || !scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
