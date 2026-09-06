import '../../../../core/constants/app_enums.dart';
import '../../../my_recipes/domain/entities/recipe_entity.dart';

/// The shared source of truth for a recipe that lives in more than one
/// account. Local recipes with a matching `collabId` are caches of this.
class CollabRecipeEntity {
  final String id;
  final String ownerUid;

  /// Everyone besides the owner, with what they may do.
  final Map<String, CollabRole> members;
  final RecipeEntity recipe;
  final DateTime updatedAt;
  final String? updatedBy;

  const CollabRecipeEntity({
    required this.id,
    required this.ownerUid,
    required this.members,
    required this.recipe,
    required this.updatedAt,
    this.updatedBy,
  });

  CollabRole roleOf(String uid) =>
      uid == ownerUid ? CollabRole.owner : (members[uid] ?? CollabRole.viewer);
}
