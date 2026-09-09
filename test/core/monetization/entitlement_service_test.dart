import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_plate/core/monetization/entitlement_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 9, 9);

  test('no document means free', () {
    expect(EntitlementService.resolvePremium(null, now), isFalse);
    expect(EntitlementService.resolvePremium({}, now), isFalse);
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
        {'premium': true, 'premiumUntil': Timestamp.fromDate(DateTime(2026, 1))},
        now,
      ),
      isFalse,
    );
  });

  test('a truthy-looking string is not premium', () {
    expect(EntitlementService.resolvePremium({'premium': 'true'}, now), isFalse);
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
}
