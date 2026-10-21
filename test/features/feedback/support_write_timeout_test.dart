import 'dart:async';

import 'package:easy_plate/features/feedback/domain/entities/feedback_entity.dart';
import 'package:easy_plate/features/feedback/domain/repositories/feedback_repository.dart';
import 'package:easy_plate/features/feedback/domain/usecases/send_feedback_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

/// Firestore offline: a write that is queued and never acknowledged; or one
/// refused outright.
class _Repo implements FeedbackRepository {
  Object? refusal;
  final sent = <String>[];

  Future<void> _write(String what) {
    sent.add(what);
    if (refusal case final e?) return Future.error(e);
    return Completer<void>().future;
  }

  @override
  Future<void> send(FeedbackEntity feedback) => _write('send:${feedback.id}');
  @override
  Future<void> addFollowUp(String feedbackId, String text) =>
      _write('follow:$feedbackId:$text');
  @override
  noSuchMethod(Invocation i) => throw UnimplementedError('${i.memberName}');
}

void main() {
  const quick = Duration(milliseconds: 20);

  test('a message queued offline does not hold the form', () async {
    final repo = _Repo();
    final id = await SendFeedbackUseCase(repo, writeTimeout: quick)(
      type: FeedbackType.bug,
      message: 'hi',
      authorUid: 'u',
      authorName: 'U',
    );
    expect(repo.sent, ['send:$id']);
  });

  test('a follow-up queued offline does not hold the composer', () async {
    final repo = _Repo();
    await ContinueFeedbackUseCase(
      repo,
      writeTimeout: quick,
    ).followUp('f1', ' more ');
    expect(repo.sent, ['follow:f1:more']);
  });

  test('a refused write is still an error', () async {
    final repo = _Repo()..refusal = StateError('permission-denied');
    expect(
      ContinueFeedbackUseCase(repo, writeTimeout: quick).followUp('f1', 'x'),
      throwsStateError,
    );
  });
}
