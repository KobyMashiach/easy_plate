import 'dart:async';

import 'package:easy_plate/core/hive/user_scope.dart';
import 'package:easy_plate/core/sync/cloud_sync_service.dart';
import 'package:easy_plate/core/sync/user_cloud_collection.dart';
import 'package:flutter_test/flutter_test.dart';

/// A mirror that counts its reads and answers when told to.
class _FakeMirror implements CloudMirror {
  _FakeMirror({this.collection = 'recipes', this.shared = true});

  int hydrates = 0;
  Completer<void>? gate;
  bool writes = false;

  @override
  final String collection;

  @override
  Future<bool> hydrate() async {
    hydrates++;
    if (gate case final held?) await held.future;
    return writes;
  }

  @override
  final bool shared;

  @override
  Future<void> listen() async {}

  @override
  Future<void> stopListening() async {}

  @override
  Future<void> clearLocal() async {}
}

void main() {
  late CloudSyncService sync;
  late _FakeMirror mirror;

  setUp(() async {
    sync = CloudSyncService();
    sync.resetForTest();
    mirror = _FakeMirror();
    sync.mirrorsForTest = [mirror];
    UserScope().resetForTest();
    await UserScope().switchTo('u1');
  });

  tearDown(() {
    sync.mirrorsForTest = null;
    sync.resetForTest();
    UserScope().resetForTest();
  });

  test(
    'two hydrates for the same account close together share one pass',
    () async {
      mirror.gate = Completer<void>();
      final first = sync.hydrate('u1');
      final second = sync.hydrate('u1');
      expect(mirror.hydrates, 1);

      mirror.gate!.complete();
      await Future.wait([first, second]);
      expect(mirror.hydrates, 1);

      // Done: the account is remembered, a third call reads nothing.
      await sync.hydrate('u1');
      expect(mirror.hydrates, 1);
    },
  );

  test('a different account does not share the pass', () async {
    mirror.gate = Completer<void>();
    final first = sync.hydrate('u1');
    final second = sync.hydrate('u2');
    expect(mirror.hydrates, 2);
    mirror.gate!.complete();
    await Future.wait([first, second]);
  });

  test(
    'once a pass is over, the next call for the account runs its own',
    () async {
      UserScope().resetForTest();
      // No signed-in scope: the pass finishes without marking the account done
      // (the way a timeout does), so the next auth event must get another go.
      await sync.hydrate('u1');
      expect(mirror.hydrates, 1);
      await sync.hydrate('u1');
      expect(mirror.hydrates, 2);
    },
  );

  test('forget drops a pass in flight, so a re-sign-in starts fresh', () async {
    mirror.gate = Completer<void>();
    final stale = sync.hydrate('u1');
    sync.forget();
    final fresh = sync.hydrate('u1');
    expect(mirror.hydrates, 2);
    mirror.gate!.complete();
    await Future.wait([stale, fresh]);
    // The stale pass finishing must not clear the fresh one's bookkeeping
    // into a third parallel read either.
    expect(sync.isListening, isFalse);
  });

  test('a pass that times out never throws and is not remembered', () async {
    mirror.gate = Completer<void>();
    await sync.hydrate('u1', timeout: const Duration(milliseconds: 20));
    await sync.hydrate('u1', timeout: const Duration(milliseconds: 20));
    expect(mirror.hydrates, 2);
    mirror.gate!.complete();
  });
  test(
    'a pass overtaken by a wipe and a re-sign-in is not remembered',
    () async {
      mirror.gate = Completer<void>();
      final stale = sync.hydrate('u1');
      // Signed out and back in to the same account while the pass ran: the
      // uid matches again, but the boxes it filled were deleted.
      await UserScope().switchTo('u2');
      await UserScope().switchTo('u1');
      mirror.gate!.complete();
      await stale;

      await sync.hydrate('u1');
      expect(mirror.hydrates, 2);
    },
  );

  group('refresh on resume', () {
    late DateTime now;

    setUp(() => sync.clock = () => now);

    test('runs nothing before the sign-in pass has finished', () async {
      now = DateTime(2026, 10, 18, 12);
      expect(await sync.refresh('u1'), isEmpty);
      expect(mirror.hydrates, 0);
    });

    test('re-reads once the throttle has passed, not before', () async {
      now = DateTime(2026, 10, 18, 12);
      await sync.hydrate('u1');
      expect(mirror.hydrates, 1);

      now = now.add(const Duration(seconds: 30));
      await sync.refresh('u1');
      expect(mirror.hydrates, 1);

      now = now.add(CloudSyncService.refreshInterval);
      await sync.refresh('u1');
      expect(mirror.hydrates, 2);
      // The pass is still remembered: a later auth event reads nothing.
      await sync.hydrate('u1');
      expect(mirror.hydrates, 2);
    });

    test('names the collections whose boxes changed', () async {
      final preferences = _FakeMirror(collection: 'preferences', shared: false)
        ..writes = true;
      sync.mirrorsForTest = [mirror, preferences];
      now = DateTime(2026, 10, 18, 12);
      await sync.hydrate('u1');
      now = now.add(CloudSyncService.refreshInterval);
      expect(await sync.refresh('u1'), {'preferences'});
    });

    test('another account, or a pass in flight, is left alone', () async {
      now = DateTime(2026, 10, 18, 12);
      await sync.hydrate('u1');
      now = now.add(CloudSyncService.refreshInterval);
      expect(await sync.refresh('u2'), isEmpty);
      expect(mirror.hydrates, 1);

      mirror.gate = Completer<void>();
      final first = sync.refresh('u1');
      final second = sync.refresh('u1');
      expect(mirror.hydrates, 2);
      mirror.gate!.complete();
      await Future.wait([first, second]);
    });

    test('a household mirror that listens live is not re-read', () async {
      final own = _FakeMirror(collection: 'preferences', shared: false);
      sync.mirrorsForTest = [mirror, own];
      now = DateTime(2026, 10, 18, 12);
      await sync.hydrate('u1');
      await sync.startListening();
      now = now.add(CloudSyncService.refreshInterval);
      await sync.refresh('u1');
      expect(mirror.hydrates, 1);
      expect(own.hydrates, 2);
      await sync.stopListening();
    });
  });
}
