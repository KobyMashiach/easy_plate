import 'package:flutter/foundation.dart';

import '../hive/user_scope.dart';

/// Process-wide "this account is being deleted".
///
/// The server's deletion takes up to a few minutes, and anything the app
/// writes beneath `users/{uid}` meanwhile — a push token arriving late, the
/// device stamp, a mirror's push-back on resume, a translation filed in the
/// background — either recreates the account document the server just
/// removed or leaves records under an account that no longer exists. Every
/// such writer in core asks [blocks] first and stands down.
///
/// Keyed by uid, so a later account on the same device is never held back.
/// A deletion that succeeded stays marked for the rest of the process (the
/// account is gone; nothing should ever write for it again); one that failed
/// is cleared by [guard].
abstract final class AccountDeletionGuard {
  static String? _deleting;

  /// The account being deleted, or null.
  static String? get deleting => _deleting;

  /// Whether writes for [uid] (the scoped account when omitted) must not
  /// happen.
  static bool blocks([String? uid]) {
    final deleting = _deleting;
    if (deleting == null) return false;
    return (uid ?? UserScope().uid) == deleting;
  }

  /// Runs [deletion] for the signed-in account with every core writer for it
  /// stood down. A failure (the server refused, the network dropped) lifts
  /// the hold again and rethrows; success keeps it.
  ///
  /// The settings page wraps its server call in this:
  /// `AccountDeletionGuard.guard(() => AccountDeletionRemoteDataSource().deleteMyAccount())`.
  static Future<T> guard<T>(
    Future<T> Function() deletion, {
    String? uid,
  }) async {
    final target = uid ?? UserScope().uid;
    if (target == null) return deletion();
    _deleting = target;
    try {
      return await deletion();
    } catch (_) {
      if (_deleting == target) _deleting = null;
      rethrow;
    }
  }

  @visibleForTesting
  static void resetForTest() => _deleting = null;
}
