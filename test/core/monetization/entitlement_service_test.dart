import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_plate/core/monetization/entitlement_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 9, 9);

  test('no document means free', () {
    expect(EntitlementService.resolvePremium(null, now), isFalse);
    expect(EntitlementService.resolvePremium({}, now), isFalse);
  });

  test('a grant dated ahead is not premium until it starts', () {
    final data = {
      'premium': true,
      'premiumFrom': Timestamp.fromDate(DateTime(2026, 10, 1)),
      'premiumUntil': Timestamp.fromDate(DateTime(2026, 10, 8)),
    };
    expect(EntitlementService.resolvePremium(data, now), isFalse);
    expect(
      EntitlementService.resolvePremium(data, DateTime(2026, 10, 3)),
      isTrue,
    );
    expect(
      EntitlementService.resolvePremium(data, DateTime(2026, 10, 9)),
      isFalse,
    );
  });

  test('the next flip is the start, then the end, then nothing', () {
    final data = {
      'premium': true,
      'premiumFrom': Timestamp.fromDate(DateTime(2026, 10, 1)),
      'premiumUntil': Timestamp.fromDate(DateTime(2026, 10, 8)),
    };
    expect(EntitlementService.nextChange(data, now), DateTime(2026, 10, 1));
    expect(
      EntitlementService.nextChange(data, DateTime(2026, 10, 3)),
      DateTime(2026, 10, 8),
    );
    expect(EntitlementService.nextChange(data, DateTime(2026, 10, 9)), isNull);
    expect(EntitlementService.nextChange({'premium': true}, now), isNull);
  });

  test('premium: true with no expiry is premium', () {
    expect(EntitlementService.resolvePremium({'premium': true}, now), isTrue);
  });

  test('a future expiry is premium, a past one is not', () {
    expect(
      EntitlementService.resolvePremium(
        {'premium': true, 'premiumUntil': Timestamp.fromDate(DateTime(2027))},
        now,
      ),
      isTrue,
    );
    expect(
      EntitlementService.resolvePremium(
        {
          'premium': true,
          'premiumUntil': Timestamp.fromDate(DateTime(2026, 1)),
        },
        now,
      ),
      isFalse,
    );
  });

  test('a truthy-looking string is not premium', () {
    expect(
      EntitlementService.resolvePremium({'premium': 'true'}, now),
      isFalse,
    );
  });

  test('the service notifies when the flag changes and clear() drops it', () {
    final service = EntitlementService();
    var notified = 0;
    service.addListener(() => notified++);

    service.setForTest(true);
    expect(service.isPremium, isTrue);
    service.setForTest(true);
    expect(notified, 1, reason: 'no notification without a change');

    service.clear();
    expect(service.isPremium, isFalse);
    expect(notified, 2);
  });

  _storeAndServerTests();
}

void _storeAndServerTests() {
  group('two sources', () {
    late EntitlementService service;
    setUp(() {
      service = EntitlementService();
      service.clear();
    });

    test('the store SDK alone unlocks premium', () {
      expect(service.isPremium, isFalse);
      service.setFromStore(true);
      expect(service.isPremium, isTrue);
    });

    test('the store going quiet does not revoke what the server grants', () {
      service.setForTest(true);
      service.setFromStore(true);
      service.setFromStore(false);
      expect(service.isPremium, isTrue);
    });

    test('sign-out drops both', () {
      service.setForTest(true);
      service.setFromStore(true);
      service.clear();
      expect(service.isPremium, isFalse);
    });

    test('notifies once per real change', () {
      var notifications = 0;
      service.addListener(() => notifications++);
      service.setFromStore(true);
      service.setFromStore(true);
      service.setForTest(true);
      expect(service.isPremium, isTrue);
      expect(notifications, 1);
    });
  });
}
