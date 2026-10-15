import '../entities/feedback_entity.dart';

abstract class FeedbackRepository {
  Future<void> send(FeedbackEntity feedback);

  /// Newest first. Readable by the administrator only — the rules refuse
  /// everyone else.
  Future<List<FeedbackEntity>> getAll({int limit = 200});

  /// The same list, kept live, so the unread badge moves as messages arrive.
  Stream<List<FeedbackEntity>> watchAll({int limit = 500});

  /// The account's own conversations, newest activity first.
  Stream<List<FeedbackEntity>> watchMine(String uid);

  /// One conversation, live; null once it is deleted.
  Stream<FeedbackEntity?> watchOne(String feedbackId);

  /// The user writes again in their own conversation. Brings it back to
  /// the administrator as unread.
  Future<void> addFollowUp(String feedbackId, String text);

  /// The user opened the conversation: the administrator's answer is seen.
  Future<void> markSeenByUser(String feedbackId);

  Future<void> setRead(String feedbackId, bool read);

  /// Ends the conversation (or opens it again): closed, the user can read
  /// it under "closed" but not write, and it leaves the open inbox.
  Future<void> setClosed(String feedbackId, bool closed);

  Future<void> markAllRead(Iterable<String> feedbackIds);

  Future<void> delete(String feedbackId);

  /// Answers the person who wrote the message: the reply is kept on the
  /// message and dropped into their notifications inbox, signed by the
  /// administrator's uid.
  Future<void> reply({
    required FeedbackEntity feedback,
    required String text,
    required String fromUid,
  });
}
