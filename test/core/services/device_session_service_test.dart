import 'package:easy_plate/core/services/device_session_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 10, 9, 12);
  final later = now.add(const Duration(days: 20));

  test('a document naming this device, still in date, keeps the session', () {
    expect(
      DeviceSessionService.evaluate(
        exists: true,
        deviceId: 'me',
        expiresAt: later,
        mine: 'me',
        now: now,
        seenBefore: true,
      ),
      isNull,
    );
  });

  test('a document naming another device ends it as a takeover', () {
    expect(
      DeviceSessionService.evaluate(
        exists: true,
        deviceId: 'them',
        expiresAt: later,
        mine: 'me',
        now: now,
        seenBefore: true,
      ),
      SessionEnd.otherDevice,
    );
  });

  test(
    'a document past its date, or one that disappears, ends it as expired',
    () {
      expect(
        DeviceSessionService.evaluate(
          exists: true,
          deviceId: 'me',
          expiresAt: now.subtract(const Duration(minutes: 1)),
          mine: 'me',
          now: now,
          seenBefore: true,
        ),
        SessionEnd.expired,
      );
      expect(
        DeviceSessionService.evaluate(
          exists: false,
          deviceId: null,
          expiresAt: null,
          mine: 'me',
          now: now,
          seenBefore: true,
        ),
        SessionEnd.expired,
      );
    },
  );

  test(
    'a missing document right after the claim is the write still landing',
    () {
      expect(
        DeviceSessionService.evaluate(
          exists: false,
          deviceId: null,
          expiresAt: null,
          mine: 'me',
          now: now,
          seenBefore: false,
        ),
        isNull,
      );
    },
  );

  test('no expiry date means a session that never runs out', () {
    expect(
      DeviceSessionService.evaluate(
        exists: true,
        deviceId: 'me',
        expiresAt: null,
        mine: 'me',
        now: now.add(const Duration(days: 400)),
        seenBefore: true,
      ),
      isNull,
    );
  });
}
