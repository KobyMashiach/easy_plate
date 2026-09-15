import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../../core/constants/app_enums.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../recipe_sharing/domain/entities/share_invite_entity.dart';
import '../../../recipe_sharing/domain/usecases/share_recipe_usecase.dart';
import '../../../user_profile/domain/repositories/user_profile_repository.dart';
import '../container_adapter.dart';
import '../entities/collab_container_entity.dart';
import '../repositories/collab_containers_repository.dart';
import 'recipe_linker.dart';

/// Everything that happens to a shared book or plan, for one kind at a time.
/// The recipe flows have one class per step; here they sit together because
/// every step is the same for both kinds and only [adapter] differs.
class ContainerCollab<T> {
  final ContainerAdapter<T> adapter;
  final CollabContainersRepository containers;
  final RecipeLinker linker;
  final UserProfileRepository profiles;

  /// How long a save waits for Firestore before treating the write as
  /// queued. Same reasoning as SaveCollabRecipeUseCase: offline, the SDK
  /// holds the write and the local save must not wait on it.
  final Duration remoteWriteTimeout;

  const ContainerCollab({
    required this.adapter,
    required this.containers,
    required this.linker,
    required this.profiles,
    this.remoteWriteTimeout = const Duration(seconds: 8),
  });

  // ── Sharing ────────────────────────────────────────────────────────────

  /// Look the contact up, make the item shared if it is not yet, invite —
  /// into the container and into every recipe of it this account owns.
  Future<T> share(
    T item, {
    required String contact,
    required CollabRole role,
    required String ownerUid,
    List<String> senderContacts = const [],
  }) async {
    assert(role != CollabRole.owner, 'an invite grants viewer or editor only');
    if (!adapter.isMine(item)) {
      throw StateError('Only what this account owns can be shared');
    }

    final targetUid = await profiles.findUidByContact(contact);
    if (targetUid == null) {
      final anySenderFound = await _anyResolves(senderContacts);
      throw ShareFailure(
        anySenderFound || senderContacts.isEmpty
            ? ShareFailure.notFound
            : ShareFailure.directoryUnavailable,
      );
    }
    if (targetUid == ownerUid) throw const ShareFailure(ShareFailure.self);

    final linked = await linker.ensureCollabs(
      adapter.recipeIdsOf(item),
      uid: ownerUid,
    );
    final content = adapter.encode(
      item,
      collabIdByRecipeId: linked.byRecipeId,
      titles: linked.titles,
    );
    final title = adapter.titleOf(item);

    var owned = item;
    var collabId = adapter.collabIdOf(item);
    if (collabId == null) {
      collabId = await containers.create(
        kind: adapter.kind,
        title: title,
        content: content,
        ownerUid: ownerUid,
      );
      // Saved before the invite goes out, so a crash between the two leaves
      // a shareable item rather than an orphaned document.
      owned = adapter.withCollab(
        item,
        collabId: collabId,
        role: CollabRole.owner,
      );
      await adapter.save(owned);
    } else {
      // Recipes just made shareable have to be in the document before the
      // invite, or the recipient's copy would be missing them.
      await containers.write(
        collabId,
        title: title,
        content: content,
        byUid: ownerUid,
      );
    }

    await containers.invite(
      container: CollabContainerEntity(
        id: collabId,
        kind: adapter.kind,
        ownerUid: ownerUid,
        members: const {},
        title: title,
        content: content,
        updatedAt: DateTime.now(),
      ),
      targetUid: targetUid,
      role: role,
      recipes: linked.owned,
    );
    return owned;
  }

  Future<bool> _anyResolves(List<String> contacts) async {
    for (final contact in contacts) {
      if (await profiles.findUidByContact(contact) != null) return true;
    }
    return false;
  }

  // ── Saving ─────────────────────────────────────────────────────────────

  /// A save by the owner or an editor: the document is rewritten, and every
  /// participant is let into any recipe this account owns that is new to it.
  /// Nothing happens for an item that is not shared or shared read-only.
  Future<void> publish(T item, {required String uid}) async {
    final collabId = adapter.collabIdOf(item);
    if (collabId == null) return;
    if (adapter.roleOf(item) == CollabRole.viewer) {
      throw const AppException(
        AppErrorType.unauthorized,
        message: 'viewer-cannot-edit',
      );
    }

    final linked = await linker.ensureCollabs(
      adapter.recipeIdsOf(item),
      uid: uid,
    );
    final content = adapter.encode(
      item,
      collabIdByRecipeId: linked.byRecipeId,
      titles: linked.titles,
    );

    CollabContainerEntity? remote;
    try {
      remote = await containers.get(collabId);
    } catch (e) {
      debugPrint('Shared ${adapter.kind.name} $collabId unreachable: $e');
      return;
    }
    // Deleted by the owner: the next open orphans the local copy.
    if (remote == null) return;

    try {
      await containers
          .write(
            collabId,
            title: adapter.titleOf(item),
            content: content,
            byUid: uid,
          )
          .timeout(remoteWriteTimeout);
    } on TimeoutException {
      // Queued offline; it lands when the network does.
    }

    // Nobody to let in: no recipes of mine, or nobody but me on the share.
    final others = remote.participants.keys.where((p) => p != uid);
    if (linked.owned.isEmpty || others.isEmpty) return;
    try {
      await containers.inviteToRecipes(
        containerId: collabId,
        participants: remote.participants,
        recipes: linked.owned,
        byUid: uid,
      );
    } catch (e) {
      debugPrint(
        'Recipe invites for ${adapter.kind.name} $collabId failed: $e',
      );
    }
  }

  // ── Receiving ──────────────────────────────────────────────────────────

  Future<T> accept(ShareInviteEntity invite, {required String uid}) async {
    final container = await containers.acceptInvite(invite);
    return _localFrom(container, uid: uid);
  }

  Future<void> decline(ShareInviteEntity invite) =>
      containers.declineInvite(invite);

  /// The document laid over this account's copy (or a fresh one), with every
  /// recipe it can reach cached locally first, saved and returned.
  Future<T> _localFrom(
    CollabContainerEntity container, {
    required String uid,
    T? local,
  }) async {
    final byCollabId = await linker.materialize(
      container.recipeCollabIds,
      uid: uid,
    );
    local ??= (await adapter.all())
        .where((i) => adapter.collabIdOf(i) == container.id)
        .firstOrNull;
    final decoded = adapter.decode(
      container,
      local: local,
      recipeIdByCollabId: byCollabId,
      uid: uid,
    );
    if (local != null && !_differs(local, decoded, byCollabId)) return local;
    await adapter.save(decoded);
    return decoded;
  }

  bool _differs(T a, T b, Map<String, String> recipeIdByCollabId) {
    final collabIdByRecipeId = {
      for (final e in recipeIdByCollabId.entries) e.value: e.key,
    };
    String key(T item) => jsonEncode({
      'title': adapter.titleOf(item),
      'role': adapter.roleOf(item)?.name,
      'collab': adapter.collabIdOf(item),
      'content': adapter.encode(
        item,
        collabIdByRecipeId: collabIdByRecipeId,
        titles: const {},
      ),
    });
    return key(a) != key(b);
  }

  /// Refreshes a single local copy from a direct read of its document.
  /// Missing, or no longer readable (this account was removed), the copy
  /// becomes an ordinary private item rather than vanishing.
  Future<T> sync(T local, {required String uid}) async {
    final collabId = adapter.collabIdOf(local);
    if (collabId == null) return local;
    CollabContainerEntity? container;
    try {
      container = await containers.get(collabId);
    } catch (e) {
      if (!'$e'.contains('permission-denied')) rethrow;
    }
    if (container == null) {
      final orphaned = adapter.withoutCollab(local);
      await adapter.save(orphaned);
      return orphaned;
    }
    return _localFrom(container, uid: uid, local: local);
  }

  /// Brings every local copy of this kind up to date in one pass, from the
  /// two queries the caller already ran. Never orphans: a query answers from
  /// cache offline, so an absent document proves nothing.
  Future<int> refresh(
    List<CollabContainerEntity> fetched, {
    required String uid,
  }) async {
    final cached = (await adapter.all()).where(adapter.isShared).toList();
    if (cached.isEmpty) return 0;
    final byId = {
      for (final c in fetched)
        if (c.kind == adapter.kind) c.id: c,
    };
    var rewritten = 0;
    for (final local in cached) {
      final container = byId[adapter.collabIdOf(local)];
      if (container == null) continue;
      try {
        final result = await _localFrom(container, uid: uid, local: local);
        if (!identical(result, local)) rewritten++;
      } catch (e) {
        debugPrint(
          'Shared ${adapter.kind.name} ${container.id} refresh failed: $e',
        );
      }
    }
    return rewritten;
  }

  // ── Leaving ────────────────────────────────────────────────────────────

  /// Before a local copy is deleted: the owner takes the document down, a
  /// member leaves it. Best effort — offline, the copy is simply gone here
  /// and the roster catches up when this account next appears.
  Future<void> retire(T item, {required String uid}) async {
    final collabId = adapter.collabIdOf(item);
    if (collabId == null) return;
    try {
      if (adapter.isMine(item)) {
        await containers.delete(collabId);
      } else {
        await containers.removeMember(collabId, uid);
      }
    } catch (e) {
      debugPrint('Shared ${adapter.kind.name} $collabId retire failed: $e');
    }
  }
}
