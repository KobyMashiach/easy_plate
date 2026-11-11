import 'package:flutter/foundation.dart';

import '../../../../core/hive/user_scope.dart';
import '../../../grocery_list/data/datasources/active_grocery_list_store.dart';

/// The day the planner was last filled on, on this device: the board opens
/// there next time instead of on Sunday, so planning the rest of the week
/// picks up where it stopped.
///
/// Per device and per account, like the open grocery list — two people on
/// one account plan different days. Kept in the same small UI box as that
/// list (a plain string box already scoped to the account and wiped on sign
/// out) rather than a box of its own.
class PlannerMemoryStore {
  PlannerMemoryStore._();
  static final instance = PlannerMemoryStore._();

  static const _dayKey = 'plannerLastWeekday';

  Future<int?> lastWeekday() async {
    try {
      final box = await UserScope().open<String>(
        HiveActiveGroceryListStore.boxName,
      );
      final day = int.tryParse(box.get(_dayKey) ?? '');
      return day == null || day < 0 || day > 6 ? null : day;
    } catch (e) {
      debugPrint('Planner memory read failed: $e');
      return null;
    }
  }

  Future<void> rememberWeekday(int weekday) async {
    try {
      final box = await UserScope().open<String>(
        HiveActiveGroceryListStore.boxName,
      );
      await box.put(_dayKey, '$weekday');
    } catch (e) {
      debugPrint('Planner memory write failed: $e');
    }
  }
}
