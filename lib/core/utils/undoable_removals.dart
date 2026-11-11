import 'package:flutter/widgets.dart';

import '../hive/user_scope.dart';
import '../widgets/app_dialog.dart';

/// Removals that wait out an undo window before they happen.
///
/// The undo pattern for a record whose delete has side effects that cannot
/// be put back by saving it again (a photo removed from Storage, a cloud
/// mirror delete, dropped translations): rather than delete and try to
/// rebuild, the record is only *hidden* while the [AppDialog.undo] notice is
/// up, and the real delete runs once the notice is gone without an undo.
/// Undo then restores it exactly, because nothing was touched.
///
/// Usage, for any kind of record:
///
/// ```dart
/// UndoableRemovals.instance.remove(
///   context,
///   key: UndoableRemovals.keyFor('plan', plan.id),
///   message: t.mealPlanner.planDeleted,
///   commit: () => repository.deletePlan(plan.id),
/// );
/// ```
///
/// and in the bloc or widget that lists the records, leave out every one
/// whose key [isPending], re-filtering when [pending] changes.
///
/// A commit is skipped when the signed-in account changed meanwhile (the
/// boxes it would write belong to someone else, or are gone); and if the
/// app is killed inside the window the record simply stays. Both err on the
/// side of keeping data.
class UndoableRemovals {
  UndoableRemovals._();
  static final instance = UndoableRemovals._();

  /// The keys hidden right now. Listen to re-filter a list.
  final ValueNotifier<Set<String>> pending = ValueNotifier(const {});

  static String keyFor(String kind, String id) => '$kind:$id';

  bool isPending(String key) => pending.value.contains(key);

  /// Hides [key], says [message] with an Undo, and runs [commit] when the
  /// notice leaves without one. [onUndone] runs after an undo, for a caller
  /// with more to put back than the hidden key.
  void remove(
    BuildContext context, {
    required String key,
    required String message,
    required Future<void> Function() commit,
    VoidCallback? onUndone,
    IconData? icon,
  }) {
    final generation = UserScope().generation;
    _set(key, hidden: true);
    AppDialog.undo(
      context,
      message: message,
      icon: icon,
      onUndo: () {
        _set(key, hidden: false);
        onUndone?.call();
      },
      onCommit: () async {
        if (UserScope().generation != generation) {
          _set(key, hidden: false);
          return;
        }
        try {
          await commit();
        } catch (e) {
          // The record is still there; showing it again is the honest state.
          debugPrint('Deferred removal of $key failed: $e');
          _set(key, hidden: false);
          return;
        }
        // Released a beat later, not at once: the lists learn of the delete
        // from their box streams, and a key released first would flash the
        // record back for a frame. Released at all so an id that returns
        // later (a re-import, a sync) is not hidden for good.
        Future<void>.delayed(
          const Duration(seconds: 2),
          () => _set(key, hidden: false),
        );
      },
    );
  }

  void _set(String key, {required bool hidden}) {
    final next = {...pending.value};
    final changed = hidden ? next.add(key) : next.remove(key);
    if (changed) pending.value = Set.unmodifiable(next);
  }
}
