import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../hive/user_scope.dart';

/// A local box that also lives in the cloud, without saying at what type.
///
/// [CloudSyncService] keeps a list of these so it can hydrate every mirror in
/// one pass; the type argument stays inside [UserCloudCollection] because a
/// `List<UserCloudCollection>` would erase it to `dynamic` and Hive would then
/// be asked for a `Box<dynamic>` it never opened.
abstract class CloudMirror {
  Future<void> hydrate();
}

/// Mirrors one Hive box into `users/{uid}/{collection}` in Firestore.
///
/// A box is a file in the app's container: it dies with an uninstall and never
/// existed on a second device, which is why an account that signed in
/// elsewhere found its recipes, books and shopping day gone. The uid-scoped
/// path means the account carries its own data with it — the same guarantee
/// [UserScope] gives locally, extended off the device.
///
/// Documents are keyed by the same id the box uses, so pushing the same record
/// twice overwrites rather than duplicates.
class UserCloudCollection<T> implements CloudMirror {
  /// The account documents already written by the profile repository. The
  /// mirrored data hangs beneath them, so one Firestore rule covers it all.
  static const usersCollection = 'users';

  /// Base name of the local box, as passed to [UserScope.open].
  final String boxName;

  /// Subcollection under the account document, e.g. `recipes`.
  final String collection;

  final String Function(T value) idOf;
  final Map<String, dynamic> Function(T value) toJson;
  final T Function(Map<String, dynamic> json) fromJson;

  final FirebaseFirestore _firestore;

  UserCloudCollection({
    required this.boxName,
    required this.collection,
    required this.idOf,
    required this.toJson,
    required this.fromJson,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Null until an account is resolved. Writing to a guessed path would put one
  /// account's recipes in another's subtree, so callers skip instead.
  CollectionReference<Map<String, dynamic>>? _ref() {
    final uid = UserScope().uid;
    if (uid == null) return null;
    return _firestore.collection(usersCollection).doc(uid).collection(collection);
  }

  /// Sends one record up.
  ///
  /// Never `await`ed from a save path: offline, the Firestore SDK applies the
  /// write to its own queue immediately but does not complete the future until
  /// the server acknowledges it, so awaiting would hang saving a recipe on a
  /// train. Errors are swallowed on purpose — the local box is the copy the
  /// user is looking at, and it has already been written.
  Future<void> push(T value) async {
    final ref = _ref();
    if (ref == null) return;
    try {
      await ref.doc(idOf(value)).set(toJson(value));
    } catch (e) {
      debugPrint('Cloud push to $collection failed: $e');
    }
  }

  Future<void> remove(String id) async {
    final ref = _ref();
    if (ref == null) return;
    try {
      await ref.doc(id).delete();
    } catch (e) {
      debugPrint('Cloud delete from $collection failed: $e');
    }
  }

  /// Merges the account's cloud copy into the local box, then sends up
  /// anything only the box had.
  ///
  /// The cloud wins where both sides hold the same id: it is the copy every
  /// device agrees on, and the local box has just been opened for an account
  /// that may not have used this device before. The push-back half covers the
  /// two cases where the box legitimately knows more — an account whose data
  /// predates this mirror, and records saved while the network was down.
  ///
  /// There are no tombstones, so a record deleted on another device while this
  /// one was offline is restored rather than removed. Deletes propagate
  /// immediately when online, which is the case that matters.
  @override
  Future<void> hydrate() async {
    final ref = _ref();
    if (ref == null) return;

    // Reads fall back to the SDK's cache when the server cannot be reached,
    // and throw only when there is no cache either — which is just "nothing to
    // merge", so the local box is left as it is.
    final QuerySnapshot<Map<String, dynamic>> snapshot;
    try {
      snapshot = await ref.get();
    } catch (e) {
      debugPrint('Cloud hydrate of $collection failed: $e');
      return;
    }

    final box = await UserScope().open<T>(boxName);
    final remoteIds = <String>{};

    for (final doc in snapshot.docs) {
      try {
        // Decoded one at a time: a single document written by an older build
        // should cost that one record, not the whole collection.
        final value = fromJson(doc.data());
        await box.put(doc.id, value);
        remoteIds.add(doc.id);
      } catch (e) {
        debugPrint('Cloud hydrate of $collection/${doc.id} skipped: $e');
      }
    }

    // Copied before pushing: the loop above writes to the same box.
    for (final value in box.values.toList()) {
      final id = idOf(value);
      if (!remoteIds.contains(id)) unawaited(push(value));
    }
  }
}
