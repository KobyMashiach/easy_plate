import '../../../../core/constants/app_enums.dart';

/// The shared source of truth for a book or a meal plan that lives in more
/// than one account. Local books and plans with a matching `collabId` are
/// caches of this, the same way local recipes cache a `CollabRecipeEntity`.
///
/// The recipes inside are not embedded: each is its own shared recipe, and
/// the container refers to it by that recipe's collab id. A member of the
/// container is invited into every one of those recipes alongside it, so
/// their copy of the book or plan resolves to real recipes on their side.
class CollabContainerEntity {
  final String id;
  final CollabKind kind;
  final String ownerUid;

  /// Everyone besides the owner, with what they may do.
  final Map<String, CollabRole> members;
  final String title;

  /// The kind-specific body, as written by [ContainerCodec]. Kept as a map so
  /// the datasource does not have to know one shape per kind.
  final Map<String, dynamic> content;
  final DateTime updatedAt;
  final String? updatedBy;

  const CollabContainerEntity({
    required this.id,
    required this.kind,
    required this.ownerUid,
    required this.members,
    required this.title,
    required this.content,
    required this.updatedAt,
    this.updatedBy,
  });

  CollabRole roleOf(String uid) =>
      uid == ownerUid ? CollabRole.owner : (members[uid] ?? CollabRole.viewer);

  /// Everyone in the share, the owner included, with their role.
  Map<String, CollabRole> get participants => {
    ownerUid: CollabRole.owner,
    ...members,
  };

  /// The shared recipes this container points at, in no particular order.
  Set<String> get recipeCollabIds => collabIdsIn(content);

  static Set<String> collabIdsIn(Map<String, dynamic> content) {
    final ids = <String>{};
    for (final raw in (content['recipes'] as List?) ?? const []) {
      if (raw is Map && raw['collabId'] is String) {
        ids.add(raw['collabId'] as String);
      }
    }
    for (final meal in (content['meals'] as List?) ?? const []) {
      if (meal is! Map) continue;
      for (final item in (meal['items'] as List?) ?? const []) {
        if (item is Map && item['recipeCollabId'] is String) {
          ids.add(item['recipeCollabId'] as String);
        }
      }
    }
    return ids;
  }
}
