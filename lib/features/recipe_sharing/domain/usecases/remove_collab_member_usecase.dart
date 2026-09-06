import '../repositories/recipe_sharing_repository.dart';

class RemoveCollabMemberUseCase {
  final RecipeSharingRepository repository;
  RemoveCollabMemberUseCase(this.repository);

  Future<void> call(String collabId, String memberUid) =>
      repository.removeMember(collabId, memberUid);
}
