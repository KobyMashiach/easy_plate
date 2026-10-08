import 'package:easy_plate/core/services/presence_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 10, 9, 12);

  test('a fresh beat with the flag set is online', () {
    expect(
      PresenceService.isOnline(
        online: true,
        lastSeenAt: now.subtract(const Duration(seconds: 50)),
        now: now,
        heartbeatSeconds: 60,
      ),
      isTrue,
    );
  });

  test('one missed beat is forgiven, two are not', () {
    expect(
      PresenceService.isOnline(
        online: true,
        lastSeenAt: now.subtract(const Duration(seconds: 140)),
        now: now,
        heartbeatSeconds: 60,
      ),
      isTrue,
    );
    expect(
      PresenceService.isOnline(
        online: true,
        lastSeenAt: now.subtract(const Duration(seconds: 151)),
        now: now,
        heartbeatSeconds: 60,
      ),
      isFalse,
    );
  });

  test('a backgrounded app, a missing stamp, or a switched-off report are offline', () {
    expect(
      PresenceService.isOnline(
        online: false,
        lastSeenAt: now,
        now: now,
        heartbeatSeconds: 60,
      ),
      isFalse,
    );
    expect(
      PresenceService.isOnline(
        online: true,
        lastSeenAt: null,
        now: now,
        heartbeatSeconds: 60,
      ),
      isFalse,
    );
    expect(
      PresenceService.isOnline(
        online: true,
        lastSeenAt: now,
        now: now,
        heartbeatSeconds: 0,
      ),
      isFalse,
    );
  });

  test('the window follows the interval', () {
    expect(PresenceService.onlineWindow(60), const Duration(seconds: 150));
    expect(PresenceService.onlineWindow(120), const Duration(seconds: 270));
  });

  test('start and stop keep the uid, and stop without a database is harmless', () async {
    final service = PresenceService()..resetForTest();
    service.configure(intervalSeconds: 0);
    service.start('u1');
    expect(service.uid, 'u1');
    await service.stop();
    expect(service.uid, isNull);
    service.resetForTest();
  });
}
