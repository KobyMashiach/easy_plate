import '../entities/share_invite_entity.dart';
import '../repositories/recipe_sharing_repository.dart';

class GetShareInvitesUseCase {
  final RecipeSharingRepository repository;
  GetShareInvitesUseCase(this.repository);

  Future<List<ShareInviteEntity>> incoming(String uid) => repository.incomingInvites(uid);
  Future<List<ShareInviteEntity>> outgoing(String uid) => repository.outgoingInvites(uid);
}
