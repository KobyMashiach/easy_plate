import '../entities/feedback_entity.dart';
import '../repositories/feedback_repository.dart';

/// The administrator's side of the inbox: read marks, answers, removal.
class ManageFeedbackUseCase {
  final FeedbackRepository repository;

  ManageFeedbackUseCase(this.repository);

  Future<void> setRead(FeedbackEntity feedback, bool read) =>
      repository.setRead(feedback.id, read);

  /// Marks every unread message in [all] read; already-read ones are left
  /// alone so their original `readAt` survives.
  Future<void> markAllRead(Iterable<FeedbackEntity> all) =>
      repository.markAllRead([
        for (final f in all)
          if (!f.read) f.id,
      ]);

  Future<void> delete(FeedbackEntity feedback) =>
      repository.delete(feedback.id);

  Future<void> reply(
    FeedbackEntity feedback,
    String text, {
    required String fromUid,
  }) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) throw ArgumentError('an empty reply');
    return repository.reply(
      feedback: feedback,
      text: trimmed,
      fromUid: fromUid,
    );
  }
}
