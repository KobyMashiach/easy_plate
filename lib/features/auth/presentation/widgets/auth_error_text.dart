import '../../../../core/utils/i18n/strings.g.dart';

/// Turns whatever the bloc carried across into something a person can read.
///
/// The key is either a Firebase Auth code (`operation-not-allowed`) or, when
/// the failure never reached Firebase, an [AppErrorType] name (`networkError`).
/// Both are matched here so the screen never has to tell them apart.
String authErrorMessage(String error) => switch (error) {
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' ||
      'invalid-verification-code' ||
      'unauthorized' =>
        t.auth.errorUnauthorized,
      'network-request-failed' || 'networkError' => t.auth.errorNetwork,
      // Raised when the provider is off for the project, and — for phone — when
      // the caller's region is not on the SMS allowlist.
      'operation-not-allowed' => t.auth.errorOperationNotAllowed,
      'too-many-requests' || 'overloaded' => t.auth.errorTooManyRequests,
      'invalid-phone-number' => t.auth.errorInvalidPhone,
      'email-already-in-use' => t.auth.errorEmailInUse,
      // Both mean "this identity belongs to a different account". They used to
      // fall through to the generic failure, which told the user nothing about
      // why signing in had stopped working.
      'account-exists-with-different-credential' =>
        t.auth.errorAccountExistsDifferentCredential,
      'credential-already-in-use' => t.auth.errorCredentialInUse,
      _ => t.auth.errorUnknown,
    };
