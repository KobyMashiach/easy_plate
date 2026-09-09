import 'package:easy_plate/core/monetization/trusted_clock.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() => TrustedClock().resetForTest());

  test('before any sync the device clock is used', () {
    final clock = TrustedClock();
    expect(clock.isSynced, isFalse);
    expect(clock.now().difference(DateTime.now()).abs(), lessThan(const Duration(seconds: 1)));
  });

  test('after a sync the server moment wins over the device clock', () {
    final clock = TrustedClock();
    final serverUtc = DateTime.utc(2030, 1, 1, 12, 0, 0);
    clock.adopt(serverUtc);

    expect(clock.isSynced, isTrue);
    expect(clock.now().toUtc().difference(serverUtc), lessThan(const Duration(seconds: 1)));
  });

  test('a failed sync leaves the previous anchor in place', () async {
    final clock = TrustedClock();
    final serverUtc = DateTime.utc(2030, 1, 1, 12);
    clock.adopt(serverUtc);

    await clock.sync(fetch: () async => null);

    expect(clock.now().toUtc().difference(serverUtc), lessThan(const Duration(seconds: 1)));
  });

  test('sync adopts what the fetch returns', () async {
    final clock = TrustedClock();
    await clock.sync(fetch: () async => DateTime.utc(2031, 6, 15, 8));
    expect(clock.now().toUtc().year, 2031);
  });

  test('the day key is zero-padded and in local time', () {
    expect(TrustedClock.dayKeyOf(DateTime(2026, 9, 9, 23, 59)), '2026-09-09');
    expect(TrustedClock.dayKeyOf(DateTime(2026, 12, 25)), '2026-12-25');
  });

  test('day keys compare as strings in date order', () {
    expect('2026-09-10'.compareTo('2026-09-09'), greaterThan(0));
    expect('2027-01-01'.compareTo('2026-12-31'), greaterThan(0));
  });
}
