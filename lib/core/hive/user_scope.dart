import 'dart:io';

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
    'groceryUiBox',
    'dailyUsageBox',
    'priceRecordsBox',
    'receiptsBox',
    'productPricingBox',
    'contentVariantsBox',
    'shareUsageBox',
  ];

  String? _uid;
  String? get uid => _uid;

  /// The boxes this class has opened, by full scoped name.
  ///
  /// Held because Hive can only hand a box back at the type it was opened with,
  /// and closing one means naming that type. Keeping the reference sidesteps
  /// the question entirely — every scoped box is opened through [open], so this
  /// map is the complete set.
  final Map<String, BoxBase<dynamic>> _opened = {};

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
        final box = _opened.remove(name);
        if (box != null && box.isOpen) await box.close();
      }
    }
    _uid = uid;
  }

  /// Opens [base] for the current account. Throws rather than falling back to
  /// an unscoped box: a silent fallback is exactly the bug this class exists
  /// to prevent.
  Future<Box<T>> open<T>(String base) async {
    final uid = _uid;
    if (uid == null) {
      throw StateError('UserScope.open("$base") before any user was resolved');
    }
    final name = '${base}_$uid';
    final box = await Hive.openBox<T>(name);
    _opened[name] = box;
    return box;
  }

  /// On sign-out: deletes every scoped box of the account that was signed
  /// in — the files, not just their contents — and leaves the scope pointing
  /// at nobody, so a late read throws rather than recreating a box.
  ///
  /// Also sweeps the scoped box files any other account left on this device
  /// before sign-out wiped them. Everything here is mirrored to the account's
  /// cloud copy (see `CloudSyncService`), which the next sign-in hydrates
  /// from; what is not — the translation cache, the open grocery list — is
  /// rebuilt or defaulted on its own.
  ///
  /// Device-level boxes (theme, login language, a skipped update) are not
  /// scoped and not touched: they belong to the phone, not to an account.
  ///
  /// Must run after the signed-in screens are gone: they hold streams on
  /// these boxes, and deleting a box under a live screen is what the
  /// comment on [switchTo] warns about.
  Future<void> clearAccount() async {
    final uid = _uid;
    _uid = null;
    if (uid == null) return;

    String? directory;
    for (final base in scopedBoxes) {
      final name = '${base}_$uid';
      final box = _opened.remove(name);
      try {
        if (box != null && box.isOpen) {
          directory ??= _directoryOf(box.path);
          await box.deleteFromDisk();
        } else {
          await Hive.deleteBoxFromDisk(name);
        }
      } catch (e) {
        debugPrint('Deleting $name failed: $e');
      }
    }
    // Anything still held (a box of another account) is closed first, so
    // the sweep below never deletes a file under an open box.
    for (final box in _opened.values) {
      if (box.isOpen) await box.close();
    }
    _opened.clear();
    if (directory != null) await _sweepLeftovers(directory);
  }

  static String? _directoryOf(String? path) =>
      path == null ? null : File(path).parent.path;

  /// Deletes every `<scoped box>_<uid>` file in [directory], whoever it
  /// belonged to. Hive writes box names lower-cased, so the match is too.
  static Future<void> _sweepLeftovers(String directory) async {
    final prefixes = [for (final base in scopedBoxes) '${base.toLowerCase()}_'];
    try {
      await for (final entry in Directory(directory).list()) {
        if (entry is! File) continue;
        final file = entry.uri.pathSegments.last.toLowerCase();
        if (!(file.endsWith('.hive') || file.endsWith('.lock'))) continue;
        if (!prefixes.any(file.startsWith)) continue;
        try {
          await entry.delete();
        } catch (e) {
          debugPrint('Leftover box $file not deleted: $e');
        }
      }
    } catch (e) {
      debugPrint('Leftover box sweep failed: $e');
    }
  }

  /// Test seam — the singleton otherwise carries a uid between tests.
  @visibleForTesting
  void resetForTest() {
    _uid = null;
    _opened.clear();
  }
}
