import '../entities/feedback_entity.dart';

abstract class FeedbackRepository {
  Future<void> send(FeedbackEntity feedback);

  /// Newest first. Readable by the administrator only — the rules refuse
  /// everyone else.
  Future<List<FeedbackEntity>> getAll({int limit = 200});
}
