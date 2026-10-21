import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_enums.dart';
import '../../../community/data/doc_fields.dart';
import '../../../my_recipes/domain/entities/nutrition_entity.dart';
import '../../../my_recipes/domain/entities/recipe_entity.dart';
import '../../../my_recipes/domain/entities/recipe_ingredient_entity.dart';
import '../../domain/entities/collab_recipe_entity.dart';
import '../../domain/entities/share_invite_entity.dart';

abstract class RecipeSharingRemoteDataSource {
  Future<String> createCollab(RecipeEntity recipe, {required String ownerUid});
  Future<void> invite({
    required String collabId,
    required String recipeTitle,
    required String ownerUid,
    required String targetUid,
    required CollabRole role,
  });
  Future<List<ShareInviteEntity>> incomingInvites(String uid);
  Future<List<ShareInviteEntity>> outgoingInvites(String ownerUid);
  Future<CollabRecipeEntity?> getCollab(String collabId);
  Future<void> setInviteStatus(String inviteId, ShareInviteStatus status);
  Future<void> joinCollab(
    String collabId, {
    required String uid,
    required CollabRole role,
  });
  Future<void> writeCollab(
    String collabId,
    RecipeEntity recipe, {
    required String byUid,
  });
  Future<List<CollabRecipeEntity>> collabsOwnedBy(String uid);
  Future<List<CollabRecipeEntity>> collabsSharedWith(String uid);

  /// [revokeInvite] (the owner removing someone, not a member leaving)
  /// also deletes the member's invite: an accepted one left behind is what
  /// the rules' accept branch checks, so the removed member could put
  /// themselves back on the roster with it.
  Future<void> removeMember(
    String collabId,
    String memberUid, {
    bool revokeInvite = false,
  });
}

class RecipeSharingFirestoreDataSource
    implements RecipeSharingRemoteDataSource {
  static const collabs = 'collab_recipes';
  static const invites = 'share_invites';
  static const notifications = 'notifications';
  static const _uuid = Uuid();

  final FirebaseFirestore _firestore;

  /// How long [createCollab] waits for the server before taking the write
  /// as queued. Offline, the SDK holds a write and its future does not
  /// complete until the network returns — which parked every save of a
  /// shared book or plan that brought a new recipe in. The id is drawn
  /// here, so the caller can tag its copy and the document lands later.
  final Duration writeTimeout;

  RecipeSharingFirestoreDataSource({
    FirebaseFirestore? firestore,
    this.writeTimeout = const Duration(seconds: 8),
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _collab(String id) =>
      _firestore.collection(collabs).doc(id);

  Map<String, dynamic> _recipeFields(RecipeEntity recipe) => {
    'title': recipe.title,
    'prepTimeMinutes': recipe.prepTimeMinutes,
    'cookTimeMinutes': recipe.cookTimeMinutes,
    'ingredients': [
      for (final i in recipe.ingredients)
        {'name': i.name, 'amount': i.amount, 'unit': i.unit.name},
    ],
    'steps': recipe.steps,
    'dietaryTags': [for (final tag in recipe.dietaryTags) tag.name],
    'allergens': recipe.allergens.names,
    'mayContain': recipe.mayContain.names,
    // The photo travels as its Storage path plus the file name to cache it
    // under. Before this the picture was simply left behind, and the other
    // account's copy of a shared recipe was permanently blank.
    'imageFileName': recipe.imageFileName,
    'imageStoragePath': recipe.imageStoragePath,
    'servings': recipe.servings,
    'nutrition': recipe.nutrition?.toJson(),
  };

  RecipeEntity _recipeFrom(
    String id,
    Map<String, dynamic> data,
    DateTime createdAt,
  ) {
    return RecipeEntity(
      id: id,
      title: docString(data['title']),
      prepTimeMinutes: docInt(data['prepTimeMinutes']),
      cookTimeMinutes: docInt(data['cookTimeMinutes']),
      ingredients: docMaps(data['ingredients'])
          .map(
            (raw) => RecipeIngredientEntity(
              name: docString(raw['name']),
              amount: docDouble(raw['amount']),
              unit: MeasurementUnit.values.firstWhere(
                (u) => u.name == raw['unit'],
                orElse: () => MeasurementUnit.unspecified,
              ),
            ),
          )
          .toList(),
      steps: docList(data['steps']).whereType<String>().toList(),
      dietaryTags: docList(data['dietaryTags'])
          .whereType<String>()
          .map(
            (n) =>
                DietaryPreference.values.where((d) => d.name == n).firstOrNull,
          )
          .nonNulls
          .toList(),
      allergens: Allergen.fromNames(data['allergens']),
      mayContain: Allergen.fromNames(data['mayContain']),
      imageFileName: docStringOrNull(data['imageFileName']),
      imageStoragePath: docStringOrNull(data['imageStoragePath']),
      servings: docInt(data['servings']),
      nutrition: docOrNull(() => NutritionEntity.fromJson(data['nutrition'])),
      createdAt: createdAt,
    );
  }

  CollabRecipeEntity _collabFrom(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    final createdAt = docDate(data['createdAt']) ?? DateTime.now();
    final rawMembers = docMap(data['members']) ?? const {};
    return CollabRecipeEntity(
      id: doc.id,
      ownerUid: docString(data['ownerUid']),
      members: {
        // Null-aware value: an unknown role name drops the entry rather than
        // inventing a role for it.
        for (final entry in rawMembers.entries)
          entry.key: ?CollabRole.values
              .where((r) => r.name == entry.value)
              .firstOrNull,
      },
      recipe: _recipeFrom(doc.id, data, createdAt),
      updatedAt: docDate(data['updatedAt']) ?? createdAt,
      updatedBy: docStringOrNull(data['updatedBy']),
    );
  }

  @override
  Future<String> createCollab(
    RecipeEntity recipe, {
    required String ownerUid,
  }) async {
    final id = _uuid.v4();
    try {
      await _collab(id)
          .set({
            ..._recipeFields(recipe),
            'ownerUid': ownerUid,
            'members': <String, String>{},
            // Parallel array of member uids, because a map key cannot be
            // queried with `arrayContains` and the rules need a provable
            // "shared with me".
            'memberUids': <String>[],
            'createdAt': Timestamp.now(),
            'updatedAt': Timestamp.now(),
            'updatedBy': ownerUid,
          })
          .timeout(writeTimeout);
    } on TimeoutException {
      // Queued offline; it lands when the network does.
    }
    return id;
  }

  /// Invite and notification in one batch: a notification for an invite that
  /// failed to write, or the reverse, would be a dangling promise.
  ///
  /// The invite id is deterministic, and once written only its target may
  /// touch it — so an invite that is still pending, or accepted by someone
  /// who is still on the roster, stands and nothing is written. One left
  /// behind by a member since removed (or who declined) is dead: the owner
  /// may delete it, and does, before writing the fresh one. The inbox item
  /// of a re-invite gets its own id, because the old one may still sit in
  /// the target's inbox and the owner may not overwrite it.
  @override
  Future<void> invite({
    required String collabId,
    required String recipeTitle,
    required String ownerUid,
    required String targetUid,
    required CollabRole role,
  }) async {
    final inviteId = ShareInviteEntity.idFor(
      collabId: collabId,
      targetUid: targetUid,
    );
    final inviteRef = _firestore.collection(invites).doc(inviteId);
    var notificationId = inviteId;
    final existing = await readInvite(inviteRef);
    if (existing != null) {
      if (!await inviteIsDead(existing, _collab(collabId))) return;
      await inviteRef.delete();
      notificationId = '${inviteId}_${DateTime.now().millisecondsSinceEpoch}';
    }
    final batch = _firestore.batch();
    batch.set(inviteRef, {
      'collabId': collabId,
      'recipeTitle': recipeTitle,
      'ownerUid': ownerUid,
      'targetUid': targetUid,
      'role': role.name,
      'status': ShareInviteStatus.pending.name,
      'createdAt': Timestamp.now(),
    });
    batch.set(
      _firestore
          .collection(notifications)
          .doc(targetUid)
          .collection('items')
          .doc(notificationId),
      {
        'type': AppNotificationType.shareInvite.name,
        'fromUid': ownerUid,
        'inviteId': inviteId,
        'collabId': collabId,
        'recipeTitle': recipeTitle,
        'role': role.name,
        'read': false,
        'createdAt': Timestamp.now(),
      },
    );
    await batch.commit();
  }

  /// The invite at [ref], or null when there is none. The rules let only an
  /// invite's owner or target read it, and for a document that is not there
  /// that check has nothing to look at and refuses the read — so a refusal
  /// on a deterministic id means the same as "not written yet". Any other
  /// failure is still thrown.
  static Future<DocumentSnapshot<Map<String, dynamic>>?> readInvite(
    DocumentReference<Map<String, dynamic>> ref,
  ) async {
    try {
      final doc = await ref.get();
      return doc.exists ? doc : null;
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied') rethrow;
      return null;
    }
  }

  /// An answered invite whose target is no longer on the roster of the
  /// document it was for. Pending invites are never dead: the answer is still
  /// to come. Used by the container flow too, for the recipe invites it
  /// carries along.
  static Future<bool> inviteIsDead(
    DocumentSnapshot<Map<String, dynamic>> invite,
    DocumentReference<Map<String, dynamic>> target,
  ) async {
    final data = invite.data() ?? const <String, dynamic>{};
    if (data['status'] == ShareInviteStatus.pending.name) return false;
    final uid = docStringOrNull(data['targetUid']);
    if (uid == null) return true;
    final doc = await target.get();
    final memberUids = docList(doc.data()?['memberUids']);
    return !memberUids.contains(uid);
  }

  ShareInviteEntity _inviteFrom(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
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

  @override
  Future<List<ShareInviteEntity>> incomingInvites(String uid) async {
    final snapshot = await _firestore
        .collection(invites)
        .where('targetUid', isEqualTo: uid)
        .where('status', isEqualTo: ShareInviteStatus.pending.name)
        .get();
    // A recipe invited as part of a book or plan is answered with the
    // container, so it is not offered on its own.
    return parseEach(
        snapshot.docs,
        _inviteFrom,
        label: 'Invites',
      ).where((i) => i.via == null).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<List<ShareInviteEntity>> outgoingInvites(String ownerUid) async {
    final snapshot = await _firestore
        .collection(invites)
        .where('ownerUid', isEqualTo: ownerUid)
        .get();
    return parseEach(snapshot.docs, _inviteFrom, label: 'Invites')
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<CollabRecipeEntity?> getCollab(String collabId) async {
    final doc = await _collab(collabId).get();
    return doc.exists ? _collabFrom(doc) : null;
  }

  @override
  Future<void> setInviteStatus(String inviteId, ShareInviteStatus status) {
    return _firestore.collection(invites).doc(inviteId).update({
      'status': status.name,
      'respondedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> joinCollab(
    String collabId, {
    required String uid,
    required CollabRole role,
  }) {
    return _collab(collabId).update({
      'members.$uid': role.name,
      'memberUids': FieldValue.arrayUnion([uid]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> writeCollab(
    String collabId,
    RecipeEntity recipe, {
    required String byUid,
  }) {
    return _collab(collabId).update({
      ..._recipeFields(recipe),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': byUid,
    });
  }

  @override
  Future<List<CollabRecipeEntity>> collabsOwnedBy(String uid) async {
    final snapshot = await _firestore
        .collection(collabs)
        .where('ownerUid', isEqualTo: uid)
        .get();
    return parseEach(snapshot.docs, _collabFrom, label: 'Shared recipes');
  }

  @override
  Future<List<CollabRecipeEntity>> collabsSharedWith(String uid) async {
    final snapshot = await _firestore
        .collection(collabs)
        .where('memberUids', arrayContains: uid)
        .get();
    return parseEach(snapshot.docs, _collabFrom, label: 'Shared recipes');
  }

  @override
  Future<void> removeMember(
    String collabId,
    String memberUid, {
    bool revokeInvite = false,
  }) => removeFromRoster(
    _firestore,
    _collab(collabId),
    _firestore
        .collection(invites)
        .doc(ShareInviteEntity.idFor(collabId: collabId, targetUid: memberUid)),
    memberUid,
    revokeInvite: revokeInvite,
  );
}

/// Takes [memberUid] off the roster of [doc] (a shared recipe or container).
///
/// With [revokeInvite], the member's invite goes in the same batch, so a
/// removed member is never left holding an accepted invite to rejoin with.
/// The invite is read first: the owner-only delete rule reads the stored
/// invite, and a batch deleting one that isn't there (an old share) would
/// be refused as a whole, roster change included. When that read fails
/// (offline), the roster change goes alone and the delete follows it.
Future<void> removeFromRoster(
  FirebaseFirestore firestore,
  DocumentReference<Map<String, dynamic>> doc,
  DocumentReference<Map<String, dynamic>> invite,
  String memberUid, {
  required bool revokeInvite,
}) async {
  final roster = <String, Object>{
    'members.$memberUid': FieldValue.delete(),
    'memberUids': FieldValue.arrayRemove([memberUid]),
    'updatedAt': FieldValue.serverTimestamp(),
  };
  if (!revokeInvite) return doc.update(roster);
  bool exists;
  try {
    exists = (await invite.get()).exists;
  } catch (e) {
    await doc.update(roster);
    try {
      await invite.delete();
    } catch (e) {
      debugPrint('Removed member\'s invite not deleted: $e');
    }
    return;
  }
  if (!exists) return doc.update(roster);
  final batch = firestore.batch()
    ..update(doc, roster)
    ..delete(invite);
  await batch.commit();
}
