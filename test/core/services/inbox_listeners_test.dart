import 'dart:async';

import 'package:easy_plate/core/services/admin_inbox_service.dart';
import 'package:easy_plate/core/services/notifications_service.dart';
import 'package:easy_plate/features/feedback/domain/entities/feedback_entity.dart';
import 'package:easy_plate/features/feedback/domain/repositories/feedback_repository.dart';
import 'package:easy_plate/features/notifications/domain/entities/app_notification_entity.dart';
import 'package:easy_plate/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Notifications extends Mock implements NotificationsRepository {}

class _Feedback extends Mock implements FeedbackRepository {}

/// A stream that counts the listeners opened on it and how many are live.
class _Counted<T> {
  var opened = 0;
  var live = 0;
  late final controller = StreamController<T>.broadcast(
    onListen: () {
      opened++;
      live++;
    },
    onCancel: () => live--,
  );
}

void main() {
  group('NotificationsService', () {
    late _Notifications repository;
    late _Counted<List<AppNotificationEntity>> stream;
    final service = NotificationsService();

    setUp(() {
      service.resetForTest();
      repository = _Notifications();
      stream = _Counted();
      when(
        () => repository.watch('u1'),
      ).thenAnswer((_) => stream.controller.stream);
    });

    tearDown(service.resetForTest);

    test('closes its listener while away and reopens it on return', () async {
      service.bind('u1', repository);
      await pumpEventQueue();
      expect(stream.live, 1);

      service.setForeground(false);
      await pumpEventQueue();
      expect(stream.live, 0);
      expect(service.isListening, isFalse);
      // Still bound: the account has not changed.
      expect(service.uid, 'u1');

      service.setForeground(true);
      await pumpEventQueue();
      expect(stream.live, 1);
      expect(stream.opened, 2);
    });

    test('quick away/back cycles never stack listeners', () async {
      service.bind('u1', repository);
      for (var i = 0; i < 5; i++) {
        service.setForeground(false);
        service.setForeground(true);
        service.setForeground(true);
      }
      await pumpEventQueue();
      expect(stream.live, 1);
    });

    test('bound while away: opens only on return', () async {
      service.setForeground(false);
      service.bind('u1', repository);
      await pumpEventQueue();
      expect(stream.opened, 0);
      service.setForeground(true);
      await pumpEventQueue();
      expect(stream.live, 1);
    });

    test('sign-out while away stays closed on return', () async {
      service.bind('u1', repository);
      service.setForeground(false);
      service.unbind();
      service.setForeground(true);
      await pumpEventQueue();
      expect(stream.live, 0);
      expect(stream.opened, 1);
    });
  });

  group('AdminInboxService', () {
    late _Feedback repository;
    late _Counted<List<FeedbackEntity>> stream;
    final service = AdminInboxService();

    setUp(() {
      service.resetForTest();
      repository = _Feedback();
      stream = _Counted();
      when(
        () => repository.watchAll(),
      ).thenAnswer((_) => stream.controller.stream);
    });

    tearDown(service.resetForTest);

    test('closes its listener while away and reopens it on return', () async {
      service.bind(repository);
      await pumpEventQueue();
      expect(stream.live, 1);
      service.setForeground(false);
      await pumpEventQueue();
      expect(stream.live, 0);
      expect(service.isBound, isTrue);
      service.setForeground(false);
      service.setForeground(true);
      service.setForeground(true);
      await pumpEventQueue();
      expect(stream.live, 1);
      expect(stream.opened, 2);
    });

    test('unbound while away stays closed on return', () async {
      service.bind(repository);
      service.setForeground(false);
      service.unbind();
      service.setForeground(true);
      await pumpEventQueue();
      expect(stream.live, 0);
    });
  });
}
