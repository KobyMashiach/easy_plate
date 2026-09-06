import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';

/// Keeps every local box namespaced to the signed-in account.
///
/// Hive boxes are files, and a single fixed name means one shared file for
/// whoever happens to be signed in — which is how one account's recipes ended
/// up visible to the next. Suffixing the name with the uid gives each account
/// its own file, so signing out and back in restores exactly that account's
/// data and nothing else.
///
/// The community lives in Firestore and is deliberately not scoped: it is
/// shared by design.
class UserScope {
  static final UserScope _instance = UserScope._internal();
  factory UserScope() => _instance;
  UserScope._internal();

  /// Every base box name that gets scoped, so a user switch knows what to
  /// close. Kept here rather than derived, because a box that is missed would
  /// silently leak the previous account's data.
  static const scopedBoxes = [
    'userPreferencesBox',
    'recipesBox',
    'recipeBooksBox',
    'mealPlansBox',
    'groceryListsBox',
  ];

  String? _uid;
  String? get uid => _uid;

  /// Points the scope at [uid], closing the previous account's boxes first.
  ///
  /// Only ever called on sign-in. Closing at sign-out instead would race the
  /// screens still being torn down as the router redirects to the login.
  Future<void> switchTo(String uid) async {
    if (_uid == uid) return;

    final previous = _uid;
    if (previous != null) {
      for (final base in scopedBoxes) {
        final name = '${base}_$previous';
        if (Hive.isBoxOpen(name)) await Hive.box<dynamic>(name).close();
      }
    }
    _uid = uid;
  }

  /// Opens [base] for the current account. Throws rather than falling back to
  /// an unscoped box: a silent fallback is exactly the bug this class exists
  /// to prevent.
  Future<Box<T>> open<T>(String base) {
    final uid = _uid;
    if (uid == null) {
      throw StateError('UserScope.open("$base") before any user was resolved');
    }
    return Hive.openBox<T>('${base}_$uid');
  }

  /// Test seam — the singleton otherwise carries a uid between tests.
  @visibleForTesting
  void resetForTest() => _uid = null;
}
