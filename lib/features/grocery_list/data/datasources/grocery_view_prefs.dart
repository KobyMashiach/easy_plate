import 'package:flutter/foundation.dart';

import '../../../../core/hive/user_scope.dart';
import 'active_grocery_list_store.dart';

/// How the grocery list is laid out on this device — for now, whether the
/// lines are grouped by supermarket aisle.
///
/// A view choice, not list data: it is never synced, and two people sharing
/// a list each keep their own. Kept in the box that already holds this
/// device's open list.
class GroceryViewPrefs {
  GroceryViewPrefs._();
  static final instance = GroceryViewPrefs._();

  static const _aisleKey = 'aisleSort';

  /// Read once and then followed by the page; false until the box answers.
  final ValueNotifier<bool> byAisle = ValueNotifier(false);

  /// The account scope the value was read for: another account signing in
  /// on this phone reads its own.
  int? _loadedFor;

  Future<void> load() async {
    final generation = UserScope().generation;
    if (_loadedFor == generation) return;
    _loadedFor = generation;
    byAisle.value = false;
    try {
      final box = await UserScope().open<String>(
        HiveActiveGroceryListStore.boxName,
      );
      byAisle.value = box.get(_aisleKey) == '1';
    } catch (e) {
      debugPrint('Grocery view prefs read failed: $e');
    }
  }

  Future<void> setByAisle(bool value) async {
    byAisle.value = value;
    try {
      final box = await UserScope().open<String>(
        HiveActiveGroceryListStore.boxName,
      );
      await box.put(_aisleKey, value ? '1' : '0');
    } catch (e) {
      debugPrint('Grocery view prefs write failed: $e');
    }
  }
}
