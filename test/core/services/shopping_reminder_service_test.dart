import 'package:easy_plate/core/constants/app_enums.dart';
import 'package:easy_plate/core/services/shopping_reminder_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a plugin that throws never escapes a reschedule', () async {
    // The reminders are rescheduled from listeners that do not await; a
    // thrown plugin error there would be recorded as a fatal crash.
    const channel = MethodChannel('dexterous.com/flutter/local_notifications');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          channel,
          (call) async => throw PlatformException(code: 'boom'),
        );
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );

    await expectLater(
      ShoppingReminderService().scheduleForShoppingDays(const [
        ShoppingDay.monday,
      ]),
      completes,
    );
  });

  test('every shopping day gets its own reminders', () {
    final times = ShoppingReminderService.reminderTimes(
      const [ShoppingDay.sunday, ShoppingDay.wednesday],
      const [
        ShoppingReminderSlot.dayBefore,
        ShoppingReminderSlot.sameDayMorning,
      ],
    );
    expect(
      [for (final r in times) (r.weekday, r.hour)],
      [
        (DateTime.tuesday, 18),
        (DateTime.wednesday, 9),
        (DateTime.saturday, 18),
        (DateTime.sunday, 9),
      ],
    );
  });

  test('two reminders on the same evening ring once, for the nearer day', () {
    // Two days before Monday is the day before Sunday: Saturday 18:00.
    final times = ShoppingReminderService.reminderTimes(
      const [ShoppingDay.sunday, ShoppingDay.monday],
      const [
        ShoppingReminderSlot.twoDaysBefore,
        ShoppingReminderSlot.dayBefore,
      ],
    );
    final saturday = times.where(
      (r) => r.weekday == DateTime.saturday && r.hour == 18,
    );
    expect(saturday.single.slot, ShoppingReminderSlot.dayBefore);
    expect(times.length, 3);
  });
}
