import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/hive/user_scope.dart';

/// Which of the account's grocery lists is open on this device.
///
/// Local on purpose, not in the synced preferences: two people sharing an
/// account shop from different lists, and a phone should reopen the list it
/// was last on. Per account through [UserScope], like every other box.
///
/// [changes] lets a list created elsewhere — from a recipe's page — become
/// the open one on the groceries tab, which is alive in an IndexedStack.
abstract class ActiveGroceryListStore {
  Future<String?> read();
  Future<void> write(String listId);
  Stream<String> get changes;
}

class HiveActiveGroceryListStore implements ActiveGroceryListStore {
  static final HiveActiveGroceryListStore instance =
      HiveActiveGroceryListStore._();
  HiveActiveGroceryListStore._();

  static const boxName = 'groceryUiBox';
  static const _key = 'activeListId';

  final _changes = StreamController<String>.broadcast();

  @override
  Stream<String> get changes => _changes.stream;

  @override
  Future<String?> read() async {
    try {
      final box = await UserScope().open<String>(boxName);
      return box.get(_key);
    } catch (e) {
      debugPrint('Active grocery list read failed: $e');
      return null;
    }
  }

  @override
  Future<void> write(String listId) async {
    try {
      final box = await UserScope().open<String>(boxName);
      await box.put(_key, listId);
    } catch (e) {
      debugPrint('Active grocery list write failed: $e');
    }
    _changes.add(listId);
  }
}

/// For tests: the same contract, in memory.
class InMemoryActiveGroceryListStore implements ActiveGroceryListStore {
  String? value;
  final _changes = StreamController<String>.broadcast();

  @override
  Stream<String> get changes => _changes.stream;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String listId) async {
    value = listId;
    _changes.add(listId);
  }
}
