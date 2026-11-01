// Firestore's document types are sealed; mocks of them are the usual
// stand-in, as in user_cloud_collection_test.
// ignore_for_file: subtype_of_sealed_class

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_plate/core/services/device_session_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Firestore extends Mock implements FirebaseFirestore {}

class _Doc extends Mock implements DocumentReference<Map<String, dynamic>> {}

class _Snapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

DocumentSnapshot<Map<String, dynamic>> snapshotOf(Map<String, dynamic>? data) {
  final snapshot = _Snapshot();
  when(() => snapshot.exists).thenReturn(data != null);
  when(() => snapshot.data()).thenReturn(data);
  return snapshot;
}

void main() {
  late StreamController<DocumentSnapshot<Map<String, dynamic>>> server;
  final service = DeviceSessionService();

  setUp(() {
    // Synchronous, so a snapshot runs its handler up to the device id read
    // right inside add(), and the test can act in that gap.
    server = StreamController.broadcast(sync: true);
    final db = _Firestore();
    final doc = _Doc();
    when(() => db.doc(any())).thenReturn(doc);
    when(() => doc.snapshots()).thenAnswer((_) => server.stream);
    service.configure(firestore: db, deviceId: 'mine');
  });

  tearDown(() {
    service.stopWaiting();
    service.resetForTest();
    server.close();
  });

  final held = {
    'deviceId': 'theirs',
    'expiresAt': Timestamp.fromDate(
      DateTime.now().add(const Duration(days: 9)),
    ),
  };

  test(
    'a release answer that lands after the wait stopped does nothing',
    () async {
      var declined = 0;
      var freed = 0;
      service.waitForRelease(
        'u1',
        onFree: () => freed++,
        onDeclined: () => declined++,
      );
      final takeover = Timestamp.fromDate(
        DateTime.now().add(const Duration(milliseconds: 1)),
      );

      server.add(
        snapshotOf({
          ...held,
          'releaseRequest': {'deviceId': 'mine', 'takeoverAt': takeover},
        }),
      );
      // The gate moved on while the handler read this device's id.
      service.stopWaiting();
      await Future<void>.delayed(const Duration(milliseconds: 2100));
      expect(service.takeoverAt.value, isNull);
      expect(freed, 0, reason: 'no takeover timer was armed');

      // A live wait still answers.
      service.waitForRelease(
        'u1',
        onFree: () => freed++,
        onDeclined: () => declined++,
      );
      server.add(
        snapshotOf({
          ...held,
          'releaseRequest': {
            'deviceId': 'mine',
            'declinedAt': Timestamp.now(),
          },
        }),
      );
      await pumpEventQueue();
      expect(declined, 1);
    },
  );

  test('a session end read after unwatch is not reported', () async {
    final ends = <SessionEnd>[];
    service.watch('u1', ends.add);
    server.add(snapshotOf(held));
    service.unwatch();
    await pumpEventQueue();
    expect(ends, isEmpty);

    service.watch('u1', ends.add);
    server.add(snapshotOf(held));
    await pumpEventQueue();
    expect(ends, [SessionEnd.otherDevice]);
  });
}
