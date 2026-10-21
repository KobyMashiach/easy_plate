import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_plate/features/admin_billing/data/datasources/admin_billing_remote_datasource.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 10, 18, 12);

  test('an owner-written profile of the wrong types costs only its values', () {
    final account = AdminBillingFirestoreDataSource.toAccount(
      'u1',
      {
        'fullName': 5,
        'email': ['x'],
        'phoneNumber': true,
        'platform': 1,
        'appVersion': {'a': 1},
        'lastSeenAt': 'yesterday',
        'createdAt': 12,
        'pushToken': 7,
      },
      null,
      const [],
      null,
      now,
    );
    expect(account.name, 'u1');
    expect(account.email, isNull);
    expect(account.phone, isNull);
    expect(account.platform, '');
    expect(account.lastSeenAt, isNull);
    expect(account.hasPushToken, isFalse);
  });

  test('a grant dated ahead is pending, not Premium', () {
    final account = AdminBillingFirestoreDataSource.toAccount(
      'u1',
      const {'fullName': 'Ann'},
      {
        'premium': true,
        'premiumFrom': Timestamp.fromDate(now.add(const Duration(days: 2))),
      },
      const [],
      null,
      now,
    );
    expect(account.premium, isFalse);
    expect(account.grantPending, isTrue);
  });
}
