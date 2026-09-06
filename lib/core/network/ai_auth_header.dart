import 'package:firebase_auth/firebase_auth.dart';

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

  return {'Authorization': 'Bearer $token'};
}
