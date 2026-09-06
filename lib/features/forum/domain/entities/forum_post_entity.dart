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

  /// Replaces the display fields with the author's live profile. Kept as a
  /// dedicated method rather than a general copyWith: the author's *identity*
  /// (`authorUid`) is never rewritten, only how it is shown.
  ForumPostEntity withAuthor({required String name, String? photoUrl}) {
    return ForumPostEntity(
      id: id,
      title: title,
      body: body,
      authorUid: authorUid,
      authorName: name,
      authorPhotoUrl: photoUrl,
      createdAt: createdAt,
      replyCount: replyCount,
    );
  }
}
