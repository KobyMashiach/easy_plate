import '../../../../core/constants/app_enums.dart';
import '../../../my_recipes/domain/entities/recipe_entity.dart';
import '../entities/collab_recipe_entity.dart';
import '../entities/share_invite_entity.dart';

abstract class RecipeSharingRepository {
  /// Makes [recipe] shareable: creates the shared document if it has none and
  /// returns its id. Idempotent for a recipe that is already shared.
  Future<String> ensureCollab(RecipeEntity recipe, {required String ownerUid});

  /// Writes the invite and the target's in-app notification together.
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

  /// Accepts on the invite and joins the recipe's members, in that order —
  /// the rules check the accepted invite before admitting the member.
  Future<CollabRecipeEntity> acceptInvite(ShareInviteEntity invite);
  Future<void> declineInvite(ShareInviteEntity invite);

  /// A save by the owner or an editor. Bumps `updatedAt`, which is how a cache
  /// on another device knows to refresh.
  Future<void> writeCollab(String collabId, RecipeEntity recipe, {required String byUid});

  Future<List<CollabRecipeEntity>> collabsOwnedBy(String uid);
  Future<List<CollabRecipeEntity>> collabsSharedWith(String uid);

  /// The owner revoking someone, or a member leaving.
  Future<void> removeMember(String collabId, String memberUid);
}
