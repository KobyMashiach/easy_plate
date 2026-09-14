import 'package:uuid/uuid.dart';

import '../entities/feedback_entity.dart';
import '../repositories/feedback_repository.dart';

class SendFeedbackUseCase {
  final FeedbackRepository repository;
  static const _uuid = Uuid();

  SendFeedbackUseCase(this.repository);

  Future<void> call({
    required FeedbackType type,
    required String message,
    required String authorUid,
    required String authorName,
    String? authorEmail,
    String? appVersion,
  }) {
    final text = message.trim();
    if (text.isEmpty) throw ArgumentError('a message is required');
    return repository.send(FeedbackEntity(
      id: _uuid.v4(),
      type: type,
      message: text,
      authorUid: authorUid,
      authorName: authorName,
      authorEmail: authorEmail,
      appVersion: appVersion,
      createdAt: DateTime.now(),
    ));
  }
}
