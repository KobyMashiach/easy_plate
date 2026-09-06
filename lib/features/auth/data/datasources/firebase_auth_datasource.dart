import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/app_user_entity.dart';

abstract class AuthDataSource {
  Stream<AppUserEntity?> authStateChanges();
  AppUserEntity? get currentUser;
  Future<AppUserEntity> signInWithEmail(String email, String password);
  Future<AppUserEntity> registerWithEmail(String email, String password);
  Future<AppUserEntity> signInWithGoogle();
  Future<AppUserEntity> signInWithApple();
  Future<void> sendPasswordReset(String email);
  Future<String> startPhoneVerification(
    String phoneNumber, {
    void Function(AppUserEntity user)? autoResolved,
    void Function(Object error)? onFailed,
  });
  Future<AppUserEntity> confirmPhoneCode(String verificationId, String smsCode);
  Future<void> signOut();
  Future<void> setLanguage(String languageCode);

  Future<void> sendEmailVerification();

  /// Re-reads the account from the server and reports whether the email has
  /// been confirmed since. `emailVerified` on a cached user never changes on
  /// its own.
  Future<bool> refreshEmailVerified();

  Future<String> startPhoneLink(
    String phoneNumber, {
    void Function(Object error)? onFailed,
  });
  Future<void> linkPhone(String verificationId, String smsCode);
  Future<void> linkEmailPassword(String email, String password);
  Future<void> linkGoogle();
  Future<void> linkApple();
}

class FirebaseAuthDataSource implements AuthDataSource {
  final FirebaseAuth _auth;

  FirebaseAuthDataSource({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  /// google_sign_in 7 replaced the per-call configuration of v6 with a single
  /// initialised singleton, so the first use has to await it.
  static Future<void>? _googleInit;
  static Future<void> _ensureGoogleReady() {
    return _googleInit ??= GoogleSignIn.instance.initialize();
  }

  /// Firebase reports an identity the account does not have as an empty
  /// string on some platforms, not null. Left as-is, "no email" looked like an
  /// email to every `== null` check downstream — the profile screen showed
  /// neither a value nor the button to add one.
  @visibleForTesting
  static String? blankToNull(String? value) =>
      value == null || value.trim().isEmpty ? null : value;

  AppUserEntity? _map(User? user) {
    if (user == null) return null;
    return AppUserEntity(
      uid: user.uid,
      email: blankToNull(user.email),
      phoneNumber: blankToNull(user.phoneNumber),
      displayName: blankToNull(user.displayName),
      photoUrl: blankToNull(user.photoURL),
      emailVerified: user.emailVerified,
      providerIds: user.providerData.map((p) => p.providerId).toList(),
    );
  }

  User get _requireUser {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AppException(AppErrorType.unauthorized, message: 'no-current-user');
    }
    return user;
  }

  /// Firebase reports every failure as a code string. The code is carried
  /// through as the message — it is stable across locales and SDK versions,
  /// unlike `e.message`, so the UI can translate it instead of showing an
  /// English sentence.
  AppException _mapAuthError(FirebaseAuthException e) {
    // The human-readable text is dropped from the exception but is the only
    // place Firebase explains *why*, so it goes to the log.
    debugPrint('FirebaseAuthException ${e.code}: ${e.message}');

    return switch (e.code) {
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' ||
      'invalid-verification-code' =>
        AppException(AppErrorType.unauthorized, message: e.code),
      'network-request-failed' => const AppException(AppErrorType.networkError),
      'too-many-requests' => AppException(AppErrorType.overloaded, message: e.code),
      _ => AppException(AppErrorType.unknown, message: e.code),
    };
  }

  Never _rethrow(FirebaseAuthException e) => throw _mapAuthError(e);

  /// Localises the SMS and email templates Firebase sends on our behalf.
  /// Without it every request carries a null `X-Firebase-Locale`.
  @override
  Future<void> setLanguage(String languageCode) async =>
      _auth.setLanguageCode(languageCode);

  @override
  Stream<AppUserEntity?> authStateChanges() => _auth.authStateChanges().map(_map);

  @override
  AppUserEntity? get currentUser => _map(_auth.currentUser);

  @override
  Future<AppUserEntity> signInWithEmail(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return _map(result.user)!;
    } on FirebaseAuthException catch (e) {
      _rethrow(e);
    }
  }

  @override
  Future<AppUserEntity> registerWithEmail(String email, String password) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      return _map(result.user)!;
    } on FirebaseAuthException catch (e) {
      _rethrow(e);
    }
  }

  @override
  Future<AppUserEntity> signInWithGoogle() async {
    try {
      await _ensureGoogleReady();
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw const AppException(
          AppErrorType.unauthorized,
          message: 'Google returned no ID token',
        );
      }
      // v7 hands back only an ID token; Firebase accepts that on its own.
      final credential = GoogleAuthProvider.credential(idToken: idToken);
      final result = await _auth.signInWithCredential(credential);
      return _map(result.user)!;
    } on GoogleSignInException catch (e) {
      throw e.code == GoogleSignInExceptionCode.canceled
          ? const AppException(AppErrorType.cancelled)
          : AppException(AppErrorType.unknown, message: e.description ?? e.code.name);
    } on FirebaseAuthException catch (e) {
      _rethrow(e);
    }
  }

  /// Native on iOS, so there is no browser hop and Apple's own "Hide My Email"
  /// relay works. Firebase's own provider flow is used rather than a separate
  /// package: `signInWithProvider` drives ASAuthorization directly.
  ///
  /// Apple hands back the name **only on the very first authorization** for an
  /// app. A reinstall gets nothing, which is why the profile screen asks for a
  /// name rather than trusting what the provider supplied.
  @override
  Future<AppUserEntity> signInWithApple() async {
    try {
      final result = await _auth.signInWithProvider(AppleAuthProvider());
      return _map(result.user)!;
    } on FirebaseAuthException catch (e) {
      // A dismissed sheet surfaces as a cancel code rather than an error the
      // user should be shown.
      if (_appleCancelled(e)) throw const AppException(AppErrorType.cancelled);
      _rethrow(e);
    }
  }

  /// Apple reports a dismissed sheet through a couple of different codes
  /// depending on the OS version; none of them are a failure worth a message.
  static bool _appleCancelled(FirebaseAuthException e) =>
      e.code == 'canceled' ||
      e.code == 'user-canceled' ||
      e.code == 'web-context-canceled';

  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      _rethrow(e);
    }
  }

  @override
  Future<String> startPhoneVerification(
    String phoneNumber, {
    void Function(AppUserEntity user)? autoResolved,
    void Function(Object error)? onFailed,
  }) {
    // verifyPhoneNumber is callback-shaped and can fire more than once (auto
    // retrieval on Android), so the completer is guarded against a second
    // completion.
    final completer = Completer<String>();

    _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (credential) async {
        try {
          final result = await _auth.signInWithCredential(credential);
          final user = _map(result.user);
          if (user != null) autoResolved?.call(user);
        } catch (e) {
          debugPrint('Phone auto-verification failed: $e');
        }
      },
      verificationFailed: (e) {
        if (!completer.isCompleted) {
          completer.completeError(_mapAuthError(e));
        } else {
          onFailed?.call(e);
        }
      },
      codeSent: (verificationId, _) {
        if (!completer.isCompleted) completer.complete(verificationId);
      },
      codeAutoRetrievalTimeout: (verificationId) {
        if (!completer.isCompleted) completer.complete(verificationId);
      },
    );

    return completer.future;
  }

  @override
  Future<AppUserEntity> confirmPhoneCode(String verificationId, String smsCode) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      final result = await _auth.signInWithCredential(credential);
      return _map(result.user)!;
    } on FirebaseAuthException catch (e) {
      _rethrow(e);
    }
  }

  @override
  Future<void> signOut() async {
    // Google keeps its own session; leaving it signed in would silently reuse
    // the same account on the next sign-in instead of showing the picker.
    try {
      await _ensureGoogleReady();
      await GoogleSignIn.instance.signOut();
    } catch (e) {
      debugPrint('Google sign-out skipped: $e');
    }
    await _auth.signOut();
  }

  @override
  Future<void> sendEmailVerification() async {
    try {
      await _requireUser.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      _rethrow(e);
    }
  }

  @override
  Future<bool> refreshEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.reload();
    // reload() mutates the cached instance rather than returning a new one, so
    // the flag has to be read off currentUser again.
    return _auth.currentUser?.emailVerified ?? false;
  }

  /// Same SMS round trip as signing in, but the resulting credential is
  /// attached to the account that is already signed in instead of starting a
  /// new session.
  @override
  Future<String> startPhoneLink(
    String phoneNumber, {
    void Function(Object error)? onFailed,
  }) {
    final completer = Completer<String>();

    _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      // Deliberately empty: auto-retrieval would sign the credential in, and
      // linking has to stay an explicit step against the current user.
      verificationCompleted: (_) {},
      verificationFailed: (e) {
        if (!completer.isCompleted) {
          completer.completeError(_mapAuthError(e));
        } else {
          onFailed?.call(e);
        }
      },
      codeSent: (verificationId, _) {
        if (!completer.isCompleted) completer.complete(verificationId);
      },
      codeAutoRetrievalTimeout: (verificationId) {
        if (!completer.isCompleted) completer.complete(verificationId);
      },
    );

    return completer.future;
  }

  @override
  Future<void> linkPhone(String verificationId, String smsCode) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      await _requireUser.linkWithCredential(credential);
      // The linked number only appears on the cached user after a reload.
      await _auth.currentUser?.reload();
    } on FirebaseAuthException catch (e) {
      _rethrow(e);
    }
  }

  /// Attaches a Google account, so signing in with Google later resolves to
  /// this same user. Firebase also adopts the Google address as the account's
  /// email — already verified — when it has none, which is the quickest way
  /// for a phone-only account to end up with a confirmed email.
  @override
  Future<void> linkGoogle() async {
    try {
      await _ensureGoogleReady();
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw const AppException(
          AppErrorType.unauthorized,
          message: 'Google returned no ID token',
        );
      }
      await _requireUser.linkWithCredential(GoogleAuthProvider.credential(idToken: idToken));
      await _auth.currentUser?.reload();
    } on GoogleSignInException catch (e) {
      throw e.code == GoogleSignInExceptionCode.canceled
          ? const AppException(AppErrorType.cancelled)
          : AppException(AppErrorType.unknown, message: e.description ?? e.code.name);
    } on FirebaseAuthException catch (e) {
      _rethrow(e);
    }
  }

  /// Attaches an Apple account to the signed-in user, so signing in with Apple
  /// later resolves here rather than opening a second account.
  @override
  Future<void> linkApple() async {
    try {
      await _requireUser.linkWithProvider(AppleAuthProvider());
      await _auth.currentUser?.reload();
    } on FirebaseAuthException catch (e) {
      if (_appleCancelled(e)) throw const AppException(AppErrorType.cancelled);
      _rethrow(e);
    }
  }

  @override
  Future<void> linkEmailPassword(String email, String password) async {
    try {
      final credential = EmailAuthProvider.credential(email: email, password: password);
      await _requireUser.linkWithCredential(credential);
      await _auth.currentUser?.reload();
      await _auth.currentUser?.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      _rethrow(e);
    }
  }
}
