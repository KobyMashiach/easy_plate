import 'package:easy_plate/core/services/account_deletion_guard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(AccountDeletionGuard.resetForTest);

  test(
    'holds the account while the deletion runs and after it succeeds',
    () async {
      var during = false;
      final result = await AccountDeletionGuard.guard(() async {
        during = AccountDeletionGuard.blocks('u1');
        return 7;
      }, uid: 'u1');
      expect(result, 7);
      expect(during, isTrue);
      expect(AccountDeletionGuard.blocks('u1'), isTrue);
      // The next account on this device is never held back.
      expect(AccountDeletionGuard.blocks('u2'), isFalse);
    },
  );

  test('a failed deletion lifts the hold and rethrows', () async {
    await expectLater(
      AccountDeletionGuard.guard<void>(
        () async => throw StateError('household owner'),
        uid: 'u1',
      ),
      throwsStateError,
    );
    expect(AccountDeletionGuard.blocks('u1'), isFalse);
    expect(AccountDeletionGuard.deleting, isNull);
  });
}
