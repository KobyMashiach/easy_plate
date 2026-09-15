import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_enums.dart';
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
    final createdAt =
        (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final rawMembers = (data['members'] as Map?) ?? const {};
    return CollabContainerEntity(
      id: doc.id,
      kind: CollabKind.fromName(data['kind'] as String?),
      ownerUid: (data['ownerUid'] as String?) ?? '',
      members: {
        for (final entry in rawMembers.entries)
          entry.key as String: ?CollabRole.values
              .where((r) => r.name == entry.value)
              .firstOrNull,
      },
      title: (data['title'] as String?) ?? '',
      content: Map<String, dynamic>.from((data['content'] as Map?) ?? const {}),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? createdAt,
      updatedBy: data['updatedBy'] as String?,
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
  Future<List<({String collabId, String title, String targetUid})>>
  _missingRecipeInvites(
    List<RecipeInvite> recipes,
    Iterable<String> targets,
  ) async {
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
      for (final w in wanted) _invite(w.collabId, w.targetUid).get(),
    ]);
    final missing = <({String collabId, String title, String targetUid})>[];
    for (var i = 0; i < wanted.length; i++) {
      if (existing[i].exists) {
        _known.add(existing[i].id);
      } else {
        missing.add(wanted[i]);
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
    final missing = await _missingRecipeInvites(recipes, [targetUid]);
    // Shared with the same person before: the invite stands (pending or
    // answered) and may not be rewritten by anyone but them. Only recipes
    // added since are new to them.
    final already = (await _invite(container.id, targetUid).get()).exists;
    if (already && missing.isEmpty) return;
    final batch = _firestore.batch();
    if (!already) {
      batch.set(
        _invite(container.id, targetUid),
        _inviteFields(
          collabId: container.id,
          title: container.title,
          ownerUid: container.ownerUid,
          targetUid: targetUid,
          role: role,
          kind: container.kind,
        ),
      );
      batch.set(
        _firestore
            .collection(notifications)
            .doc(targetUid)
            .collection('items')
            .doc(
              ShareInviteEntity.idFor(
                collabId: container.id,
                targetUid: targetUid,
              ),
            ),
        {
          'type': AppNotificationType.shareInvite.name,
          'kind': container.kind.name,
          'fromUid': container.ownerUid,
          'inviteId': ShareInviteEntity.idFor(
            collabId: container.id,
            targetUid: targetUid,
          ),
          'collabId': container.id,
          'recipeTitle': container.title,
          'role': role.name,
          'read': false,
          'createdAt': Timestamp.now(),
        },
      );
    }
    for (final m in missing) {
      batch.set(
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
      );
    }
    await batch.commit();
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
    final batch = _firestore.batch();
    for (final m in missing) {
      // The owner of the container gets to edit a recipe an editor brought
      // in; everyone else gets the role they hold on the container.
      final role = participants[m.targetUid] == CollabRole.viewer
          ? CollabRole.viewer
          : CollabRole.editor;
      batch.set(
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
      );
    }
    await batch.commit();
    _known.addAll([
      for (final m in missing)
        ShareInviteEntity.idFor(collabId: m.collabId, targetUid: m.targetUid),
    ]);
  }

  ShareInviteEntity _inviteFrom(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return ShareInviteEntity(
      id: doc.id,
      collabId: (data['collabId'] as String?) ?? '',
      recipeTitle: (data['recipeTitle'] as String?) ?? '',
      ownerUid: (data['ownerUid'] as String?) ?? '',
      targetUid: (data['targetUid'] as String?) ?? '',
      role: CollabRole.values.firstWhere(
        (r) => r.name == data['role'],
        orElse: () => CollabRole.viewer,
      ),
      status: ShareInviteStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => ShareInviteStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      kind: CollabKind.fromName(data['kind'] as String?),
      via: data['via'] as String?,
    );
  }

  Future<ShareInviteEntity?> recipeInvite({
    required String collabId,
    required String uid,
  }) async {
    final doc = await _invite(collabId, uid).get();
    return doc.exists ? _inviteFrom(doc) : null;
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
    return snapshot.docs.map(_from).toList();
  }

  Future<List<CollabContainerEntity>> sharedWith(String uid) async {
    final snapshot = await _firestore
        .collection(collection)
        .where('memberUids', arrayContains: uid)
        .get();
    return snapshot.docs.map(_from).toList();
  }

  Future<void> removeMember(String id, String memberUid) {
    return _doc(id).update({
      'members.$memberUid': FieldValue.delete(),
      'memberUids': FieldValue.arrayRemove([memberUid]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
