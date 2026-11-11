import '../../../core/errors/app_exception.dart';
import '../../my_recipes/domain/entities/recipe_entity.dart';
import 'bulk_import.dart';
import 'paid_call_refusal.dart';

enum BulkRowStatus { waiting, running, done, failed, skipped }

/// Why a run ended before the last row.
enum BulkStopReason {
  /// It did not: every row was tried (or skipped as unavailable).
  none,

  /// The daily allowance said no — the gate refused, or the server did.
  quota,

  /// A refusal that stands for the rest too: no verified phone, a blocked
  /// account.
  refused,

  /// The user stopped it.
  cancelled,
}

/// Runs a bulk import one row at a time. Each row is a whole single
/// import: the quota gate first (the same one the add-recipe form asks,
/// which records the spend before the model is touched), then the
/// extraction, then the save. The first "no" from the allowance stops the
/// run — the rows after it are skipped, never tried around the gate.
///
/// The steps come in as functions so the order and the stopping rules are
/// tested without a model, a network or a screen.
class BulkImportRunner {
  /// May one more extraction go ahead? Has recorded the spend when it says
  /// yes. Asked once per row, immediately before that row's extraction.
  final Future<bool> Function() gate;
  final Future<RecipeEntity> Function(BulkCandidate candidate) extract;
  final Future<void> Function(RecipeEntity recipe) save;

  /// The extraction the gate paid for produced a recipe.
  final void Function() delivered;

  /// Whether this kind of row may be imported at all (its way in is
  /// switched on in the console); a row that may not is skipped, unpaid.
  final bool Function(BulkCandidate candidate) allowed;

  BulkImportRunner({
    required this.gate,
    required this.extract,
    required this.save,
    required this.delivered,
    required this.allowed,
  });

  bool _cancelled = false;

  /// Stops after the row that is running now; the rest are skipped.
  void cancel() => _cancelled = true;

  /// Imports [items] in order, reporting every row's change through
  /// [onStatus] (its index into [items]).
  Future<BulkStopReason> run(
    List<BulkCandidate> items,
    void Function(int index, BulkRowStatus status) onStatus,
  ) async {
    void skipFrom(int start) {
      for (var i = start; i < items.length; i++) {
        onStatus(i, BulkRowStatus.skipped);
      }
    }

    for (var i = 0; i < items.length; i++) {
      if (_cancelled) {
        skipFrom(i);
        return BulkStopReason.cancelled;
      }
      final item = items[i];
      if (!allowed(item)) {
        onStatus(i, BulkRowStatus.skipped);
        continue;
      }
      if (!await gate()) {
        skipFrom(i);
        return BulkStopReason.quota;
      }
      onStatus(i, BulkRowStatus.running);
      try {
        final recipe = await extract(item);
        delivered();
        await save(recipe);
        onStatus(i, BulkRowStatus.done);
      } catch (e) {
        onStatus(i, BulkRowStatus.failed);
        if (isStandingRefusal(e)) {
          skipFrom(i + 1);
          return e is AppException && e.type == AppErrorType.quotaExceeded
              ? BulkStopReason.quota
              : BulkStopReason.refused;
        }
      }
    }
    return BulkStopReason.none;
  }
}
