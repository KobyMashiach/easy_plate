import 'package:easy_plate/core/constants/app_enums.dart';
import 'package:easy_plate/features/notifications/domain/entities/app_notification_entity.dart';
import 'package:easy_plate/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:easy_plate/features/notifications/domain/usecases/mark_notification_read_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

class _Recorder implements NotificationsRepository {
  final marked = <String>[];
  final missing = <String>{};

  @override
  Future<void> markRead(String uid, String notificationId) async {
    if (missing.contains(notificationId)) throw StateError('not-found');
    marked.add(notificationId);
  }

  @override
  Future<void> markAllRead(String uid) async {}
  @override
  Future<void> delete(String uid, String notificationId) async {}
  @override
  Future<void> deleteAll(String uid) async {}
  @override
  Stream<List<AppNotificationEntity>> watch(String uid) => const Stream.empty();
}

AppNotificationEntity _row(String id, {String? inviteId, bool read = false}) =>
    AppNotificationEntity(
      id: id,
      type: inviteId == null
          ? AppNotificationType.adminMessage
          : AppNotificationType.shareInvite,
      fromUid: 'owner',
      read: read,
      createdAt: DateTime(2026),
      inviteId: inviteId,
    );

void main() {
  test(
    'marks every unread row of the invite, re-invite rows included',
    () async {
      final repo = _Recorder();
      await MarkNotificationReadUseCase(repo).invite(
        'me',
        'c1_me',
        inbox: [
          _row('c1_me', inviteId: 'c1_me'),
          _row('c1_me_1700', inviteId: 'c1_me'),
          _row('c2_me', inviteId: 'c2_me'),
          _row('other'),
        ],
      );
      expect(repo.marked, unorderedEquals(['c1_me', 'c1_me_1700']));
    },
  );

  test('skips rows already read', () async {
    final repo = _Recorder();
    await MarkNotificationReadUseCase(repo).invite(
      'me',
      'c1_me',
      inbox: [
        _row('c1_me', inviteId: 'c1_me', read: true),
        _row('c1_me_1700', inviteId: 'c1_me', read: true),
      ],
    );
    expect(repo.marked, isEmpty);
  });

  test(
    'tries the invite id when the row has not reached the inbox yet',
    () async {
      final repo = _Recorder();
      await MarkNotificationReadUseCase(repo).invite('me', 'c1_me');
      expect(repo.marked, ['c1_me']);
    },
  );

  test('a missing row is not an error and the others still go', () async {
    final repo = _Recorder()..missing.add('c1_me');
    await MarkNotificationReadUseCase(repo).invite(
      'me',
      'c1_me',
      inbox: [_row('c1_me_1700', inviteId: 'c1_me')],
    );
    expect(repo.marked, ['c1_me_1700']);
  });
}
