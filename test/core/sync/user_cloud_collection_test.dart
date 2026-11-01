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

class _Batch extends Mock implements WriteBatch {}

class _Change extends Mock implements DocumentChange<Map<String, dynamic>> {}

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
      when(() => doc.id).thenReturn(id);
      when(() => doc.set(any())).thenAnswer((_) async => pushed.add(id));
      return doc;
    });
    // A batched push lands in [pushed] too, when it commits.
    registerFallbackValue(_Doc());
    when(() => firestore.batch()).thenAnswer((_) {
      final batch = _Batch();
      final staged = <String>[];
      when(
        () => batch.set<Map<String, dynamic>>(any(), any()),
      ).thenAnswer((call) {
        staged.add(
          (call.positionalArguments.first as DocumentReference).id,
        );
      });
      when(() => batch.commit()).thenAnswer((_) async => pushed.addAll(staged));
      return batch;
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

  test(
    'a long answer is decoded in breaks, and a save in one is kept',
    () async {
      final box = await UserScope().open<String>('recipesBox');
      final ids = [for (var i = 0; i < 250; i++) 'r$i'];
      await box.putAll({for (final id in ids) id: 'old $id'});
      serverHolds(ids);
      var frames = 0;
      // Something else gets the isolate while the answer is decoded: a
      // frame, and the user saving a record already decoded.
      final ticker = Timer.periodic(Duration.zero, (_) => frames++);
      var saved = false;
      final m = UserCloudCollection<String>(
        boxName: 'recipesBox',
        collection: 'recipes',
        idOf: (value) => value,
        toJson: (value) => {'v': value},
        fromJson: (json) {
          if (json['v'] == 'r150' && !saved) {
            saved = true;
            unawaited(box.put('r10', 'saved during the pass'));
          }
          return json['v'] as String;
        },
        firestore: firestore,
      );

      await m.hydrate();
      ticker.cancel();

      expect(frames, greaterThan(0), reason: 'the decode gave way');
      expect(box.get('r10'), 'saved during the pass');
      expect(box.get('r11'), 'r11');
      expect(box.get('r249'), 'r249');
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

  group('batched writes', () {
    late List<_Batch> batches;
    late List<int> commitSizes;
    var failCommit = false;

    setUp(() {
      registerFallbackValue(_Doc());
      batches = [];
      commitSizes = [];
      failCommit = false;
      when(() => firestore.batch()).thenAnswer((_) {
        final batch = _Batch();
        var size = 0;
        when(
          () => batch.set<Map<String, dynamic>>(any(), any()),
        ).thenAnswer((_) => size++);
        when(() => batch.delete(any())).thenAnswer((_) => size++);
        when(() => batch.commit()).thenAnswer((_) async {
          if (failCommit) throw StateError('offline');
          commitSizes.add(size);
        });
        batches.add(batch);
        return batch;
      });
    });

    Future<Box<bool>> ledger() =>
        UserScope().open<bool>(CloudSyncLedger.boxName);

    /// The commit sizes [n] records split into.
    List<int> chunks(int n) => [
      for (var left = n; left > 0; left -= UserCloudCollection.batchLimit)
        left < UserCloudCollection.batchLimit
            ? left
            : UserCloudCollection.batchLimit,
    ];

    test('pushAll goes up in batches, never one request per record', () async {
      final ids = [for (var i = 0; i < 1000; i++) 'r$i'];
      await mirror().pushAll(ids);

      expect(pushed, isEmpty, reason: 'no single-document writes');
      expect(commitSizes, chunks(1000));
      final confirmed = await ledger();
      expect(
        ids.every(
          (id) => confirmed.containsKey(
            CloudSyncLedger.key('users/u1/recipes', id),
          ),
        ),
        isTrue,
      );
    });

    test('removeAll deletes in batches and drops the confirmations', () async {
      await CloudSyncLedger.mark('users/u1/recipes', ['a', 'b', 'c']);
      await mirror().removeAll(['a', 'b', 'a']);

      expect(commitSizes, [2], reason: 'one commit, duplicates folded');
      final confirmed = await ledger();
      expect(
        confirmed.keys,
        [CloudSyncLedger.key('users/u1/recipes', 'c')],
      );
    });

    test('a failed commit confirms nothing and does not throw', () async {
      failCommit = true;
      await mirror().pushAll(['x', 'y']);
      expect((await ledger()).isEmpty, isTrue);
    });

    test('a hydrate pushes back what only the box has in batches', () async {
      final box = await UserScope().open<String>('recipesBox');
      await box.putAll({for (var i = 0; i < 600; i++) 'r$i': 'r$i'});
      serverHolds(['r0']);

      await mirror().hydrate();
      await pumpEventQueue();

      expect(pushed, isEmpty, reason: 'no single-document writes');
      expect(commitSizes, chunks(599));
    });

    test('nothing to write opens no batch', () async {
      await mirror().pushAll(const []);
      await mirror().removeAll(const []);
      expect(batches, isEmpty);
    });
  });

  group('household listener', () {
    _Change change(String id, DocumentChangeType type) {
      final metadata = _Metadata();
      when(() => metadata.hasPendingWrites).thenReturn(false);
      final doc = _QueryDoc();
      when(() => doc.id).thenReturn(id);
      when(() => doc.data()).thenReturn({'v': id});
      when(() => doc.metadata).thenReturn(metadata);
      final c = _Change();
      when(() => c.type).thenReturn(type);
      when(() => c.doc).thenReturn(doc);
      return c;
    }

    _Snapshot snapshotOf(List<_Change> changes) {
      final snapshot = _Snapshot();
      when(() => snapshot.docChanges).thenReturn(changes);
      return snapshot;
    }

    test('a first snapshot of every document takes breaks, and a save in one '
        'is kept', () async {
      final box = await UserScope().open<String>('recipesBox');
      final ids = [for (var i = 0; i < 250; i++) 'r$i'];
      await box.putAll({for (final id in ids) id: 'old $id'});
      final server = StreamController<QuerySnapshot<Map<String, dynamic>>>();
      when(() => recipes.snapshots()).thenAnswer((_) => server.stream);
      var frames = 0;
      final ticker = Timer.periodic(Duration.zero, (_) => frames++);
      var saved = false;
      final m = UserCloudCollection<String>(
        boxName: 'recipesBox',
        collection: 'recipes',
        idOf: (value) => value,
        toJson: (value) => {'v': value},
        fromJson: (json) {
          if (json['v'] == 'r150' && !saved) {
            saved = true;
            unawaited(box.put('r10', 'saved during the pass'));
          }
          return json['v'] as String;
        },
        firestore: firestore,
      );
      await m.listen();

      server.add(
        snapshotOf([
          for (final id in ids) change(id, DocumentChangeType.added),
        ]),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      ticker.cancel();

      expect(frames, greaterThan(0), reason: 'the decode gave way');
      expect(box.get('r10'), 'saved during the pass');
      expect(box.get('r11'), 'r11');
      expect(box.get('r249'), 'r249');
      await m.stopListening();
      await server.close();
    });

    test('a listener closed by an error reports itself closed', () async {
      final server = StreamController<QuerySnapshot<Map<String, dynamic>>>();
      when(() => recipes.snapshots()).thenAnswer((_) => server.stream);
      final m = UserCloudCollection<String>(
        boxName: 'recipesBox',
        collection: 'recipes',
        idOf: (value) => value,
        toJson: (value) => {'v': value},
        fromJson: (json) => json['v'] as String,
        firestore: firestore,
      );
      expect(m.isListening, isFalse);
      await m.listen();
      expect(m.isListening, isTrue);

      server.addError(StateError('permission-denied'));
      await pumpEventQueue();
      expect(m.isListening, isFalse);
      await server.close();
    });

    test(
      'snapshots apply in order: a delete then a re-add keeps the record',
      () async {
        final box = await UserScope().open<String>('recipesBox');
        await box.put('x', 'x');
        final server = StreamController<QuerySnapshot<Map<String, dynamic>>>();
        when(() => recipes.snapshots()).thenAnswer((_) => server.stream);
        final m = mirror();
        await m.listen();

        // Removed (with another record arriving), then put back at once.
        server
          ..add(
            snapshotOf([
              change('y', DocumentChangeType.added),
              change('x', DocumentChangeType.removed),
            ]),
          )
          ..add(snapshotOf([change('x', DocumentChangeType.added)]));
        await pumpEventQueue();
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(box.keys, containsAll(['x', 'y']));
        await m.stopListening();
        await server.close();
      },
    );
  });
}
