import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';

import '../hive/user_scope.dart';

/// Where the mirrors write: the account's own document, or the household's
/// once the account belongs to one (Pro Duo / Pro Family). Set by the
/// household service; read by every mirror on every write, so a switch takes
/// effect at once.
abstract class CloudRoot {
  static const usersCollection = 'users';
  static const householdsCollection = 'households';

  static String? householdId;

  /// The document the shared mirrors hang beneath, or null before an
  /// account is resolved.
  static DocumentReference<Map<String, dynamic>>? sharedRoot(
    FirebaseFirestore firestore,
  ) {
    final hid = householdId;
    if (hid != null) return firestore.collection(householdsCollection).doc(hid);
    return personalRoot(firestore);
  }

  static DocumentReference<Map<String, dynamic>>? personalRoot(
    FirebaseFirestore firestore,
  ) {
    final uid = UserScope().uid;
    if (uid == null) return null;
    return firestore.collection(usersCollection).doc(uid);
  }
}

/// A local box that also lives in the cloud, without saying at what type.
///
/// [CloudSyncService] keeps a list of these so it can hydrate every mirror in
/// one pass; the type argument stays inside [UserCloudCollection] because a
/// `List<UserCloudCollection>` would erase it to `dynamic` and Hive would then
/// be asked for a `Box<dynamic>` it never opened.
abstract class CloudMirror {
  Future<void> hydrate();

  /// Whether the mirror follows the household root (recipes, plans…) or
  /// stays the account's own (preferences, daily usage).
  bool get shared;

  /// Keeps the box following the cloud copy while a household is active,
  /// so what one member changes shows up for the others.
  Future<void> listen();
  Future<void> stopListening();

  /// Empties the local box: a member leaving a household must not carry
  /// its data into their own root.
  Future<void> clearLocal();
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
  static const usersCollection = CloudRoot.usersCollection;

  @override
  final bool shared;

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
    this.shared = true,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;

  /// Null until an account is resolved. Writing to a guessed path would put one
  /// account's recipes in another's subtree, so callers skip instead.
  CollectionReference<Map<String, dynamic>>? _ref() {
    final root = shared
        ? CloudRoot.sharedRoot(_firestore)
        : CloudRoot.personalRoot(_firestore);
    return root?.collection(collection);
  }

  @override
  Future<void> listen() async {
    await stopListening();
    final ref = _ref();
    if (ref == null) return;
    final box = await UserScope().open<T>(boxName);
    _subscription = ref.snapshots().listen(
      (snapshot) => _apply(snapshot, box),
      onError: (Object e) =>
          debugPrint('Cloud listen on $collection failed: $e'),
    );
  }

  @override
  Future<void> stopListening() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  @override
  Future<void> clearLocal() async {
    final box = await UserScope().open<T>(boxName);
    await box.clear();
  }

  /// Applies what changed on the server. This device's own writes come
  /// back through the same stream: first as pending, then acknowledged; both
  /// are skipped when the box already holds the value, so a save never
  /// rebuilds the screens twice.
  Future<void> _apply(
    QuerySnapshot<Map<String, dynamic>> snapshot,
    Box<T> box,
  ) async {
    if (!box.isOpen) return;
    final puts = <String, T>{};
    final deletes = <String>[];
    for (final change in snapshot.docChanges) {
      final id = change.doc.id;
      if (change.type == DocumentChangeType.removed) {
        if (box.containsKey(id)) deletes.add(id);
        continue;
      }
      if (change.doc.metadata.hasPendingWrites) continue;
      final data = change.doc.data();
      if (data == null) continue;
      final current = box.get(id);
      if (current != null && _sameJson(toJson(current), data)) continue;
      try {
        puts[id] = fromJson(data);
      } catch (e) {
        debugPrint('Cloud change on $collection/$id skipped: $e');
      }
    }
    if (puts.isNotEmpty) await box.putAll(puts);
    if (deletes.isNotEmpty) await box.deleteAll(deletes);
  }

  static bool _sameJson(Map<String, dynamic> a, Map<String, dynamic> b) =>
      const DeepCollectionEquality().equals(_plain(a), _plain(b));

  /// Firestore hands timestamps back as [Timestamp]; the model may encode
  /// them as strings or millis. Comparing through a plain encoding keeps the
  /// echo check honest without knowing each model's choice.
  static Object? _plain(Object? value) => switch (value) {
    Timestamp() => value.millisecondsSinceEpoch,
    Map() => {for (final e in value.entries) e.key.toString(): _plain(e.value)},
    List() => value.map(_plain).toList(),
    _ => value,
  };

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
    final decoded = <String, T>{};

    for (final doc in snapshot.docs) {
      try {
        // Decoded one at a time: a single document written by an older build
        // should cost that one record, not the whole collection.
        decoded[doc.id] = fromJson(doc.data());
        remoteIds.add(doc.id);
      } catch (e) {
        debugPrint('Cloud hydrate of $collection/${doc.id} skipped: $e');
      }
    }
    // One write, one box event: every tab watching this box re-reads it
    // once, not once per record. Sign-in with a few hundred recipes used to
    // rebuild the recipes tab a few hundred times.
    if (decoded.isNotEmpty) await box.putAll(decoded);

    // Copied before pushing: the loop above writes to the same box.
    for (final value in box.values.toList()) {
      final id = idOf(value);
      if (!remoteIds.contains(id)) unawaited(push(value));
    }
  }
}
