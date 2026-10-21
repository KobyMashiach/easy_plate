import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_enums.dart';
import '../../../community/data/doc_fields.dart';
import '../../../recipe_sharing/data/datasources/recipe_sharing_remote_datasource.dart';
import '../../../recipe_sharing/domain/entities/share_invite_entity.dart';
import '../../domain/entities/collab_container_entity.dart';
import '../../domain/repositories/collab_containers_repository.dart';

/// `collab_containers/{id}`: one collection for shared books and plans, told
/// apart by `kind`. The roster fields (`ownerUid`, `members`, `memberUids`)
/// and the invite flow are the same as `collab_recipes`, and so are the
/// rules — a container is a shared recipe whose body happens to point at
/// other shared recipes.
class CollabContainersFirestoreDataSource {
  static const collection = 'collab_containers';
  static const invites = 'share_invites';
  static const notifications = 'notifications';
  static const _uuid = Uuid();

  final FirebaseFirestore _firestore;

  /// Invite ids seen to exist this session, so a save that re-checks every
  /// participant against every recipe does not re-read them each time.
  final _known = <String>{};

  CollabContainersFirestoreDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _doc(String id) =>
      _firestore.collection(collection).doc(id);

  CollabContainerEntity _from(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    final createdAt = docDate(data['createdAt']) ?? DateTime.now();
    final rawMembers = docMap(data['members']) ?? const {};
    return CollabContainerEntity(
      id: doc.id,
      kind: CollabKind.fromName(docStringOrNull(data['kind'])),
      ownerUid: docString(data['ownerUid']),
      members: {
        for (final entry in rawMembers.entries)
          entry.key: ?CollabRole.values
              .where((r) => r.name == entry.value)
              .firstOrNull,
      },
      title: docString(data['title']),
      content: docMap(data['content']) ?? {},
      updatedAt: docDate(data['updatedAt']) ?? createdAt,
      updatedBy: docStringOrNull(data['updatedBy']),
    );
  }

  Future<String> create({
    required CollabKind kind,
    required String title,
    required Map<String, dynamic> content,
    required String ownerUid,
  }) async {
    final id = _uuid.v4();
    await _doc(id).set({
      'kind': kind.name,
      'title': title,
      'content': content,
      'ownerUid': ownerUid,
      'members': <String, String>{},
      'memberUids': <String>[],
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'updatedBy': ownerUid,
    });
    return id;
  }

  Future<CollabContainerEntity?> get(String id) async {
    final doc = await _doc(id).get();
    return doc.exists ? _from(doc) : null;
  }

  Future<void> write(
    String id, {
    required String title,
    required Map<String, dynamic> content,
    required String byUid,
  }) {
    return _doc(id).update({
      'title': title,
      'content': content,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': byUid,
    });
  }

  Future<void> delete(String id) => _doc(id).delete();

  DocumentReference<Map<String, dynamic>> _invite(
    String collabId,
    String targetUid,
  ) => _firestore
      .collection(invites)
      .doc(ShareInviteEntity.idFor(collabId: collabId, targetUid: targetUid));

  Map<String, dynamic> _inviteFields({
    required String collabId,
    required String title,
    required String ownerUid,
    required String targetUid,
    required CollabRole role,
    required CollabKind kind,
    String? via,
  }) => {
    'collabId': collabId,
    'recipeTitle': title,
    'ownerUid': ownerUid,
    'targetUid': targetUid,
    'role': role.name,
    'status': ShareInviteStatus.pending.name,
    'kind': kind.name,
    'via': ?via,
    'createdAt': Timestamp.now(),
  };

  /// The recipe invites that do not exist yet. An invite already sent —
  /// directly, or with another container — must not be rewritten: only its
  /// target may touch it after creation, so the whole batch would be refused.
  /// With [replaceDead], one answered by a target who has since left the
  /// recipe's roster (see [RecipeSharingFirestoreDataSource.inviteIsDead])
  /// is deleted, which the writer may do, and counted as missing. Only a
  /// deliberate invite asks for that: a save must not quietly undo a
  /// removal the recipe's owner made on purpose.
  Future<List<({String collabId, String title, String targetUid})>>
  _missingRecipeInvites(
    List<RecipeInvite> recipes,
    Iterable<String> targets, {
    bool replaceDead = false,
  }) async {
    final wanted = [
      for (final target in targets)
        for (final recipe in recipes)
          if (!_known.contains(
            ShareInviteEntity.idFor(
              collabId: recipe.collabId,
              targetUid: target,
            ),
          ))
            (collabId: recipe.collabId, title: recipe.title, targetUid: target),
    ];
    if (wanted.isEmpty) return const [];
    final existing = await Future.wait([
      for (final w in wanted)
        RecipeSharingFirestoreDataSource.readInvite(
          _invite(w.collabId, w.targetUid),
        ),
    ]);
    final missing = <({String collabId, String title, String targetUid})>[];
    for (var i = 0; i < wanted.length; i++) {
      final invite = existing[i];
      if (invite == null) {
        missing.add(wanted[i]);
        continue;
      }
      final dead =
          replaceDead &&
          await RecipeSharingFirestoreDataSource.inviteIsDead(
            invite,
            _firestore
                .collection(RecipeSharingFirestoreDataSource.collabs)
                .doc(wanted[i].collabId),
          );
      if (dead) {
        await invite.reference.delete();
        missing.add(wanted[i]);
      } else {
        _known.add(invite.id);
      }
    }
    return missing;
  }

  Future<void> invite({
    required CollabContainerEntity container,
    required String targetUid,
    required CollabRole role,
    required List<RecipeInvite> recipes,
  }) async {
    // A deliberate invite to this person re-checks every recipe invite of
    // theirs: one seen earlier this session may have died since (removed
    // from the share, then invited again).
    _known.removeWhere((id) => id.endsWith('_$targetUid'));
    final missing = await _missingRecipeInvites(
      recipes,
      [targetUid],
      replaceDead: true,
    );
    // Shared with the same person before: the invite stands (pending, or
    // accepted while they are still a member) and may not be rewritten by
    // anyone but them. Only recipes added since are new to them. A dead one
    // — they were removed, or declined — is deleted and written afresh, with
    // an inbox item under a new id since the old item may still be there.
    final inviteId = ShareInviteEntity.idFor(
      collabId: container.id,
      targetUid: targetUid,
    );
    var notificationId = inviteId;
    final existing = await RecipeSharingFirestoreDataSource.readInvite(
      _invite(container.id, targetUid),
    );
    var already = existing != null;
    if (existing != null &&
        await RecipeSharingFirestoreDataSource.inviteIsDead(
          existing,
          _doc(container.id),
        )) {
      await existing.reference.delete();
      already = false;
      notificationId = '${inviteId}_${DateTime.now().millisecondsSinceEpoch}';
    }
    if (already && missing.isEmpty) return;
    // The container invite and its inbox item go first, so they share the
    // first commit (the inbox rule reads the invite with getAfter).
    final writes = <void Function(WriteBatch)>[];
    if (!already) {
      writes.add(
        (batch) => batch.set(
          _invite(container.id, targetUid),
          _inviteFields(
            collabId: container.id,
            title: container.title,
            ownerUid: container.ownerUid,
            targetUid: targetUid,
            role: role,
            kind: container.kind,
          ),
        ),
      );
      writes.add(
        (batch) => batch.set(
          _firestore
              .collection(notifications)
              .doc(targetUid)
              .collection('items')
              .doc(notificationId),
          {
            'type': AppNotificationType.shareInvite.name,
            'kind': container.kind.name,
            'fromUid': container.ownerUid,
            'inviteId': inviteId,
            'collabId': container.id,
            'recipeTitle': container.title,
            'role': role.name,
            'read': false,
            'createdAt': Timestamp.now(),
          },
        ),
      );
    }
    for (final m in missing) {
      writes.add(
        (batch) => batch.set(
          _invite(m.collabId, m.targetUid),
          _inviteFields(
            collabId: m.collabId,
            title: m.title,
            ownerUid: container.ownerUid,
            targetUid: m.targetUid,
            role: role,
            kind: CollabKind.recipe,
            via: container.id,
          ),
        ),
      );
    }
    await _commitChunked(writes);
    _known.addAll([
      for (final m in missing)
        ShareInviteEntity.idFor(collabId: m.collabId, targetUid: m.targetUid),
    ]);
  }

  Future<void> inviteToRecipes({
    required String containerId,
    required Map<String, CollabRole> participants,
    required List<RecipeInvite> recipes,
    required String byUid,
  }) async {
    final targets = participants.keys.where((uid) => uid != byUid);
    final missing = await _missingRecipeInvites(recipes, targets);
    if (missing.isEmpty) return;
    final writes = <void Function(WriteBatch)>[];
    for (final m in missing) {
      // The owner of the container gets to edit a recipe an editor brought
      // in; everyone else gets the role they hold on the container.
      final role = participants[m.targetUid] == CollabRole.viewer
          ? CollabRole.viewer
          : CollabRole.editor;
      writes.add(
        (batch) => batch.set(
          _invite(m.collabId, m.targetUid),
          _inviteFields(
            collabId: m.collabId,
            title: m.title,
            ownerUid: byUid,
            targetUid: m.targetUid,
            role: role,
            kind: CollabKind.recipe,
            via: containerId,
          ),
        ),
      );
    }
    await _commitChunked(writes);
    _known.addAll([
      for (final m in missing)
        ShareInviteEntity.idFor(collabId: m.collabId, targetUid: m.targetUid),
    ]);
  }

  /// A batch takes 500 writes; a little under, per commit. A Family
  /// household times a long book's new recipes is past that, and the one
  /// commit used to fail whole.
  static const _batchLimit = 450;

  Future<void> _commitChunked(List<void Function(WriteBatch)> writes) async {
    for (var i = 0; i < writes.length; i += _batchLimit) {
      final batch = _firestore.batch();
      for (final write in writes.skip(i).take(_batchLimit)) {
        write(batch);
      }
      await batch.commit();
    }
  }

  ShareInviteEntity _inviteFrom(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return ShareInviteEntity(
      id: doc.id,
      collabId: docString(data['collabId']),
      recipeTitle: docString(data['recipeTitle']),
      ownerUid: docString(data['ownerUid']),
      targetUid: docString(data['targetUid']),
      role: CollabRole.values.firstWhere(
        (r) => r.name == data['role'],
        orElse: () => CollabRole.viewer,
      ),
      status: ShareInviteStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => ShareInviteStatus.pending,
      ),
      createdAt: docDate(data['createdAt']) ?? DateTime.now(),
      kind: CollabKind.fromName(docStringOrNull(data['kind'])),
      via: docStringOrNull(data['via']),
    );
  }

  Future<ShareInviteEntity?> recipeInvite({
    required String collabId,
    required String uid,
  }) async {
    // Through readInvite: the rules refuse the read of an invite that is
    // not there, so a plain get would throw for "never invited".
    final doc = await RecipeSharingFirestoreDataSource.readInvite(
      _invite(collabId, uid),
    );
    return doc == null ? null : _inviteFrom(doc);
  }

  /// `whereIn` takes at most 30 values per query.
  static const _idChunk = 30;

  /// The account's invites among [collabIds], a chunk of ids per query. The
  /// rules let an invite's target list invites, which the `targetUid`
  /// filter proves for every row the query can return; the ids are the
  /// deterministic `{collabId}_{uid}` the invites are written under.
  Future<Map<String, ShareInviteEntity>> recipeInvites({
    required Set<String> collabIds,
    required String uid,
  }) async {
    if (collabIds.isEmpty) return const {};
    final ids = [
      for (final collabId in collabIds)
        ShareInviteEntity.idFor(collabId: collabId, targetUid: uid),
    ];
    final snapshots = await Future.wait([
      for (var i = 0; i < ids.length; i += _idChunk)
        _firestore
            .collection(invites)
            .where('targetUid', isEqualTo: uid)
            .where(
              FieldPath.documentId,
              whereIn: ids.sublist(
                i,
                i + _idChunk > ids.length ? ids.length : i + _idChunk,
              ),
            )
            .get(),
    ]);
    final found = parseEach(
      [for (final snapshot in snapshots) ...snapshot.docs],
      _inviteFrom,
      label: 'Recipe invites',
    );
    return {for (final invite in found) invite.collabId: invite};
  }

  Future<void> setInviteStatus(String inviteId, ShareInviteStatus status) {
    return _firestore.collection(invites).doc(inviteId).update({
      'status': status.name,
      'respondedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> join(
    String id, {
    required String uid,
    required CollabRole role,
  }) {
    return _doc(id).update({
      'members.$uid': role.name,
      'memberUids': FieldValue.arrayUnion([uid]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<CollabContainerEntity>> ownedBy(String uid) async {
    final snapshot = await _firestore
        .collection(collection)
        .where('ownerUid', isEqualTo: uid)
        .get();
    return parseEach(snapshot.docs, _from, label: 'Shared containers');
  }

  Future<List<CollabContainerEntity>> sharedWith(String uid) async {
    final snapshot = await _firestore
        .collection(collection)
        .where('memberUids', arrayContains: uid)
        .get();
    return parseEach(snapshot.docs, _from, label: 'Shared containers');
  }

  /// [revokeInvite]: the owner removing someone — their invite is deleted
  /// with the roster change (see [removeFromRoster]).
  Future<void> removeMember(
    String id,
    String memberUid, {
    bool revokeInvite = false,
  }) => removeFromRoster(
    _firestore,
    _doc(id),
    _firestore
        .collection(invites)
        .doc(ShareInviteEntity.idFor(collabId: id, targetUid: memberUid)),
    memberUid,
    revokeInvite: revokeInvite,
  );
}
