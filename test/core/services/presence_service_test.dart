// Mocked Firestore references stand in for the database the heartbeat writes.
// ignore_for_file: subtype_of_sealed_class

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_plate/core/services/account_deletion_guard.dart';
import 'package:easy_plate/core/services/presence_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

typedef _Json = Map<String, dynamic>;

class _Firestore extends Mock implements FirebaseFirestore {}

class _Collection extends Mock implements CollectionReference<_Json> {}

class _Doc extends Mock implements DocumentReference<_Json> {}

void main() {
  final now = DateTime(2026, 10, 9, 12);

  test('a fresh beat with the flag set is online', () {
    expect(
      PresenceService.isOnline(
        online: true,
        lastSeenAt: now.subtract(const Duration(seconds: 50)),
        now: now,
        heartbeatSeconds: 60,
      ),
      isTrue,
    );
  });

  test('one missed beat is forgiven, two are not', () {
    expect(
      PresenceService.isOnline(
        online: true,
        lastSeenAt: now.subtract(const Duration(seconds: 140)),
        now: now,
        heartbeatSeconds: 60,
      ),
      isTrue,
    );
    expect(
      PresenceService.isOnline(
        online: true,
        lastSeenAt: now.subtract(const Duration(seconds: 151)),
        now: now,
        heartbeatSeconds: 60,
      ),
      isFalse,
    );
  });

  test(
    'a backgrounded app, a missing stamp, or a switched-off report are offline',
    () {
      expect(
        PresenceService.isOnline(
          online: false,
          lastSeenAt: now,
          now: now,
          heartbeatSeconds: 60,
        ),
        isFalse,
      );
      expect(
        PresenceService.isOnline(
          online: true,
          lastSeenAt: null,
          now: now,
          heartbeatSeconds: 60,
        ),
        isFalse,
      );
      expect(
        PresenceService.isOnline(
          online: true,
          lastSeenAt: now,
          now: now,
          heartbeatSeconds: 0,
        ),
        isFalse,
      );
    },
  );

  test('the window follows the interval', () {
    expect(PresenceService.onlineWindow(60), const Duration(seconds: 150));
    expect(PresenceService.onlineWindow(120), const Duration(seconds: 270));
  });

  test(
    'start and stop keep the uid, and stop without a database is harmless',
    () async {
      final service = PresenceService()..resetForTest();
      service.configure(intervalSeconds: 0);
      service.start('u1');
      expect(service.uid, 'u1');
      await service.stop();
      expect(service.uid, isNull);
      service.resetForTest();
    },
  );

  group('heartbeat schedule', () {
    late List<bool> writes;
    late PresenceService service;
    late _Firestore firestore;

    setUpAll(() => registerFallbackValue(SetOptions(merge: true)));

    setUp(() {
      writes = [];
      firestore = _Firestore();
      final users = _Collection();
      final doc = _Doc();
      when(() => firestore.collection('users')).thenReturn(users);
      when(() => users.doc(any())).thenReturn(doc);
      when(() => doc.set(any(), any())).thenAnswer((call) async {
        final data = call.positionalArguments.first as Map<String, dynamic>;
        writes.add(data['online'] as bool);
      });
      service = PresenceService()..resetForTest();
      service.configure(firestore: firestore, intervalSeconds: 60);
    });

    tearDown(() => service.resetForTest());

    testWidgets('beats while in front, stops on pause, restarts on resume', (
      tester,
    ) async {
      service.start('u1');
      await tester.pump();
      expect(writes, [true]);
      await tester.pump(const Duration(seconds: 60));
      expect(writes, [true, true]);

      service.setForeground(false);
      await tester.pump();
      expect(writes, [true, true, false]);
      // Away for ten intervals: not one beat.
      await tester.pump(const Duration(minutes: 10));
      expect(writes, [true, true, false]);

      service.setForeground(true);
      await tester.pump();
      expect(writes, [true, true, false, true]);
      await tester.pump(const Duration(seconds: 60));
      expect(writes, [true, true, false, true, true]);
      service.resetForTest();
    });

    testWidgets('quick pause/resume cycles leave a single timer', (
      tester,
    ) async {
      service.start('u1');
      for (var i = 0; i < 5; i++) {
        service.setForeground(false);
        service.setForeground(true);
        // A repeated report of the same state changes nothing.
        service.setForeground(true);
      }
      // Start again for the same account while already beating: no second
      // timer either.
      service.start('u1');
      await tester.pump();
      writes.clear();
      await tester.pump(const Duration(seconds: 60));
      expect(writes, [true]);
      await tester.pump(const Duration(seconds: 60));
      expect(writes, [true, true]);
      service.resetForTest();
    });

    testWidgets('halt (account deletion) writes nothing, then or later', (
      tester,
    ) async {
      service.start('u1');
      await tester.pump();
      writes.clear();
      expect(service.halt(), 'u1');
      await service.stop();
      service.setForeground(false);
      service.setForeground(true);
      await tester.pump(const Duration(minutes: 5));
      expect(writes, isEmpty);
    });

    testWidgets('a deletion in flight stands every write down, even unhalted', (
      tester,
    ) async {
      service.start('u1');
      await tester.pump();
      writes.clear();
      final done = Completer<void>();
      final deletion = AccountDeletionGuard.guard(
        () => done.future,
        uid: 'u1',
      );
      service.setForeground(false);
      service.setForeground(true);
      await tester.pump(const Duration(minutes: 3));
      expect(writes, isEmpty);
      done.complete();
      await deletion;
      // Gone for good: still nothing.
      await tester.pump(const Duration(minutes: 3));
      expect(writes, isEmpty);
      AccountDeletionGuard.resetForTest();
      service.resetForTest();
    });

    testWidgets('switched off: no beat and no offline write on pause', (
      tester,
    ) async {
      service.configure(firestore: firestore, intervalSeconds: 0);
      service.start('u1');
      service.setForeground(false);
      service.setForeground(true);
      await tester.pump(const Duration(minutes: 5));
      expect(writes, isEmpty);
    });
  });
}
