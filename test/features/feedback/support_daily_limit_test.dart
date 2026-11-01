import 'dart:async';

import 'package:easy_plate/features/feedback/data/datasources/feedback_remote_datasource.dart';
import 'package:easy_plate/features/feedback/domain/entities/feedback_entity.dart';
import 'package:easy_plate/features/feedback/domain/repositories/feedback_repository.dart';
import 'package:easy_plate/features/feedback/domain/usecases/send_feedback_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

/// One conversation as the listener delivers it, verdict or not.
class _Repo implements FeedbackRepository {
  final StreamController<FeedbackEntity?> one = StreamController();

  @override
  Stream<FeedbackEntity?> watchOne(String feedbackId) => one.stream;
  @override
  noSuchMethod(Invocation i) => throw UnimplementedError('${i.memberName}');
}

FeedbackEntity _doc(Map<String, dynamic> extra) =>
    FeedbackFirestoreDataSource.fromData('f1', {
      'type': 'bug',
      'message': 'hi',
      'authorUid': 'u',
      ...extra,
    });

void main() {
  const quick = Duration(milliseconds: 50);

  test('the server verdict is read from the document', () {
    final fresh = _doc({});
    expect(fresh.judged, isFalse);
    expect(fresh.overDailyLimit, isFalse);
    final admitted = _doc({'admitted': true});
    expect(admitted.judged, isTrue);
    expect(admitted.overDailyLimit, isFalse);
    final refused = _doc({'rejected': 'daily_limit', 'status': 'closed'});
    expect(refused.judged, isTrue);
    expect(refused.overDailyLimit, isTrue);
    expect(refused.closed, isTrue);
    // A reason this build does not know is a verdict, not a daily limit.
    expect(_doc({'rejected': 'other'}).overDailyLimit, isFalse);
    expect(_doc({'rejected': 42}).judged, isFalse);
  });

  test('a refusal stamped after the write is reported', () async {
    final repo = _Repo();
    final verdict = refusedForDailyLimit(repo, 'f1', timeout: quick * 10);
    repo.one.add(_doc({}));
    repo.one.add(_doc({'rejected': 'daily_limit', 'status': 'closed'}));
    expect(await verdict, isTrue);
  });

  test('an admitted conversation is not refused', () async {
    final repo = _Repo();
    final verdict = refusedForDailyLimit(repo, 'f1', timeout: quick * 10);
    repo.one.add(_doc({}));
    repo.one.add(_doc({'admitted': true}));
    expect(await verdict, isFalse);
  });

  test(
    'no verdict in time, an error or a deleted document count as sent',
    () async {
      final silent = _Repo();
      final late = refusedForDailyLimit(silent, 'f1', timeout: quick);
      silent.one.add(_doc({}));
      expect(await late, isFalse);

      final broken = _Repo();
      final failed = refusedForDailyLimit(broken, 'f1', timeout: quick * 10);
      broken.one.addError(StateError('permission-denied'));
      expect(await failed, isFalse);

      final gone = _Repo();
      final deleted = refusedForDailyLimit(gone, 'f1', timeout: quick * 10);
      gone.one.add(null);
      expect(await deleted, isFalse);
    },
  );
}
