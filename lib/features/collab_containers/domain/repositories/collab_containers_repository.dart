import '../../../../core/constants/app_enums.dart';
import '../../../recipe_sharing/domain/entities/share_invite_entity.dart';
import '../entities/collab_container_entity.dart';

/// A shared recipe to invite someone into alongside a book or plan.
typedef RecipeInvite = ({String collabId, String title});

abstract class CollabContainersRepository {
  Future<String> create({
    required CollabKind kind,
    required String title,
    required Map<String, dynamic> content,
    required String ownerUid,
  });

  Future<CollabContainerEntity?> get(String id);

  Future<void> write(
    String id, {
    required String title,
    required Map<String, dynamic> content,
    required String byUid,
  });

  Future<void> delete(String id);

  /// The container invite, its notification, and a silent invite into each
  /// of [recipes] for the same person — one batch, so an invite to a book
  /// whose recipes cannot be reached is never written.
  Future<void> invite({
    required CollabContainerEntity container,
    required String targetUid,
    required CollabRole role,
    required List<RecipeInvite> recipes,
  });

  /// Silent recipe invites only: for a recipe added to an already shared
  /// container, so every current participant is let into it.
  Future<void> inviteToRecipes({
    required String containerId,
    required Map<String, CollabRole> participants,
    required List<RecipeInvite> recipes,
    required String byUid,
  });

  /// The invite this account holds for a shared recipe, whatever its state,
  /// or null when none was ever sent.
  Future<ShareInviteEntity?> recipeInvite({
    required String collabId,
    required String uid,
  });

  /// Accepts on the invite and joins the container, in that order — the
  /// rules check the accepted invite before admitting the member.
  Future<CollabContainerEntity> acceptInvite(ShareInviteEntity invite);
  Future<void> declineInvite(ShareInviteEntity invite);

  Future<List<CollabContainerEntity>> ownedBy(String uid);
  Future<List<CollabContainerEntity>> sharedWith(String uid);

  /// The owner revoking someone, or a member leaving.
  Future<void> removeMember(String containerId, String memberUid);
}
