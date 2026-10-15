/// Why the user is writing. Stored by name; the first two predate the
/// others, which arrived with the support chat (2026-10-15).
enum FeedbackType { bug, suggestion, account, billing, sharing, recipes, other }

/// Where a message was opened from: the support screen's form, or Shefi
/// on the user's behalf.
enum FeedbackSource { app, shefi }

/// One answer the administrator sent back, as kept on the message.
class FeedbackReply {
  final String text;
  final DateTime at;

  const FeedbackReply({required this.text, required this.at});
}

/// One line of the conversation, whoever wrote it: the opening message,
/// a follow-up by the user, or an answer by the administrator.
class FeedbackMessage {
  final String text;
  final DateTime at;
  final bool fromAdmin;

  const FeedbackMessage({
    required this.text,
    required this.at,
    required this.fromAdmin,
  });
}

/// A support conversation: opened on the support screen (or through Shefi)
/// with a reason and a message, continued by the user with follow-ups and
/// by the administrator with replies, signed by the account that wrote it.
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
  /// this existed carry no flag and count as unread. A follow-up by the
  /// user clears it again, so the conversation comes back to the top.
  final bool read;
  final DateTime? readAt;
  final List<FeedbackReply> replies;

  /// What the user wrote after the opening message.
  final List<FeedbackReply> followUps;

  /// The same lines the mail and WhatsApp signatures carry (name, email,
  /// phone, account id, version, device, language), kept for the
  /// administrator's eyes only — the chat never shows them to the writer.
  final Map<String, String> details;

  /// The administrator answered and the user has not opened the
  /// conversation since.
  final bool userUnread;
  final FeedbackSource source;

  /// The last line written by either side.
  final DateTime updatedAt;

  /// Closed by the administrator: the conversation is over, the user's
  /// chat is locked (read only) and it is listed under "closed".
  final bool closed;
  final DateTime? closedAt;

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
    this.followUps = const [],
    this.details = const {},
    this.userUnread = false,
    this.source = FeedbackSource.app,
    this.closed = false,
    this.closedAt,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? createdAt;

  bool get answered => replies.isNotEmpty;

  /// The whole conversation in the order it was written.
  List<FeedbackMessage> get thread => [
    FeedbackMessage(text: message, at: createdAt, fromAdmin: false),
    for (final r in followUps)
      FeedbackMessage(text: r.text, at: r.at, fromAdmin: false),
    for (final r in replies)
      FeedbackMessage(text: r.text, at: r.at, fromAdmin: true),
  ]..sort((a, b) => a.at.compareTo(b.at));

  /// The newest line, for the conversations list.
  FeedbackMessage get last => thread.last;

  /// The opening of the message, for a reply notification that quotes it.
  String get excerpt => excerptOf(message);

  static String excerptOf(String text) {
    final flat = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    return flat.length <= 80 ? flat : '${flat.substring(0, 77)}…';
  }
}
