import 'dart:async';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../errors/app_exception.dart';

/// Builds the `Authorization` header the AI proxy expects.
///
/// The proxy holds the Gemini key and decides who may spend it, so the caller's
/// Firebase ID token *is* the credential. Resolved per request rather than once:
/// a token lasts an hour, and a session outlives that.
Future<Map<String, String>> aiProxyAuthHeader() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    throw const AppException(
      AppErrorType.unauthorized,
      message: 'Sign in to use recipe analysis',
    );
  }

  // Firebase returns a cached token until it is close to expiry, so this is a
  // local read on almost every call rather than a network round trip.
  final token = await user.getIdToken();
  if (token == null || token.isEmpty) {
    throw const AppException(
      AppErrorType.unauthorized,
      message: 'Could not obtain an identity token',
    );
  }

  final appCheck = await appCheckToken();
  return {
    'Authorization': 'Bearer $token',
    'X-Firebase-AppCheck': ?appCheck,
  };
}

/// The App Check token for a paid call, or null when none could be had (not
/// activated, the attestation provider failing, offline). Cached by the SDK
/// like the ID token; bounded so a slow attestation never holds a call up.
/// The server decides what a missing token costs (`app_check_mode`).
Future<String?> appCheckToken() async {
  try {
    return await FirebaseAppCheck.instance.getToken().timeout(
      const Duration(seconds: 4),
    );
  } catch (e) {
    debugPrint('App Check token unavailable: $e');
    return null;
  }
}

/// [AuthSessionService.refreshClaims] for the app: a forced ID token
/// refresh after a server answered `account_disabled`. The console's
/// disable writes a `disabled` claim and revokes the refresh tokens, so
/// this either brings the claim into the cached token (every later call is
/// refused the same way) or fails and signs the account out — which lands
/// on the login, and from there `account_status` keeps it blocked.
Future<void> refreshIdTokenClaims() async {
  try {
    await FirebaseAuth.instance.currentUser?.getIdToken(true);
  } catch (e) {
    debugPrint('Claims refresh failed: $e');
  }
}

Future<bool>? _phoneRefresh;
DateTime? _phoneRefreshedAt;

/// [HttpCalls.refreshIdentity] for the app: when a paid endpoint answers
/// `phone_required` but the signed-in account does hold a verified phone,
/// the cached ID token predates the link — force a fresh one so the retry
/// carries the `phone_number` claim. Without a phone there is nothing to
/// refresh, so it answers false and the refusal stands.
///
/// Parallel refusals (translation sends batches side by side) share one
/// refresh, and a refresh in the last minute is reused instead of repeated
/// (the retry simply reads the token it left), so a real refusal can never
/// turn into a stream of token round trips — each request retries once.
Future<bool> refreshPhoneClaim() {
  final user = FirebaseAuth.instance.currentUser;
  final phone = user?.phoneNumber;
  if (user == null || phone == null || phone.isEmpty) {
    return Future.value(false);
  }
  final inFlight = _phoneRefresh;
  if (inFlight != null) return inFlight;
  final last = _phoneRefreshedAt;
  if (last != null &&
      DateTime.now().difference(last) < const Duration(minutes: 1)) {
    return Future.value(true);
  }
  final refresh = () async {
    try {
      await user.getIdToken(true);
      return true;
    } catch (e) {
      return false;
    } finally {
      _phoneRefreshedAt = DateTime.now();
      _phoneRefresh = null;
    }
  }();
  _phoneRefresh = refresh;
  return refresh;
}
