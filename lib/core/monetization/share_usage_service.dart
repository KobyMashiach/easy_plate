import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';

import '../hive/user_scope.dart';

/// How many recipes this account shared in the current calendar week
/// (Monday-based ISO week), kept per account on the device. The free-tier
/// allowance is read against it; Premium never asks.
class ShareUsageService {
  static final ShareUsageService _instance = ShareUsageService._internal();
  factory ShareUsageService() => _instance;
  ShareUsageService._internal();

  static const boxName = 'shareUsageBox';

  /// "2026-W41": the bucket a share lands in.
  static String weekKey(DateTime at) {
    final day = DateTime.utc(at.year, at.month, at.day);
    // The Thursday of the same Monday-based week decides the ISO year and
    // week: it is the ordinal of that Thursday within its year.
    final thursday = day.add(Duration(days: 4 - day.weekday));
    final dayOfYear =
        thursday.difference(DateTime.utc(thursday.year, 1, 1)).inDays + 1;
    final week = (dayOfYear - 1) ~/ 7 + 1;
    return '${thursday.year}-W${week.toString().padLeft(2, '0')}';
  }

  Future<Box<int>?> _box() async {
    try {
      return await UserScope().open<int>(boxName);
    } catch (e) {
      debugPrint('Share usage box unavailable: $e');
      return null;
    }
  }

  Future<int> recipeSharesThisWeek() async {
    final box = await _box();
    return box?.get(weekKey(DateTime.now())) ?? 0;
  }

  Future<void> recordRecipeShare() async {
    final box = await _box();
    if (box == null) return;
    final key = weekKey(DateTime.now());
    await box.put(key, (box.get(key) ?? 0) + 1);
  }
}
