import 'dart:async';

import 'package:hive_ce/hive.dart';

/// The contents of a box, now and after every write.
///
/// One shape for every "the list, kept current" stream in the app: the
/// recipes, books, plans and lists all live in an IndexedStack tab that is
/// never rebuilt on its own, so a save made anywhere else reaches them only
/// through this.
///
/// Writes are coalesced: hydrating from the cloud puts every record in one
/// after another, and a tab that re-read and re-mapped the whole box for
/// each of them did N² work on sign-in. A short quiet period turns a burst
/// into one emission.
Stream<List<T>> watchBoxValues<T>(
  Future<Box<T>> Function() open, {
  Duration quiet = const Duration(milliseconds: 60),
}) {
  late final StreamController<List<T>> controller;
  StreamSubscription<void>? changes;
  var cancelled = false;
  controller = StreamController<List<T>>(
    onListen: () async {
      final Box<T> box;
      try {
        box = await open();
      } catch (e, stack) {
        if (!cancelled) {
          controller.addError(e, stack);
          await controller.close();
        }
        return;
      }
      if (cancelled) return;
      // Following the box before the first read, not after: a write that
      // landed between the two (a screen saving the moment it had the
      // list) was in neither, and the tab showed the box without it until
      // some later write happened along.
      changes = coalesce(box.watch(), quiet).listen(
        (_) => controller.add(box.values.toList()),
        onError: controller.addError,
        onDone: controller.close,
      );
      controller.add(box.values.toList());
    },
    onPause: () => changes?.pause(),
    onResume: () => changes?.resume(),
    onCancel: () {
      cancelled = true;
      return changes?.cancel();
    },
  );
  return controller.stream;
}

/// Emits once per burst of [source] events: the first event starts a
/// [quiet] timer, later events restart it, and the emission lands when it
/// runs out. A [Duration.zero] passes events straight through.
Stream<void> coalesce<E>(Stream<E> source, Duration quiet) {
  if (quiet == Duration.zero) return source.map((_) {});
  late final StreamController<void> controller;
  StreamSubscription<E>? subscription;
  Timer? timer;
  controller = StreamController<void>(
    onListen: () {
      subscription = source.listen(
        (_) {
          timer?.cancel();
          timer = Timer(quiet, () {
            if (!controller.isClosed) controller.add(null);
          });
        },
        onError: controller.addError,
        onDone: () {
          timer?.cancel();
          controller.close();
        },
      );
    },
    onPause: () => subscription?.pause(),
    onResume: () => subscription?.resume(),
    onCancel: () {
      timer?.cancel();
      return subscription?.cancel();
    },
  );
  return controller.stream;
}
