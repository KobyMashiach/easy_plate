import '../repositories/recipe_sharing_repository.dart';

class RemoveCollabMemberUseCase {
  final RecipeSharingRepository repository;
  RemoveCollabMemberUseCase(this.repository);

  /// [revokeInvite]: the owner removing [memberUid] (not the member
  /// leaving) — their invite is deleted too, so they can't rejoin with it.
  Future<void> call(
    String collabId,
    String memberUid, {
    bool revokeInvite = false,
  }) => repository.removeMember(
    collabId,
    memberUid,
    revokeInvite: revokeInvite,
  );
}
