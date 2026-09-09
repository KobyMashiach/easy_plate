import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';

import '../hive/user_scope.dart';
import '../sync/cloud_sync_service.dart';
import '../sync/user_cloud_collection.dart';
import 'daily_usage_model.dart';
import 'trusted_clock.dart';

/// Today's spend against the daily quotas, for the signed-in account.
///
/// A [ChangeNotifier] so the counters on the community and ingestion screens
/// follow it live. The record lives in a uid-scoped Hive box and is mirrored
/// through [CloudSyncService.dailyUsage]; the day it applies to is decided by
/// [TrustedClock], never by the phone's own date.
///
/// Loaded lazily, on first use, rather than by the auth session: the scope
/// switch is what makes the box readable, and every caller goes through
/// [ensureLoaded] first.
class DailyUsageService extends ChangeNotifier {
  static final DailyUsageService _instance = DailyUsageService._internal();
  factory DailyUsageService() => _instance;
  DailyUsageService._internal();

  DailyUsageModel? _usage;
  String? _uid;
  Future<void>? _loading;

  /// Test seam: the mirror is the singleton's unless one is injected.
  UserCloudCollection<DailyUsageModel>? cloudOverride;

  bool get isLoaded => _usage != null;

  DailyUsageModel get _current => _usage ?? DailyUsageModel.empty(TrustedClock().today);

  int get sharedViewsToday => _current.viewedSharedIds.length;
  int get aiExtractionsToday => _current.aiExtractions;
  bool hasViewedShared(String sharedId) => _current.viewedSharedIds.contains(sharedId);

  /// Reads the account's record, once per account. Cheap to call repeatedly:
  /// after the first load it only checks whether the day has rolled over.
  Future<void> ensureLoaded() async {
    final uid = UserScope().uid;
    if (uid == null) return;
    if (_uid == uid && _usage != null) {
      _rollover();
      return;
    }
    return _loading ??= _load(uid).whenComplete(() => _loading = null);
  }

  Future<void> _load(String uid) async {
    try {
      final box = await _box();
      final stored = box.get(DailyUsageModel.storageKey);
      _usage = (stored ?? DailyUsageModel.empty(TrustedClock().today)).forDay(TrustedClock().today);
      _uid = uid;
      notifyListeners();
    } catch (e) {
      debugPrint('Daily usage load failed: $e');
    }
  }

  Future<void> recordSharedView(String sharedId) async {
    await ensureLoaded();
    if (hasViewedShared(sharedId)) return;
    await _write(_current.copyWith(viewedSharedIds: [..._current.viewedSharedIds, sharedId]));
  }

  Future<void> recordAiExtraction() async {
    await ensureLoaded();
    await _write(_current.copyWith(aiExtractions: _current.aiExtractions + 1));
  }

  /// Drops yesterday's record the first time it is read today. Notifies, so a
  /// banner left open across midnight refreshes on its own.
  void _rollover() {
    final rolled = _current.forDay(TrustedClock().today);
    if (identical(rolled, _usage)) return;
    _usage = rolled;
    notifyListeners();
  }

  Future<void> _write(DailyUsageModel usage) async {
    _usage = usage;
    notifyListeners();
    try {
      final box = await _box();
      await box.put(DailyUsageModel.storageKey, usage);
    } catch (e) {
      debugPrint('Daily usage save failed: $e');
    }
    // Not awaited, like every other mirror push: offline it would wait for a
    // server that is not there.
    unawaited((cloudOverride ?? CloudSyncService().dailyUsage).push(usage));
  }

  Future<Box<DailyUsageModel>> _box() => UserScope().open<DailyUsageModel>(DailyUsageModel.hiveKey);

  /// Drops the in-memory record. Called on sign-out so the next account never
  /// starts from the previous one's count, and by tests.
  void reset() {
    _usage = null;
    _uid = null;
    notifyListeners();
  }
}
