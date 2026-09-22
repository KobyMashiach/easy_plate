import 'dart:async';

import 'package:easy_plate/core/services/admin_inbox_service.dart';
import 'package:easy_plate/features/feedback/domain/entities/feedback_entity.dart';
import 'package:easy_plate/features/feedback/domain/repositories/feedback_repository.dart';
import 'package:easy_plate/features/feedback/domain/usecases/manage_feedback_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeFeedback implements FeedbackRepository {
  final controller = StreamController<List<FeedbackEntity>>.broadcast();
  int watches = 0;
  final read = <String, bool>{};
  final replies = <String>[];
  final deleted = <String>[];
  List<String>? markedAll;

  @override
  Stream<List<FeedbackEntity>> watchAll({int limit = 500}) {
    watches++;
    return controller.stream;
  }

  @override
  Future<List<FeedbackEntity>> getAll({int limit = 200}) async => const [];

  @override
  Future<void> send(FeedbackEntity feedback) async {}

  @override
  Future<void> setRead(String feedbackId, bool value) async =>
      read[feedbackId] = value;

  @override
  Future<void> markAllRead(Iterable<String> feedbackIds) async =>
      markedAll = feedbackIds.toList();

  @override
  Future<void> delete(String feedbackId) async => deleted.add(feedbackId);

  @override
  Future<void> reply({
    required FeedbackEntity feedback,
    required String text,
    required String fromUid,
  }) async => replies.add('${feedback.id}:$text:$fromUid');
}

FeedbackEntity ticket(
  String id, {
  bool read = false,
  String message = 'hello',
}) => FeedbackEntity(
  id: id,
  type: FeedbackType.bug,
  message: message,
  authorUid: 'u-$id',
  authorName: 'Dana',
  createdAt: DateTime(2026, 9, 1),
  read: read,
);

void main() {
  late _FakeFeedback repository;
  final service = AdminInboxService();

  setUp(() {
    repository = _FakeFeedback();
    service.unbind();
  });

  test('counts the unread messages as they arrive', () async {
    service.bind(repository);
    repository.controller.add([
      ticket('a'),
      ticket('b', read: true),
      ticket('c'),
    ]);
    await Future<void>.delayed(Duration.zero);
    expect(service.unreadCount.value, 2);
    expect(service.items.value.length, 3);
  });

  test('binds once, and unbinding clears everything', () async {
    service.bind(repository);
    service.bind(repository);
    expect(repository.watches, 1);
    repository.controller.add([ticket('a')]);
    await Future<void>.delayed(Duration.zero);
    service.unbind();
    expect(service.unreadCount.value, 0);
    expect(service.items.value, isEmpty);
    expect(service.isBound, isFalse);
  });

  test('read all touches only the unread ones', () async {
    final manage = ManageFeedbackUseCase(repository);
    await manage.markAllRead([
      ticket('a'),
      ticket('b', read: true),
      ticket('c'),
    ]);
    expect(repository.markedAll, ['a', 'c']);
  });

  test('a reply is trimmed and signed; an empty one is refused', () async {
    final manage = ManageFeedbackUseCase(repository);
    await manage.reply(ticket('a'), '  thanks  ', fromUid: 'admin');
    expect(repository.replies, ['a:thanks:admin']);
    expect(
      () => manage.reply(ticket('a'), '   ', fromUid: 'admin'),
      throwsArgumentError,
    );
  });

  test('the excerpt quoted in a reply is one flat line, cut short', () {
    expect(
      ticket('a', message: 'line one\n\n  line two').excerpt,
      'line one line two',
    );
    final long = ticket('b', message: 'x' * 200).excerpt;
    expect(long.length, 78);
    expect(long.endsWith('…'), isTrue);
  });
}
