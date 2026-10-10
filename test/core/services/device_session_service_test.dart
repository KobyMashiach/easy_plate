import 'package:cloud_firestore/cloud_firestore.dart';
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

  group('release requests', () {
    final now = DateTime.now();
    Map<String, dynamic> doc({
      String holder = 'A',
      String from = 'B',
      DateTime? at,
      bool declined = false,
    }) => {
      'deviceId': holder,
      'releaseRequest': {
        'deviceId': from,
        'platform': 'android',
        'at': Timestamp.fromDate(at ?? now),
        'declinedAt': declined ? Timestamp.fromDate(now) : null,
      },
    };

    test('the holder sees a fresh request from another device once', () {
      final request = DeviceSessionService.pendingRequest(
        doc(),
        mine: 'A',
        handled: null,
      );
      expect(request?.platform, 'android');
      expect(
        DeviceSessionService.pendingRequest(doc(), mine: 'A', handled: now),
        isNull,
      );
    });

    test('not on another device, not declined, not stale, not its own', () {
      expect(
        DeviceSessionService.pendingRequest(doc(), mine: 'B', handled: null),
        isNull,
      );
      expect(
        DeviceSessionService.pendingRequest(
          doc(declined: true),
          mine: 'A',
          handled: null,
        ),
        isNull,
      );
      expect(
        DeviceSessionService.pendingRequest(
          doc(at: now.subtract(const Duration(hours: 1))),
          mine: 'A',
          handled: null,
        ),
        isNull,
      );
      expect(
        DeviceSessionService.pendingRequest(
          doc(from: 'A'),
          mine: 'A',
          handled: null,
        ),
        isNull,
      );
    });
  });
}
