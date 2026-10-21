import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/sync/cloud_sync_service.dart';
import '../../../core/sync/user_cloud_collection.dart';
import 'household_entity.dart';

/// The household this account belongs to, followed live. Moving in or out
/// rehomes the cloud mirrors: the service is the one place that sets
/// [CloudRoot.householdId].
class HouseholdService extends ChangeNotifier {
  static final HouseholdService _instance = HouseholdService._internal();
  factory HouseholdService() => _instance;
  HouseholdService._internal();

  static const collection = 'households';

  HouseholdEntity? _current;
  HouseholdEntity? get current => _current;
  bool get inHousehold => _current != null;

  String? _uid;
  bool _resolved = false;
  bool get resolved => _resolved;
  Completer<void>? _first;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;

  /// Test seam: the mirrors are rehomed through this.
  Future<void> Function(String uid, {required bool wipeShared}) rehome =
      (uid, {required wipeShared}) =>
          CloudSyncService().rehome(uid, wipeShared: wipeShared);

  /// Starts following the account's household and resolves once the first
  /// answer is in (or [timeout] passed), so the sign-in hydrate reads the
  /// right root the first time rather than the account's own and then the
  /// household's.
  Future<void> resolve(
    String uid, {
    Duration timeout = const Duration(seconds: 4),
  }) {
    if (_uid == uid && _subscription != null) {
      // Bounded like the first call: a session refresh (after email
      // verification or a link) re-resolves, and must not wait on the
      // network for good.
      return (_first?.future ?? Future.value()).timeout(
        timeout,
        onTimeout: () => _answerLate = true,
      );
    }
    if (_uid == uid && _resolved) {
      // The listener died on an error after answering. Clearing here would
      // drop the household root until the new first snapshot, and writes in
      // that gap went to the account's own root (split data). What is known
      // stays; the new listener's answers arrive as ordinary changes.
      _listen(uid, null);
      return Future.value();
    }
    clear();
    _uid = uid;
    final first = _first = Completer<void>();
    _listen(uid, first);
    return first.future.timeout(
      timeout,
      onTimeout: () => _answerLate = true,
    );
  }

  void _listen(String uid, Completer<void>? first) {
    try {
      _subscription = watch(uid).listen(
        (snapshot) => _onSnapshot(uid, snapshot),
        onError: (Object e) {
          debugPrint('Household watch failed: $e');
          // Firestore closes the stream after an error. Left in place,
          // the dead subscription made every later resolve() for this
          // uid return early and the household went unfollowed for the
          // rest of the session.
          _subscription?.cancel();
          _subscription = null;
          if (first != null && !first.isCompleted) first.complete();
        },
      );
    } catch (e) {
      debugPrint('Household watch unavailable: $e');
      if (first != null && !first.isCompleted) first.complete();
    }
  }

  /// Test seam: the account's household query, live.
  @visibleForTesting
  Stream<QuerySnapshot<Map<String, dynamic>>> Function(String uid) watch =
      (uid) => FirebaseFirestore.instance
          .collection(collection)
          .where('memberUids', arrayContains: uid)
          .limit(1)
          .snapshots();

  /// [resolve] gave up waiting, so the sign-in hydrate read the account's
  /// own root: a household arriving after that has to be read in like a
  /// join, not only listened to.
  bool _answerLate = false;

  /// The rehome in progress, if any; the next one waits for it.
  Future<void> _rehoming = Future.value();

  Future<void> _onSnapshot(
    String uid,
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) async {
    if (_uid != uid) return;
    final doc = snapshot.docs.firstOrNull;
    final next = doc == null
        ? null
        : HouseholdEntity.fromJson(doc.id, doc.data());
    final previous = _current;
    final firstAnswer = !_resolved;
    _resolved = true;
    _current = next;
    CloudRoot.householdId = next?.id;
    final arrivedLate = firstAnswer && _answerLate && next != null;
    if (firstAnswer && !arrivedLate) {
      // The first answer only sets the root; the session's own hydrate
      // follows. Live mirroring starts here when the account is already in.
      if (next != null) unawaited(CloudSyncService().startListening());
      _first?.complete();
      notifyListeners();
      return;
    }
    if (arrivedLate) _first?.complete();
    if (previous?.id != next?.id) {
      // Left (or was removed, or the owner closed it): the shared boxes are
      // emptied before reading the account's own root. The owner closing
      // their household keeps everything and carries it back.
      final wasOwnerLeaving =
          next == null && previous != null && previous.isOwner(uid);
      // One rehome at a time, in order: a second change landing while the
      // first ran (left, then joined) started a second one beside it, and
      // the older — wiping and pointing at the old root — could finish
      // last. One overtaken by a newer change is skipped; that one follows.
      final run = _rehoming.then((_) async {
        if (_uid != uid || _current?.id != next?.id) return;
        await rehome(uid, wipeShared: next == null && !wasOwnerLeaving);
      });
      _rehoming = run.catchError((Object e) {
        debugPrint('Rehome after household change failed: $e');
      });
      await _rehoming;
      // Signed out, or another account in, while the rehome ran.
      if (_uid != uid) return;
    }
    notifyListeners();
  }

  void clear() {
    _subscription?.cancel();
    _subscription = null;
    _uid = null;
    _current = null;
    _resolved = false;
    _answerLate = false;
    if (_first case final first? when !first.isCompleted) first.complete();
    _first = null;
    CloudRoot.householdId = null;
  }

  @visibleForTesting
  void setForTest(HouseholdEntity? household, {String? uid}) {
    _uid = uid ?? _uid;
    _current = household;
    _resolved = true;
    CloudRoot.householdId = household?.id;
    notifyListeners();
  }
}
