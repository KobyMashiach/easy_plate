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

  group('remembered verdict', () {
    late EntitlementService service;
    setUp(() {
      service = EntitlementService();
      service.clear();
    });

    test('nothing remembered: a gated route has to wait for the document', () {
      expect(service.hasRemembered, isFalse);
      expect(service.resolved, isFalse);
    });

    test('a remembered premium reads as premium until the document lands', () {
      service.rememberForTest(true);
      expect(service.hasRemembered, isTrue);
      expect(service.isPremium, isTrue);
      // The document says otherwise: it wins once read.
      service.setForTest(false);
      expect(service.isPremium, isTrue, reason: 'not resolved yet');
    });

    test('a remembered free is remembered too, and is not premium', () {
      service.rememberForTest(false);
      expect(service.hasRemembered, isTrue);
      expect(service.isPremium, isFalse);
    });

    test('whenResolved gives up after two seconds offline, not four', () async {
      final started = DateTime.now();
      await service.whenResolved();
      final waited = DateTime.now().difference(started);
      expect(waited, greaterThanOrEqualTo(const Duration(seconds: 2)));
      expect(waited, lessThan(const Duration(seconds: 4)));
    });

    test('clear forgets the remembered verdict with the rest', () {
      service.rememberForTest(true);
      service.clear();
      expect(service.hasRemembered, isFalse);
    });
  });
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

  group('fromWeb', () {
    late EntitlementService service;
    setUp(() {
      service = EntitlementService();
      service.clear();
    });

    test(
      'PayPlus and Paddle through RevenueCat are web plans; a store one is not',
      () {
        service.documentForTest({'premium': true, 'source': 'payplus'});
        expect(service.fromWeb, isTrue);
        service.documentForTest({
          'premium': true,
          'source': 'revenuecat',
          'store': 'PADDLE',
        });
        expect(service.fromWeb, isTrue);
        service.documentForTest({
          'premium': true,
          'source': 'revenuecat',
          'store': 'APP_STORE',
        });
        expect(service.fromWeb, isFalse);
        service.documentForTest({'premium': true, 'source': 'household'});
        expect(service.fromWeb, isFalse);
      },
    );
  });
}
