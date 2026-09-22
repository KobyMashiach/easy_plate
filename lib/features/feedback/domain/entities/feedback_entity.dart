/// What a message from a user is about. Stored by name.
enum FeedbackType { bug, suggestion }

/// One answer the administrator sent back, as kept on the message.
class FeedbackReply {
  final String text;
  final DateTime at;

  const FeedbackReply({required this.text, required this.at});
}

/// A message left on the support screen: a bug or a suggestion, signed by
/// the account that wrote it.
class FeedbackEntity {
  final String id;
  final FeedbackType type;
  final String message;
  final String authorUid;
  final String authorName;
  final String? authorEmail;

  /// The app version the message was written on, so a bug report can be read
  /// against the build it happened in.
  final String? appVersion;
  final DateTime createdAt;

  /// Marked by the administrator, and reversible. Messages written before
  /// this existed carry no flag and count as unread.
  final bool read;
  final DateTime? readAt;
  final List<FeedbackReply> replies;

  const FeedbackEntity({
    required this.id,
    required this.type,
    required this.message,
    required this.authorUid,
    required this.authorName,
    required this.createdAt,
    this.authorEmail,
    this.appVersion,
    this.read = false,
    this.readAt,
    this.replies = const [],
  });

  bool get answered => replies.isNotEmpty;

  /// The opening of the message, for a reply notification that quotes it.
  String get excerpt {
    final flat = message.replaceAll(RegExp(r'\s+'), ' ').trim();
    return flat.length <= 80 ? flat : '${flat.substring(0, 77)}…';
  }
}
