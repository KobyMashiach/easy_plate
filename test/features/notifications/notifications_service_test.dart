import 'dart:async';

import 'package:easy_plate/core/constants/app_enums.dart';
import 'package:easy_plate/core/services/notifications_service.dart';
import 'package:easy_plate/features/notifications/domain/entities/app_notification_entity.dart';
import 'package:easy_plate/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeNotifications implements NotificationsRepository {
  final controller = StreamController<List<AppNotificationEntity>>.broadcast();
  int watches = 0;

  @override
  Stream<List<AppNotificationEntity>> watch(String uid) {
    watches++;
    return controller.stream;
  }

  @override
  Future<void> markRead(String uid, String notificationId) async {}
  @override
  Future<void> markAllRead(String uid) async {}
}

AppNotificationEntity item(String id, {bool read = false}) => AppNotificationEntity(
      id: id,
      type: AppNotificationType.shareInvite,
      fromUid: 'dana',
      read: read,
      createdAt: DateTime(2026, 1, 1),
    );

void main() {
  late _FakeNotifications repository;
  final service = NotificationsService();

  setUp(() {
    repository = _FakeNotifications();
    service.unbind();
  });

  tearDown(() => repository.controller.close());

  test('the badge counts only the unread items', () async {
    service.bind('me', repository);
    repository.controller.add([item('a'), item('b', read: true), item('c')]);
    await Future<void>.delayed(Duration.zero);

    expect(service.unreadCount.value, 2);
    expect(service.items.value, hasLength(3));
  });

  test('rebinding the same account does not open a second listener', () {
    service.bind('me', repository);
    service.bind('me', repository);
    expect(repository.watches, 1);
  });

  test('signing out clears everything, so the next account sees nothing stale', () async {
    service.bind('me', repository);
    repository.controller.add([item('a')]);
    await Future<void>.delayed(Duration.zero);
    expect(service.unreadCount.value, 1);

    service.unbind();
    expect(service.unreadCount.value, 0);
    expect(service.items.value, isEmpty);
    expect(service.uid, isNull);
  });
}
