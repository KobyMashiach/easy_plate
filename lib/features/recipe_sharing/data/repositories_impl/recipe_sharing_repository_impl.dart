import '../../../../core/constants/app_enums.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../my_recipes/domain/entities/recipe_entity.dart';
import '../../domain/entities/collab_recipe_entity.dart';
import '../../domain/entities/share_invite_entity.dart';
import '../../domain/repositories/recipe_sharing_repository.dart';
import '../datasources/recipe_sharing_remote_datasource.dart';

class RecipeSharingRepositoryImpl implements RecipeSharingRepository {
  final RecipeSharingRemoteDataSource remoteDataSource;

  RecipeSharingRepositoryImpl({required this.remoteDataSource});

  @override
  Future<String> ensureCollab(RecipeEntity recipe, {required String ownerUid}) async {
    if (recipe.collabId case final existing?) return existing;
    return remoteDataSource.createCollab(recipe, ownerUid: ownerUid);
  }

  @override
  Future<void> invite({
    required String collabId,
    required String recipeTitle,
    required String ownerUid,
    required String targetUid,
    required CollabRole role,
  }) =>
      remoteDataSource.invite(
        collabId: collabId,
        recipeTitle: recipeTitle,
        ownerUid: ownerUid,
        targetUid: targetUid,
        role: role,
      );

  @override
  Future<List<ShareInviteEntity>> incomingInvites(String uid) =>
      remoteDataSource.incomingInvites(uid);

  @override
  Future<List<ShareInviteEntity>> outgoingInvites(String ownerUid) =>
      remoteDataSource.outgoingInvites(ownerUid);

  @override
  Future<CollabRecipeEntity?> getCollab(String collabId) => remoteDataSource.getCollab(collabId);

  @override
  Future<CollabRecipeEntity> acceptInvite(ShareInviteEntity invite) async {
    await remoteDataSource.setInviteStatus(invite.id, ShareInviteStatus.accepted);
    await remoteDataSource.joinCollab(invite.collabId, uid: invite.targetUid, role: invite.role);
    final collab = await remoteDataSource.getCollab(invite.collabId);
    if (collab == null) {
      // The owner deleted the recipe between sending and accepting.
      throw const AppException(AppErrorType.notFound, message: 'collab-missing');
    }
    return collab;
  }

  @override
  Future<void> declineInvite(ShareInviteEntity invite) =>
      remoteDataSource.setInviteStatus(invite.id, ShareInviteStatus.declined);

  @override
  Future<void> writeCollab(String collabId, RecipeEntity recipe, {required String byUid}) =>
      remoteDataSource.writeCollab(collabId, recipe, byUid: byUid);

  @override
  Future<List<CollabRecipeEntity>> collabsOwnedBy(String uid) =>
      remoteDataSource.collabsOwnedBy(uid);

  @override
  Future<List<CollabRecipeEntity>> collabsSharedWith(String uid) =>
      remoteDataSource.collabsSharedWith(uid);

  @override
  Future<void> removeMember(String collabId, String memberUid) =>
      remoteDataSource.removeMember(collabId, memberUid);
}
