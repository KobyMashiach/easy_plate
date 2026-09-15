import '../../../../core/constants/app_enums.dart';

/// An offer to join a shared recipe. Its id is `{collabId}_{targetUid}` on
/// purpose: the rules can then find it from the recipe when the target adds
/// themselves as a member, and verify the role they claim is the one offered.
class ShareInviteEntity {
  final String id;
  final String collabId;
  final String recipeTitle;
  final String ownerUid;
  final String targetUid;
  final CollabRole role;
  final ShareInviteStatus status;
  final DateTime createdAt;

  /// What is being shared. Older invites carry no kind and are recipes.
  final CollabKind kind;

  /// The shared book or plan this recipe invite came with, for a recipe
  /// invited as part of one. Such an invite is answered by answering the
  /// container's, never on its own, so the inbox does not list it.
  final String? via;

  const ShareInviteEntity({
    required this.id,
    required this.collabId,
    required this.recipeTitle,
    required this.ownerUid,
    required this.targetUid,
    required this.role,
    required this.status,
    required this.createdAt,
    this.kind = CollabKind.recipe,
    this.via,
  });

  static String idFor({required String collabId, required String targetUid}) =>
      '${collabId}_$targetUid';

  bool get isPending => status == ShareInviteStatus.pending;
}
