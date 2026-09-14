/// What a message from a user is about. Stored by name.
enum FeedbackType { bug, suggestion }

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

  const FeedbackEntity({
    required this.id,
    required this.type,
    required this.message,
    required this.authorUid,
    required this.authorName,
    required this.createdAt,
    this.authorEmail,
    this.appVersion,
  });
}
