import 'package:easy_plate/core/utils/i18n/strings.g.dart';
import 'package:easy_plate/features/auth/data/datasources/firebase_auth_datasource.dart';
import 'package:easy_plate/features/auth/presentation/widgets/auth_error_text.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'a project/region config failure is not reported as bad credentials',
    () {
      // 17006 "SMS unable to be sent until this region enabled" surfaces as
      // operation-not-allowed. Calling that "wrong details" sends the user off
      // retyping a phone number that was never the problem.
      expect(
        authErrorMessage('operation-not-allowed'),
        t.auth.errorOperationNotAllowed,
      );
      expect(
        authErrorMessage('operation-not-allowed'),
        isNot(t.auth.errorUnauthorized),
      );
    },
  );

  test('credential failures still read as bad credentials', () {
    for (final code in [
      'invalid-credential',
      'wrong-password',
      'user-not-found',
      'invalid-verification-code',
    ]) {
      expect(authErrorMessage(code), t.auth.errorUnauthorized, reason: code);
    }
  });

  test('rate limiting gets its own advice, not a generic failure', () {
    expect(authErrorMessage('too-many-requests'), t.auth.errorTooManyRequests);
    expect(authErrorMessage('too-many-requests'), isNot(t.auth.errorUnknown));
  });

  test(
    'AppErrorType names still resolve, for failures that never reached Firebase',
    () {
      expect(authErrorMessage('networkError'), t.auth.errorNetwork);
      expect(authErrorMessage('unauthorized'), t.auth.errorUnauthorized);
      expect(authErrorMessage('overloaded'), t.auth.errorTooManyRequests);
    },
  );

  test('an unrecognised code falls back instead of throwing', () {
    expect(
      authErrorMessage('some-brand-new-code'),
      '${t.auth.errorUnknown} (some-brand-new-code)',
    );
    expect(authErrorMessage('unknown'), t.auth.errorUnknown);
  });

  test('an identity that belongs to another account says so', () {
    // Both used to fall through to the generic failure, which left the user
    // with no idea why signing in had stopped working.
    expect(
      authErrorMessage('account-exists-with-different-credential'),
      isNot(t.auth.errorUnknown),
    );
    expect(
      authErrorMessage('credential-already-in-use'),
      isNot(t.auth.errorUnknown),
    );
  });

  test('the native Firebase number travels with internal-error', () {
    expect(
      FirebaseAuthDataSource.withNativeCode(
        'internal-error',
        'An internal error has occurred. [ Error code:39 ]',
      ),
      'internal-error:39',
    );
    expect(
      FirebaseAuthDataSource.withNativeCode('quota-exceeded', null),
      'quota-exceeded',
    );
  });

  test('every app-verification failure gets the reCAPTCHA retry', () {
    for (final code in [
      'unknown',
      'internal-error',
      'missing-client-identifier',
      'invalid-app-credential',
      'app-not-authorized',
    ]) {
      expect(
        FirebaseAuthDataSource.isAppVerificationFailure(code),
        isTrue,
        reason: code,
      );
    }
    expect(
      FirebaseAuthDataSource.isAppVerificationFailure('invalid-phone-number'),
      isFalse,
    );
    // Code 39 is the server refusing the number; reCAPTCHA cannot lift it
    // (a user passed reCAPTCHA and still got it), so it is never retried.
    expect(
      FirebaseAuthDataSource.isAppVerificationFailure(
        'unknown',
        'An internal error has occurred. [ Error code:39 ]',
      ),
      isFalse,
    );
    expect(
      FirebaseAuthDataSource.isSmsQuotaBlock(
        'An internal error has occurred. [ Error code:39 ]',
      ),
      isTrue,
    );
    expect(
      FirebaseAuthDataSource.isSmsQuotaBlock('[ Error code:17 ]'),
      isFalse,
    );
  });
}
