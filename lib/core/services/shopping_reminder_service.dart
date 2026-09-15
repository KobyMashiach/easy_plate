import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../constants/app_enums.dart';
import '../navigation/main_tabs.dart';

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
  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      'תזכורות קניות',
      importance: Importance.defaultImportance,
    ),
    iOS: DarwinNotificationDetails(),
  );

  Future<void> initialize() async {
    if (_initialized) return;
    tz.initializeTimeZones();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      // A tap on a reminder lands on the grocery list, running or not.
      onDidReceiveNotificationResponse: (_) => _openGroceries(),
    );
    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) _openGroceries();
    _initialized = true;
  }

  /// Switches to the grocery tab; if the main screen is not up yet, the
  /// tab notifier simply holds the value until it is.
  void _openGroceries() => MainTabs.index.value = MainTabs.groceries;

  /// Reschedules the whole reminder set. Called on app start and whenever the
  /// shopping day changes in settings.
  Future<void> scheduleForShoppingDay(
    ShoppingDay shoppingDay, {
    List<ShoppingReminderSlot> slots = ShoppingReminderSlot.defaults,
  }) async {
    await initialize();
    await _plugin.cancelAll();

    // Dart weekdays run Mon=1..Sun=7; ShoppingDay runs Sunday-first.
    final targetWeekday = shoppingDay.index == 0
        ? DateTime.sunday
        : shoppingDay.index;

    // Every slot the app knows; only the chosen ones are scheduled.
    const all =
        <ShoppingReminderSlot, ({int daysBefore, int hour, String body})>{
          ShoppingReminderSlot.twoDaysBefore: (
            daysBefore: 2,
            hour: 18,
            body: 'יום הקניות מתקרב — כדאי להתחיל לתכנן את התפריט',
          ),
          ShoppingReminderSlot.dayBefore: (
            daysBefore: 1,
            hour: 18,
            body: 'מחר יום הקניות — בדקו שהתפריט שלכם מעודכן',
          ),
          ShoppingReminderSlot.sameDayMorning: (
            daysBefore: 0,
            hour: 9,
            body: 'היום יום הקניות — סיימו את התפריט כדי לקבל רשימה מדויקת',
          ),
          ShoppingReminderSlot.sameDayAfternoon: (
            daysBefore: 0,
            hour: 16,
            body: 'תזכורת אחרונה לפני הקניות — רשימת הקניות מחכה לכם',
          ),
        };
    final schedule = [for (final slot in slots) all[slot]!];

    for (var i = 0; i < schedule.length; i++) {
      final entry = schedule[i];
      try {
        await _plugin.zonedSchedule(
          id: i,
          title: 'EasyPlate',
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
