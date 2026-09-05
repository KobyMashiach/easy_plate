/// A discussion thread's opening message.
class ForumPostEntity {
  final String id;
  final String title;
  final String body;
  final String authorUid;
  final String authorName;
  final String? authorPhotoUrl;
  final DateTime createdAt;

  /// Denormalised so the list does not have to count a subcollection per row.
  final int replyCount;

  const ForumPostEntity({
    required this.id,
    required this.title,
    required this.body,
    required this.authorUid,
    required this.authorName,
    required this.createdAt,
    this.authorPhotoUrl,
    this.replyCount = 0,
  });
}
