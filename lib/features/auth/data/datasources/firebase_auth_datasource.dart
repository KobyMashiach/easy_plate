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
  Future<void> sendPasswordReset(String email);
  Future<String> startPhoneVerification(
    String phoneNumber, {
    void Function(AppUserEntity user)? autoResolved,
    void Function(Object error)? onFailed,
  });
  Future<AppUserEntity> confirmPhoneCode(String verificationId, String smsCode);
  Future<void> signOut();
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

  AppUserEntity? _map(User? user) {
    if (user == null) return null;
    return AppUserEntity(
      uid: user.uid,
      email: user.email,
      phoneNumber: user.phoneNumber,
      displayName: user.displayName,
      photoUrl: user.photoURL,
    );
  }

  /// Firebase reports every failure as a code string; mapping them here keeps
  /// the raw plugin exception out of the bloc and the UI.
  Never _rethrow(FirebaseAuthException e) {
    throw switch (e.code) {
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' ||
      'invalid-verification-code' =>
        AppException(AppErrorType.unauthorized, message: e.code),
      'network-request-failed' => const AppException(AppErrorType.networkError),
      _ => AppException(AppErrorType.unknown, message: e.message ?? e.code),
    };
  }

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
          completer.completeError(
            AppException(AppErrorType.unauthorized, message: e.message ?? e.code),
          );
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
}
