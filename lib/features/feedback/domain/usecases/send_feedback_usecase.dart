import 'package:uuid/uuid.dart';

import '../entities/feedback_entity.dart';
import '../repositories/feedback_repository.dart';

class SendFeedbackUseCase {
  final FeedbackRepository repository;
  static const _uuid = Uuid();

  SendFeedbackUseCase(this.repository);

  /// Opens a conversation and returns its id, so the screen can go on to
  /// the chat.
  Future<String> call({
    required FeedbackType type,
    required String message,
    required String authorUid,
    required String authorName,
    String? authorEmail,
    String? appVersion,
    Map<String, String> details = const {},
    FeedbackSource source = FeedbackSource.app,
  }) async {
    final text = message.trim();
    if (text.isEmpty) throw ArgumentError('a message is required');
    final id = _uuid.v4();
    await repository.send(
      FeedbackEntity(
        id: id,
        type: type,
        message: text,
        authorUid: authorUid,
        authorName: authorName,
        authorEmail: authorEmail,
        appVersion: appVersion,
        details: details,
        source: source,
        createdAt: DateTime.now(),
      ),
    );
    return id;
  }
}

/// The user's side of a conversation after it is opened.
class ContinueFeedbackUseCase {
  final FeedbackRepository repository;

  ContinueFeedbackUseCase(this.repository);

  Future<void> followUp(String feedbackId, String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) throw ArgumentError('an empty message');
    return repository.addFollowUp(feedbackId, trimmed);
  }

  Future<void> seen(String feedbackId) =>
      repository.markSeenByUser(feedbackId);
}
