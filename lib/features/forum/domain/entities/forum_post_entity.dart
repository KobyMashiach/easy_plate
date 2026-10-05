import 'package:equatable/equatable.dart';

/// A discussion thread's opening message.
///
/// Value equality matters here: the feed is fed by a live Firestore stream,
/// and bloc drops a state equal to the current one. Without `==` every
/// snapshot — including the ones that changed nothing the viewer can see —
/// would rebuild the whole list.
class ForumPostEntity extends Equatable {
  final String id;
  final String title;
  final String body;
  final String authorUid;
  final String authorName;
  final String? authorPhotoUrl;
  final DateTime createdAt;

  /// Denormalised so the list does not have to count a subcollection per row.
  final int replyCount;
  final int likeCount;

  /// Whether the signed-in user has liked this thread. Resolved per viewer, so
  /// it is not part of the stored document.
  final bool likedByMe;

  const ForumPostEntity({
    required this.id,
    required this.title,
    required this.body,
    required this.authorUid,
    required this.authorName,
    required this.createdAt,
    this.authorPhotoUrl,
    this.replyCount = 0,
    this.likeCount = 0,
    this.likedByMe = false,
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
      likeCount: likeCount,
      likedByMe: likedByMe,
    );
  }

  /// The same thread with this viewer's like flipped, counter included — what
  /// the list shows while the write is still in flight.
  ForumPostEntity withLikeToggled() {
    return ForumPostEntity(
      id: id,
      title: title,
      body: body,
      authorUid: authorUid,
      authorName: authorName,
      authorPhotoUrl: authorPhotoUrl,
      createdAt: createdAt,
      replyCount: replyCount,
      likeCount: likeCount + (likedByMe ? -1 : 1),
      likedByMe: !likedByMe,
    );
  }

  /// The same thread as the server now has it, but with this viewer's like as
  /// the app knows it. Used when a live snapshot lands while a like of the
  /// viewer's own is still on its way up, so the heart does not flicker back.
  ForumPostEntity withViewerLike(bool liked) {
    if (liked == likedByMe) return this;
    return ForumPostEntity(
      id: id,
      title: title,
      body: body,
      authorUid: authorUid,
      authorName: authorName,
      authorPhotoUrl: authorPhotoUrl,
      createdAt: createdAt,
      replyCount: replyCount,
      likeCount: likeCount,
      likedByMe: liked,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    body,
    authorUid,
    authorName,
    authorPhotoUrl,
    createdAt,
    replyCount,
    likeCount,
    likedByMe,
  ];
}
