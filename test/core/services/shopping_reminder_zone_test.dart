import 'package:easy_plate/core/services/shopping_reminder_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// The reminders are scheduled in `tz.local`, which the package leaves on
/// UTC until told otherwise: "18:00" rang at 18:00 UTC. The device's zone is
/// matched from the database by its offsets across a year.
void main() {
  setUpAll(tz.initializeTimeZones);

  Iterable<tz.Location> candidates() => tz.timeZoneDatabase.locations.values;
  final now = DateTime.utc(2026, 10, 18, 9);

  Duration Function(DateTime) offsetsOf(String name) {
    final zone = tz.getLocation(name);
    return (instant) => zone.timeZone(instant.millisecondsSinceEpoch).offset;
  }

  test('an Israeli phone gets a zone with Israel\'s daylight-saving rule', () {
    final jerusalem = tz.getLocation('Asia/Jerusalem');
    final match = ShoppingReminderService.matchLocalLocation(
      candidates(),
      now: now,
      offsetAt: offsetsOf('Asia/Jerusalem'),
      abbreviation: jerusalem.timeZone(now.millisecondsSinceEpoch).abbreviation,
    );

    expect(match, isNotNull);
    // Whichever alias it is, it keeps the same clock all year.
    for (var day = 0; day < 365; day += 7) {
      final instant = now.add(Duration(days: day)).millisecondsSinceEpoch;
      expect(
        match!.timeZone(instant).offset,
        jerusalem.timeZone(instant).offset,
      );
    }
    // 18:00 there is 18:00 on the phone, not 18:00 UTC.
    final local = tz.TZDateTime(match!, 2026, 10, 19, 18);
    expect(local.toUtc().hour, 15);
  });

  test('a New York phone does not land on a zone without its DST', () {
    final match = ShoppingReminderService.matchLocalLocation(
      candidates(),
      now: now,
      offsetAt: offsetsOf('America/New_York'),
      abbreviation: 'EDT',
    );

    expect(match, isNotNull);
    final winter = DateTime.utc(2027, 1, 15).millisecondsSinceEpoch;
    expect(match!.timeZone(winter).offset, const Duration(hours: -5));
  });

  test('an offset no zone keeps leaves the reminders on UTC', () {
    expect(
      ShoppingReminderService.matchLocalLocation(
        candidates(),
        now: now,
        offsetAt: (_) => const Duration(minutes: 17),
        abbreviation: 'XYZ',
      ),
      isNull,
    );
  });
}
