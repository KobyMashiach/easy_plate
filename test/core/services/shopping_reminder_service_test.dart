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
      ShoppingReminderService().scheduleForShoppingDay(ShoppingDay.monday),
      completes,
    );
  });
}
