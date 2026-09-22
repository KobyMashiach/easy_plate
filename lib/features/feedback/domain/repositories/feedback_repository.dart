import '../entities/feedback_entity.dart';

abstract class FeedbackRepository {
  Future<void> send(FeedbackEntity feedback);

  /// Newest first. Readable by the administrator only — the rules refuse
  /// everyone else.
  Future<List<FeedbackEntity>> getAll({int limit = 200});

  /// The same list, kept live, so the unread badge moves as messages arrive.
  Stream<List<FeedbackEntity>> watchAll({int limit = 500});

  Future<void> setRead(String feedbackId, bool read);

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
