import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_enums.dart';
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
  Future<void> joinCollab(String collabId, {required String uid, required CollabRole role});
  Future<void> writeCollab(String collabId, RecipeEntity recipe, {required String byUid});
  Future<List<CollabRecipeEntity>> collabsOwnedBy(String uid);
  Future<List<CollabRecipeEntity>> collabsSharedWith(String uid);
  Future<void> removeMember(String collabId, String memberUid);
}

class RecipeSharingFirestoreDataSource implements RecipeSharingRemoteDataSource {
  static const collabs = 'collab_recipes';
  static const invites = 'share_invites';
  static const notifications = 'notifications';
  static const _uuid = Uuid();

  final FirebaseFirestore _firestore;

  RecipeSharingFirestoreDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

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
        // The photo travels as its Storage path plus the file name to cache it
        // under. Before this the picture was simply left behind, and the other
        // account's copy of a shared recipe was permanently blank.
        'imageFileName': recipe.imageFileName,
        'imageStoragePath': recipe.imageStoragePath,
      };

  RecipeEntity _recipeFrom(String id, Map<String, dynamic> data, DateTime createdAt) {
    return RecipeEntity(
      id: id,
      title: (data['title'] as String?) ?? '',
      prepTimeMinutes: (data['prepTimeMinutes'] as num?)?.toInt(),
      cookTimeMinutes: (data['cookTimeMinutes'] as num?)?.toInt(),
      ingredients: ((data['ingredients'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map((raw) => RecipeIngredientEntity(
                name: (raw['name'] as String?) ?? '',
                amount: (raw['amount'] as num?)?.toDouble(),
                unit: MeasurementUnit.values.firstWhere(
                  (u) => u.name == raw['unit'],
                  orElse: () => MeasurementUnit.unspecified,
                ),
              ))
          .toList(),
      steps: ((data['steps'] as List?) ?? const []).whereType<String>().toList(),
      dietaryTags: ((data['dietaryTags'] as List?) ?? const [])
          .whereType<String>()
          .map((n) => DietaryPreference.values.where((d) => d.name == n).firstOrNull)
          .nonNulls
          .toList(),
      imageFileName: data['imageFileName'] as String?,
      imageStoragePath: data['imageStoragePath'] as String?,
      createdAt: createdAt,
    );
  }

  CollabRecipeEntity _collabFrom(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final rawMembers = (data['members'] as Map?) ?? const {};
    return CollabRecipeEntity(
      id: doc.id,
      ownerUid: (data['ownerUid'] as String?) ?? '',
      members: {
        // Null-aware value: an unknown role name drops the entry rather than
        // inventing a role for it.
        for (final entry in rawMembers.entries)
          entry.key as String: ?CollabRole.values.where((r) => r.name == entry.value).firstOrNull,
      },
      recipe: _recipeFrom(doc.id, data, createdAt),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? createdAt,
      updatedBy: data['updatedBy'] as String?,
    );
  }

  @override
  Future<String> createCollab(RecipeEntity recipe, {required String ownerUid}) async {
    final id = _uuid.v4();
    await _collab(id).set({
      ..._recipeFields(recipe),
      'ownerUid': ownerUid,
      'members': <String, String>{},
      // Parallel array of member uids, because a map key cannot be queried
      // with `arrayContains` and the rules need a provable "shared with me".
      'memberUids': <String>[],
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'updatedBy': ownerUid,
    });
    return id;
  }

  /// Invite and notification in one batch: a notification for an invite that
  /// failed to write, or the reverse, would be a dangling promise.
  @override
  Future<void> invite({
    required String collabId,
    required String recipeTitle,
    required String ownerUid,
    required String targetUid,
    required CollabRole role,
  }) {
    final inviteId = ShareInviteEntity.idFor(collabId: collabId, targetUid: targetUid);
    final batch = _firestore.batch();
    batch.set(_firestore.collection(invites).doc(inviteId), {
      'collabId': collabId,
      'recipeTitle': recipeTitle,
      'ownerUid': ownerUid,
      'targetUid': targetUid,
      'role': role.name,
      'status': ShareInviteStatus.pending.name,
      'createdAt': Timestamp.now(),
    });
    batch.set(
      _firestore.collection(notifications).doc(targetUid).collection('items').doc(inviteId),
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
    return batch.commit();
  }

  ShareInviteEntity _inviteFrom(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
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
    );
  }

  @override
  Future<List<ShareInviteEntity>> incomingInvites(String uid) async {
    final snapshot = await _firestore
        .collection(invites)
        .where('targetUid', isEqualTo: uid)
        .where('status', isEqualTo: ShareInviteStatus.pending.name)
        .get();
    return snapshot.docs.map(_inviteFrom).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<List<ShareInviteEntity>> outgoingInvites(String ownerUid) async {
    final snapshot =
        await _firestore.collection(invites).where('ownerUid', isEqualTo: ownerUid).get();
    return snapshot.docs.map(_inviteFrom).toList()
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
  Future<void> joinCollab(String collabId, {required String uid, required CollabRole role}) {
    return _collab(collabId).update({
      'members.$uid': role.name,
      'memberUids': FieldValue.arrayUnion([uid]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> writeCollab(String collabId, RecipeEntity recipe, {required String byUid}) {
    return _collab(collabId).update({
      ..._recipeFields(recipe),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': byUid,
    });
  }

  @override
  Future<List<CollabRecipeEntity>> collabsOwnedBy(String uid) async {
    final snapshot =
        await _firestore.collection(collabs).where('ownerUid', isEqualTo: uid).get();
    return snapshot.docs.map(_collabFrom).toList();
  }

  @override
  Future<List<CollabRecipeEntity>> collabsSharedWith(String uid) async {
    final snapshot = await _firestore
        .collection(collabs)
        .where('memberUids', arrayContains: uid)
        .get();
    return snapshot.docs.map(_collabFrom).toList();
  }

  @override
  Future<void> removeMember(String collabId, String memberUid) {
    return _collab(collabId).update({
      'members.$memberUid': FieldValue.delete(),
      'memberUids': FieldValue.arrayRemove([memberUid]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
