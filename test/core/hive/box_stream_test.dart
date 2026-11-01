import 'dart:async';
import 'dart:io';

import 'package:easy_plate/core/hive/box_stream.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('box_stream_test');
    Hive.init(dir.path);
  });

  tearDown(() async {
    await Hive.close();
    if (dir.existsSync()) await dir.delete(recursive: true);
  });

  Future<Box<String>> open() => Hive.openBox<String>('watched');

  test('a write made as the first list arrives is not missed', () async {
    final box = await open();
    await box.put('a', 'a');
    final seen = <List<String>>[];
    final sub = watchBoxValues(open, quiet: Duration.zero).listen((values) {
      seen.add(values);
      // The screen saves the moment it has the list: that write must
      // reach it too, not sit in the box unannounced.
      if (seen.length == 1) unawaited(box.put('b', 'b'));
    });
    await pumpEventQueue();
    await sub.cancel();

    expect(seen.last, ['a', 'b']);
  });

  test('a burst of writes is one emission', () async {
    final box = await open();
    final seen = <List<String>>[];
    final sub = watchBoxValues(
      open,
      quiet: const Duration(milliseconds: 20),
    ).listen(seen.add);
    await pumpEventQueue();
    for (var i = 0; i < 50; i++) {
      unawaited(box.put('k$i', 'v$i'));
    }
    await Future<void>.delayed(const Duration(milliseconds: 60));
    await sub.cancel();

    expect(seen, hasLength(2));
    expect(seen.last, hasLength(50));
  });

  test('cancelled before the box opened, nothing is emitted', () async {
    final opening = Completer<Box<String>>();
    final seen = <List<String>>[];
    final sub = watchBoxValues(() => opening.future).listen(seen.add);
    final cancelled = sub.cancel();
    opening.complete(await open());
    await cancelled;
    await pumpEventQueue();

    expect(seen, isEmpty);
  });

  test('a box that cannot open is an error on the stream', () async {
    final errors = <Object>[];
    final done = Completer<void>();
    watchBoxValues<String>(
      () => Future.error(StateError('no scope')),
    ).listen((_) {}, onError: errors.add, onDone: done.complete);
    await done.future;

    expect(errors.single, isStateError);
  });
}
