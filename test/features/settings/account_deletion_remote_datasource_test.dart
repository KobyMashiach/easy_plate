import 'package:easy_plate/features/settings/data/account_deletion_remote_datasource.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('account deletion refusals', () {
    test(
      'a recent-sign-in demand is told apart from the household refusal',
      () {
        const recent =
            '{error: {code: recent_login_required, message: Sign in again}}';
        expect(
          AccountDeletionRemoteDataSource.needsRecentLogin(recent),
          isTrue,
        );
        expect(
          AccountDeletionRemoteDataSource.needsRecentLogin(
            '{"error":{"code":"recent_login_required"}}',
          ),
          isTrue,
        );
        expect(AccountDeletionRemoteDataSource.refusalIn(recent), isNull);
        const owner =
            '{error: {code: household_owner, message: household_owner}}';
        expect(
          AccountDeletionRemoteDataSource.needsRecentLogin(owner),
          isFalse,
        );
        expect(
          AccountDeletionRemoteDataSource.refusalIn(owner),
          'household_owner',
        );
        expect(AccountDeletionRemoteDataSource.needsRecentLogin(''), isFalse);
      },
    );
  });
}
