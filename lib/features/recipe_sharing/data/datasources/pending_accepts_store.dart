import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../../core/constants/app_enums.dart';
import '../../../../core/hive/user_scope.dart';

/// An invite this device started to accept whose local copy is not written
/// yet.
///
/// Accepting is two server writes (the invite's status, the roster) and
/// then the local copy. Offline, Firestore queues the writes and holds
/// their futures open; the accept is bounded by a timeout, but the queued
/// writes still land once the network returns — and from then on the invite
/// is no longer pending, so the inbox offers no second try. Without a mark
/// the account would be on the roster with nothing on the device. The mark
/// is written before the server is asked and cleared once the copy is saved
/// (or the server refused for good); whatever is left is finished by the
/// next shared-recipe refresh.
class PendingAccept {
  final String collabId;
  final CollabKind kind;
  final DateTime at;

  const PendingAccept({
    required this.collabId,
    required this.kind,
    required this.at,
  });

  /// Young marks belong to an accept that may still be running; the repair
  /// pass leaves them alone or it would write the copy twice.
  static const settleAfter = Duration(minutes: 1);

  /// A mark this old is given up: the join never landed (the owner removed
  /// the account meanwhile, or deleted the share) and every refresh since
  /// has paid a read for it.
  static const giveUpAfter = Duration(days: 7);

  bool isDue(DateTime now) => now.difference(at) >= settleAfter;
  bool isStale(DateTime now) => now.difference(at) >= giveUpAfter;

  Map<String, dynamic> toJson() => {
    'collabId': collabId,
    'kind': kind.name,
    'at': at.toIso8601String(),
  };

  static PendingAccept? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final collabId = raw['collabId'];
    final at = raw['at'];
    if (collabId is! String || collabId.isEmpty || at is! String) return null;
    final when = DateTime.tryParse(at);
    if (when == null) return null;
    return PendingAccept(
      collabId: collabId,
      kind: CollabKind.fromName(raw['kind'] is String ? raw['kind'] : null),
      at: when,
    );
  }
}

abstract class PendingAcceptsStore {
  Future<List<PendingAccept>> all();
  Future<void> add(PendingAccept accept);
  Future<void> remove(String collabId);
}

/// Per account and per device — the device that accepted is the one that
/// owes the copy; another device gets it through the cloud mirror, and a
/// synced mark would have both of them write one.
///
/// Kept in the account's device-local string box (the one the groceries
/// tab keeps its open list in) under its own key prefix: every scoped box
/// has to be named in [UserScope.scopedBoxes] to be closed on an account
/// switch and deleted at sign-out, and that list lives in core. Every
/// failure here is logged and swallowed: a mark that could not be written
/// costs one copy, never the accept itself.
class HivePendingAcceptsStore implements PendingAcceptsStore {
  static final HivePendingAcceptsStore instance = HivePendingAcceptsStore._();
  HivePendingAcceptsStore._();

  static const boxName = 'groceryUiBox';
  static const keyPrefix = 'pendingAccept:';

  /// No account resolved (tests, the sign-out window): nothing to hold a
  /// mark for, and [UserScope.open] would throw on purpose.
  static bool get _scoped => UserScope().uid != null;

  @override
  Future<List<PendingAccept>> all() async {
    if (!_scoped) return const [];
    try {
      final box = await UserScope().open<String>(boxName);
      return [
        for (final key in box.keys)
          if (key is String && key.startsWith(keyPrefix))
            ?PendingAccept.fromJson(_decode(box.get(key))),
      ];
    } catch (e) {
      debugPrint('Pending accepts read failed: $e');
      return const [];
    }
  }

  @override
  Future<void> add(PendingAccept accept) async {
    if (!_scoped) return;
    try {
      final box = await UserScope().open<String>(boxName);
      await box.put(
        '$keyPrefix${accept.collabId}',
        jsonEncode(accept.toJson()),
      );
    } catch (e) {
      debugPrint('Pending accept ${accept.collabId} not recorded: $e');
    }
  }

  @override
  Future<void> remove(String collabId) async {
    if (!_scoped) return;
    try {
      final box = await UserScope().open<String>(boxName);
      await box.delete('$keyPrefix$collabId');
    } catch (e) {
      debugPrint('Pending accept $collabId not cleared: $e');
    }
  }

  static Object? _decode(String? raw) {
    if (raw == null) return null;
    try {
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }
}

/// For tests: the same contract, in memory.
class InMemoryPendingAcceptsStore implements PendingAcceptsStore {
  final entries = <String, PendingAccept>{};

  @override
  Future<List<PendingAccept>> all() async => entries.values.toList();

  @override
  Future<void> add(PendingAccept accept) async =>
      entries[accept.collabId] = accept;

  @override
  Future<void> remove(String collabId) async => entries.remove(collabId);
}
