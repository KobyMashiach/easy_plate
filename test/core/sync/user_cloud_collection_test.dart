// The Firestore types the mirror reads are sealed; these fakes stand in for
// the few calls hydrate makes.
// ignore_for_file: subtype_of_sealed_class
import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_plate/core/hive/user_scope.dart';
import 'package:easy_plate/core/services/account_deletion_guard.dart';
import 'package:easy_plate/core/sync/user_cloud_collection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:mocktail/mocktail.dart';

class _Firestore extends Mock implements FirebaseFirestore {}

class _Collection extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class _Doc extends Mock implements DocumentReference<Map<String, dynamic>> {}

class _Snapshot extends Mock implements QuerySnapshot<Map<String, dynamic>> {}

class _Metadata extends Mock implements SnapshotMetadata {}

class _QueryDoc extends Mock
    implements QueryDocumentSnapshot<Map<String, dynamic>> {}

/// Why the household listeners stay open while the app is in the
/// background: a record that is in the box but not on the server is either
/// one another member deleted, or one this device has not pushed yet — and
/// nothing on the record tells the two apart. Hydrate therefore restores
/// rather than deletes, so a fresh listen after a pause could not apply a
/// deletion made during the gap. These pin that hydrate never deletes.
void main() {
  late Directory dir;
  late _Firestore firestore;
  late _Collection recipes;
  final pushed = <String>[];

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('cloud_collection_test');
    Hive.init(dir.path);
    UserScope().resetForTest();
    await UserScope().switchTo('u1');
    CloudRoot.householdId = null;
    pushed.clear();

    firestore = _Firestore();
    final users = _Collection();
    final account = _Doc();
    recipes = _Collection();
    when(() => firestore.collection('users')).thenReturn(users);
    when(() => users.doc('u1')).thenReturn(account);
    when(() => account.path).thenReturn('users/u1');
    when(() => account.collection('recipes')).thenReturn(recipes);
    when(() => recipes.path).thenReturn('users/u1/recipes');
    when(() => recipes.doc(any())).thenAnswer((call) {
      final id = call.positionalArguments.single as String;
      final doc = _Doc();
      when(() => doc.set(any())).thenAnswer((_) async => pushed.add(id));
      return doc;
    });
  });

  tearDown(() async {
    await Hive.close();
    UserScope().resetForTest();
    if (dir.existsSync()) await dir.delete(recursive: true);
  });

  UserCloudCollection<String> mirror() => UserCloudCollection<String>(
    boxName: 'recipesBox',
    collection: 'recipes',
    idOf: (value) => value,
    toJson: (value) => {'v': value},
    // A shape this build cannot read throws, the way a model's fromJson
    // does on a field written by a newer website.
    fromJson: (json) => json['v'] as String,
    firestore: firestore,
  );

  void serverHolds(
    List<String> ids, {
    Map<String, Map<String, dynamic>> data = const {},
    Future<void>? answerAfter,
    bool fromCache = false,
  }) {
    final snapshot = _Snapshot();
    final metadata = _Metadata();
    when(() => metadata.isFromCache).thenReturn(fromCache);
    when(() => metadata.hasPendingWrites).thenReturn(false);
    when(() => snapshot.metadata).thenReturn(metadata);
    final docs = [
      for (final id in ids)
        () {
          final doc = _QueryDoc();
          when(() => doc.id).thenReturn(id);
          when(() => doc.data()).thenReturn(data[id] ?? {'v': id});
          when(() => doc.metadata).thenReturn(metadata);
          return doc;
        }(),
    ];
    when(() => snapshot.docs).thenReturn(docs);
    when(() => recipes.get()).thenAnswer((_) async {
      await answerAfter;
      return snapshot;
    });
  }

  test('a record the server lacks is pushed back, never deleted', () async {
    final box = await UserScope().open<String>('recipesBox');
    await box.putAll({'local-only': 'local-only', 'both': 'both'});
    serverHolds(['both', 'remote']);

    await mirror().hydrate();
    await pumpEventQueue();

    expect(box.keys, containsAll(['local-only', 'both', 'remote']));
    expect(pushed, ['local-only']);
  });

  test(
    'a document this build cannot read is skipped, and the stale local '
    'copy is not pushed over it',
    () async {
      final box = await UserScope().open<String>('recipesBox');
      await box.put('edited-on-web', 'edited-on-web');
      serverHolds(
        ['edited-on-web', 'fine'],
        data: {
          'edited-on-web': {'v': 42},
        },
      );

      final wrote = await mirror().hydrate();
      await pumpEventQueue();

      expect(wrote, isTrue);
      expect(box.get('fine'), 'fine');
      expect(box.get('edited-on-web'), 'edited-on-web');
      expect(pushed, isEmpty);
    },
  );

  test('a record saved on the device during the read keeps the save', () async {
    final box = await UserScope().open<String>('recipesBox');
    final answer = Completer<void>();
    // The server's copy of 'r1' predates the save below.
    serverHolds(
      ['r1'],
      data: {
        'r1': {'v': 'server'},
      },
      answerAfter: answer.future,
    );

    final running = mirror().hydrate();
    await pumpEventQueue();
    await box.put('r1', 'saved-meanwhile');
    await pumpEventQueue();
    answer.complete();
    await running;

    expect(box.get('r1'), 'saved-meanwhile');
  });

  test('a pass where nothing changed writes nothing to the box', () async {
    final box = await UserScope().open<String>('recipesBox');
    await box.putAll({'a': 'a', 'b': 'b'});
    serverHolds(['a', 'b']);
    final events = <Object?>[];
    final sub = box.watch().listen((e) => events.add(e.key));

    final wrote = await mirror().hydrate();
    await pumpEventQueue();
    await sub.cancel();

    expect(wrote, isFalse);
    expect(events, isEmpty);
    expect(pushed, isEmpty);
  });

  group('a record deleted elsewhere', () {
    Future<Box<bool>> ledger() =>
        UserScope().open<bool>(CloudSyncLedger.boxName);

    test('once confirmed by the server, its absence deletes it here', () async {
      final box = await UserScope().open<String>('recipesBox');
      await box.putAll({'gone': 'gone', 'kept': 'kept'});
      serverHolds(['gone', 'kept']);
      await mirror().hydrate();
      expect(
        (await ledger()).containsKey(
          CloudSyncLedger.key('users/u1/recipes', 'gone'),
        ),
        isTrue,
      );

      // Deleted on the website.
      serverHolds(['kept']);
      final wrote = await mirror().hydrate();
      await pumpEventQueue();

      expect(wrote, isTrue);
      expect(box.keys, ['kept']);
      expect(pushed, isEmpty, reason: 'the delete must not be undone');
      expect(
        (await ledger()).containsKey(
          CloudSyncLedger.key('users/u1/recipes', 'gone'),
        ),
        isFalse,
      );
    });

    test('an answer from the offline cache deletes nothing', () async {
      final box = await UserScope().open<String>('recipesBox');
      await box.put('maybe', 'maybe');
      serverHolds(['maybe']);
      await mirror().hydrate();

      serverHolds([], fromCache: true);
      await mirror().hydrate();
      await pumpEventQueue();

      expect(box.keys, ['maybe']);
      expect(pushed, ['maybe']);
    });

    test('a push the server acknowledged is confirmed', () async {
      await mirror().push('new');
      expect(
        (await ledger()).containsKey(
          CloudSyncLedger.key('users/u1/recipes', 'new'),
        ),
        isTrue,
      );
    });

    test('a household root does not vouch for the personal one', () async {
      final box = await UserScope().open<String>('recipesBox');
      await (await ledger()).put(
        CloudSyncLedger.key('households/h1/recipes', 'r1'),
        true,
      );
      await box.put('r1', 'r1');
      serverHolds([]);

      await mirror().hydrate();
      await pumpEventQueue();

      expect(box.keys, ['r1']);
      expect(pushed, ['r1']);
    });
  });

  test('mid-deletion the account root is gone: nothing is pushed', () async {
    final pending = Completer<void>();
    final deletion = AccountDeletionGuard.guard(() => pending.future);
    expect(CloudRoot.personalRoot(firestore), isNull);
    await mirror().push('r1');
    expect(pushed, isEmpty);
    pending.completeError(StateError('refused'));
    await expectLater(deletion, throwsStateError);
    // A refused deletion lifts the hold.
    expect(AccountDeletionGuard.deleting, isNull);
    await mirror().push('r1');
    expect(pushed, ['r1']);
  });
}
