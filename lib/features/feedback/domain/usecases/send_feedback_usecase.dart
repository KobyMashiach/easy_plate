import 'dart:async';

import 'package:uuid/uuid.dart';

import '../entities/feedback_entity.dart';
import '../repositories/feedback_repository.dart';

/// How long a support write is waited on before it counts as queued.
/// Firestore holds a write made offline and completes its future only when
/// a server takes it, so an unbounded await kept the composer locked with a
/// spinner for as long as the phone had no connection. The write still goes
/// out once it can; a real refusal arrives before this.
const supportWriteTimeout = Duration(seconds: 8);

/// [write], or nothing more when it is merely still queued after [timeout].
Future<void> _queuedAfter(Future<void> write, Duration timeout) async {
  try {
    await write.timeout(timeout);
  } on TimeoutException {
    // Queued offline, not refused.
  }
}

class SendFeedbackUseCase {
  final FeedbackRepository repository;
  final Duration writeTimeout;
  static const _uuid = Uuid();

  SendFeedbackUseCase(
    this.repository, {
    this.writeTimeout = supportWriteTimeout,
  });

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
    await _queuedAfter(
      repository.send(
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
      ),
      writeTimeout,
    );
    return id;
  }
}

/// The user's side of a conversation after it is opened.
class ContinueFeedbackUseCase {
  final FeedbackRepository repository;
  final Duration writeTimeout;

  ContinueFeedbackUseCase(
    this.repository, {
    this.writeTimeout = supportWriteTimeout,
  });

  Future<void> followUp(String feedbackId, String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) throw ArgumentError('an empty message');
    return _queuedAfter(
      repository.addFollowUp(feedbackId, trimmed),
      writeTimeout,
    );
  }

  Future<void> seen(String feedbackId) => repository.markSeenByUser(feedbackId);
}
