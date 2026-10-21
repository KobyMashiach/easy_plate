import 'package:easy_plate/core/errors/app_exception.dart';
import 'package:easy_plate/features/recipe_ingestion/domain/paid_call_refusal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a blocked account is told by its type, or by the body under the '
      'generic type', () {
    expect(
      isAccountDisabled(const AppException(AppErrorType.accountDisabled)),
      isTrue,
    );
    expect(
      isAccountDisabled(
        const AppException(
          AppErrorType.unauthorized,
          data: {
            'error': {'code': 'account_disabled'},
          },
        ),
      ),
      isTrue,
    );
    // A missing key is the same type with another body.
    expect(
      isAccountDisabled(
        const AppException(
          AppErrorType.unauthorized,
          data: {
            'error': {'code': 'unauthenticated'},
          },
        ),
      ),
      isFalse,
    );
    expect(
      isAccountDisabled(const AppException(AppErrorType.unknown)),
      isFalse,
    );
    expect(isAccountDisabled(StateError('x')), isFalse);
  });

  test('quota, phone and block stand; offline and capacity pass', () {
    for (final type in [
      AppErrorType.quotaExceeded,
      AppErrorType.phoneRequired,
      AppErrorType.accountDisabled,
    ]) {
      expect(isStandingRefusal(AppException(type)), isTrue, reason: '$type');
    }
    for (final type in [
      AppErrorType.networkError,
      AppErrorType.overloaded,
      AppErrorType.unauthorized,
      AppErrorType.unknown,
    ]) {
      expect(isStandingRefusal(AppException(type)), isFalse, reason: '$type');
    }
    expect(isStandingRefusal(null), isFalse);
  });
}
