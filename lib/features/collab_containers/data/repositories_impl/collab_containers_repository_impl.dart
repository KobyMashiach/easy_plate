import '../../../../core/constants/app_enums.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../recipe_sharing/domain/entities/share_invite_entity.dart';
import '../../domain/entities/collab_container_entity.dart';
import '../../domain/repositories/collab_containers_repository.dart';
import '../datasources/collab_containers_remote_datasource.dart';

class CollabContainersRepositoryImpl implements CollabContainersRepository {
  final CollabContainersFirestoreDataSource remote;

  CollabContainersRepositoryImpl({required this.remote});

  @override
  Future<String> create({
    required CollabKind kind,
    required String title,
    required Map<String, dynamic> content,
    required String ownerUid,
  }) => remote.create(
    kind: kind,
    title: title,
    content: content,
    ownerUid: ownerUid,
  );

  @override
  Future<CollabContainerEntity?> get(String id) => remote.get(id);

  @override
  Future<void> write(
    String id, {
    required String title,
    required Map<String, dynamic> content,
    required String byUid,
  }) => remote.write(id, title: title, content: content, byUid: byUid);

  @override
  Future<void> delete(String id) => remote.delete(id);

  @override
  Future<void> invite({
    required CollabContainerEntity container,
    required String targetUid,
    required CollabRole role,
    required List<RecipeInvite> recipes,
  }) => remote.invite(
    container: container,
    targetUid: targetUid,
    role: role,
    recipes: recipes,
  );

  @override
  Future<void> inviteToRecipes({
    required String containerId,
    required Map<String, CollabRole> participants,
    required List<RecipeInvite> recipes,
    required String byUid,
  }) => remote.inviteToRecipes(
    containerId: containerId,
    participants: participants,
    recipes: recipes,
    byUid: byUid,
  );

  @override
  Future<ShareInviteEntity?> recipeInvite({
    required String collabId,
    required String uid,
  }) => remote.recipeInvite(collabId: collabId, uid: uid);

  @override
  Future<CollabContainerEntity> acceptInvite(ShareInviteEntity invite) async {
    await remote.setInviteStatus(invite.id, ShareInviteStatus.accepted);
    await remote.join(
      invite.collabId,
      uid: invite.targetUid,
      role: invite.role,
    );
    final container = await remote.get(invite.collabId);
    if (container == null) {
      // The owner deleted it between sending and accepting.
      throw const AppException(
        AppErrorType.notFound,
        message: 'collab-missing',
      );
    }
    return container;
  }

  @override
  Future<void> declineInvite(ShareInviteEntity invite) =>
      remote.setInviteStatus(invite.id, ShareInviteStatus.declined);

  @override
  Future<List<CollabContainerEntity>> ownedBy(String uid) =>
      remote.ownedBy(uid);

  @override
  Future<List<CollabContainerEntity>> sharedWith(String uid) =>
      remote.sharedWith(uid);

  @override
  Future<void> removeMember(String containerId, String memberUid) =>
      remote.removeMember(containerId, memberUid);
}
