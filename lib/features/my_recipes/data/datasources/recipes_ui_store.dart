import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/hive/user_scope.dart';
import '../../domain/entities/recipe_entity.dart';

/// How often, and how lately, one recipe was cooked on this device.
@immutable
class CookRecord {
  final String recipeId;
  final int count;
  final DateTime lastAt;

  const CookRecord(this.recipeId, {required this.count, required this.lastAt});

  Map<String, Object> toJson() => {
    'count': count,
    'lastAt': lastAt.millisecondsSinceEpoch,
  };

  static CookRecord? fromJson(String recipeId, Object? json) {
    if (json is! Map) return null;
    final count = json['count'];
    final lastAt = json['lastAt'];
    if (count is! int || count < 1 || lastAt is! int) return null;
    return CookRecord(
      recipeId,
      count: count,
      lastAt: DateTime.fromMillisecondsSinceEpoch(lastAt),
    );
  }
}

/// The recipes for the "recently cooked" row: newest cook first, only those
/// still in [recipes] (a deleted recipe's record is ignored, not shown).
List<RecipeEntity> recentlyCooked(
  Map<String, CookRecord> history,
  List<RecipeEntity> recipes, {
  int limit = 10,
}) {
  final byId = {for (final r in recipes) r.id: r};
  final records =
      history.values.where((h) => byId.containsKey(h.recipeId)).toList()
        ..sort((a, b) => b.lastAt.compareTo(a.lastAt));
  return [for (final h in records.take(limit)) byId[h.recipeId]!];
}

/// The recipes for the "most cooked" row: cooked at least [minCount] times,
/// most first, the more recent breaking a tie. One cook does not make a
/// favourite, and the row would only repeat the recent one.
List<RecipeEntity> mostCooked(
  Map<String, CookRecord> history,
  List<RecipeEntity> recipes, {
  int limit = 10,
  int minCount = 2,
}) {
  final byId = {for (final r in recipes) r.id: r};
  final records =
      history.values
          .where((h) => h.count >= minCount && byId.containsKey(h.recipeId))
          .toList()
        ..sort((a, b) {
          final byCount = b.count.compareTo(a.count);
          return byCount != 0 ? byCount : b.lastAt.compareTo(a.lastAt);
        });
  return [for (final h in records.take(limit)) byId[h.recipeId]!];
}

/// [history] with one more cook of [recipeId] at [at], trimmed to the
/// [keep] most recent records so the box cannot grow without bound.
Map<String, CookRecord> withCook(
  Map<String, CookRecord> history,
  String recipeId,
  DateTime at, {
  int keep = 200,
}) {
  final previous = history[recipeId];
  final next = {
    ...history,
    recipeId: CookRecord(
      recipeId,
      count: (previous?.count ?? 0) + 1,
      lastAt: at,
    ),
  };
  if (next.length <= keep) return next;
  final newest = next.values.toList()
    ..sort((a, b) => b.lastAt.compareTo(a.lastAt));
  return {for (final r in newest.take(keep)) r.recipeId: r};
}

/// Small per-account memories of the recipe screens: which recipes were
/// cooked and when (the recently / most cooked rows), and the book a recipe
/// was last added to (offered first next time).
///
/// On this device only, per account through [UserScope] (wiped on sign-out
/// with every other scoped box); never synced, never sent anywhere. Stored
/// as JSON strings so no generated adapter is needed.
class RecipesUiStore {
  static final RecipesUiStore instance = RecipesUiStore._();
  RecipesUiStore._();

  static const boxName = 'recipesUiBox';
  static const _cooksKey = 'cookHistory';
  static const _lastBookKey = 'lastBookId';

  /// Moves on after every write, so a row on screen can read again.
  final ValueNotifier<int> revision = ValueNotifier(0);

  Future<Map<String, CookRecord>> cookHistory() async {
    try {
      final box = await UserScope().open<String>(boxName);
      final raw = box.get(_cooksKey);
      if (raw == null) return const {};
      final json = jsonDecode(raw);
      if (json is! Map) return const {};
      final records = <String, CookRecord>{};
      for (final entry in json.entries) {
        final record = CookRecord.fromJson('${entry.key}', entry.value);
        if (record != null) records[record.recipeId] = record;
      }
      return records;
    } catch (e) {
      debugPrint('Cook history read failed: $e');
      return const {};
    }
  }

  /// One more cook of [recipeId], now.
  Future<void> recordCook(String recipeId) async {
    try {
      final next = withCook(await cookHistory(), recipeId, clock.now());
      final box = await UserScope().open<String>(boxName);
      await box.put(
        _cooksKey,
        jsonEncode({for (final r in next.values) r.recipeId: r.toJson()}),
      );
      revision.value++;
    } catch (e) {
      debugPrint('Cook history write failed: $e');
    }
  }

  Future<String?> lastBookId() async {
    try {
      final box = await UserScope().open<String>(boxName);
      return box.get(_lastBookKey);
    } catch (e) {
      debugPrint('Last book read failed: $e');
      return null;
    }
  }

  Future<void> setLastBookId(String bookId) async {
    try {
      final box = await UserScope().open<String>(boxName);
      await box.put(_lastBookKey, bookId);
    } catch (e) {
      debugPrint('Last book write failed: $e');
    }
  }
}
