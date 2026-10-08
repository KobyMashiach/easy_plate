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
      return _first?.future ?? Future.value();
    }
    clear();
    _uid = uid;
    final first = _first = Completer<void>();
    try {
      _subscription = FirebaseFirestore.instance
          .collection(collection)
          .where('memberUids', arrayContains: uid)
          .limit(1)
          .snapshots()
          .listen(
            (snapshot) => _onSnapshot(uid, snapshot),
            onError: (Object e) {
              debugPrint('Household watch failed: $e');
              if (!first.isCompleted) first.complete();
            },
          );
    } catch (e) {
      debugPrint('Household watch unavailable: $e');
      if (!first.isCompleted) first.complete();
    }
    return first.future.timeout(timeout, onTimeout: () {});
  }

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
    if (firstAnswer) {
      // The first answer only sets the root; the session's own hydrate
      // follows. Live mirroring starts here when the account is already in.
      if (next != null) unawaited(CloudSyncService().startListening());
      _first?.complete();
      notifyListeners();
      return;
    }
    if (previous?.id != next?.id) {
      // Left (or was removed, or the owner closed it): the shared boxes are
      // emptied before reading the account's own root. The owner closing
      // their household keeps everything and carries it back.
      final wasOwnerLeaving =
          next == null && previous != null && previous.isOwner(uid);
      try {
        await rehome(uid, wipeShared: next == null && !wasOwnerLeaving);
      } catch (e) {
        debugPrint('Rehome after household change failed: $e');
      }
    }
    notifyListeners();
  }

  void clear() {
    _subscription?.cancel();
    _subscription = null;
    _uid = null;
    _current = null;
    _resolved = false;
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
