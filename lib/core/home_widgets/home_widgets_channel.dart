import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The platform side of the home-screen widgets: where the snapshot is
/// written, where the widgets' own writes queue up, and the launcher's
/// "add this widget" sheet on Android.
///
/// One small channel of our own rather than a package: the data lives in
/// the platform's shared store (SharedPreferences / app-group
/// UserDefaults), and both native sides are a few lines each. See
/// `HomeWidgetsChannel.kt` and `HomeWidgetsChannel.swift`.
class HomeWidgetsChannel {
  static const _channel = MethodChannel('easy_plate/home_widgets');

  /// Called when a widget wrote to the queue while the app is alive — a
  /// line added from the Android quick-add dialog, a tick on iOS — so the
  /// app applies it at once instead of on its next launch.
  VoidCallback? onPendingChanged;

  HomeWidgetsChannel() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'pendingChanged') onPendingChanged?.call();
      return null;
    });
  }

  static bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// Writes the snapshot and asks every placed widget to redraw.
  Future<void> publish(String snapshotJson) async {
    if (!_supported) return;
    try {
      await _channel.invokeMethod<void>('publish', {'snapshot': snapshotJson});
    } catch (e) {
      debugPrint('Home widgets publish failed: $e');
    }
  }

  /// Drops the snapshot (sign-out): the widgets show "sign in" and
  /// nothing of the account stays on the home screen.
  Future<void> clear() async {
    if (!_supported) return;
    try {
      await _channel.invokeMethod<void>('clear');
    } catch (e) {
      debugPrint('Home widgets clear failed: $e');
    }
  }

  /// The widgets' queued writes, oldest first.
  Future<List<Map<String, Object?>>> readPending() async {
    if (!_supported) return const [];
    try {
      final raw = await _channel.invokeMethod<String>('readPending');
      if (raw == null || raw.isEmpty) return const [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return [
        for (final entry in decoded)
          if (entry is Map) entry.cast<String, Object?>(),
      ];
    } catch (e) {
      debugPrint('Home widgets queue read failed: $e');
      return const [];
    }
  }

  /// Removes the entries the app has applied, by id, leaving anything
  /// that queued up meanwhile.
  Future<void> removePending(List<String> ids) async {
    if (!_supported || ids.isEmpty) return;
    try {
      await _channel.invokeMethod<void>('removePending', {'ids': ids});
    } catch (e) {
      debugPrint('Home widgets queue clear failed: $e');
    }
  }

  /// Android 8+: whether the launcher can be asked to place a widget.
  Future<bool> pinSupported() async {
    if (!_supported) return false;
    try {
      return await _channel.invokeMethod<bool>('pinSupported') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Asks the launcher to place [kind] (`assistant`, `grocery_add`,
  /// `grocery_list`, `today_menu`). True when the sheet was shown.
  Future<bool> pinWidget(String kind) async {
    if (!_supported) return false;
    try {
      return await _channel.invokeMethod<bool>('pinWidget', {'kind': kind}) ??
          false;
    } catch (e) {
      debugPrint('Home widgets pin failed: $e');
      return false;
    }
  }

  /// How many of each kind are on the home screen right now.
  Future<Map<String, int>> installedCounts() async {
    if (!_supported) return const {};
    try {
      final raw = await _channel.invokeMethod<Map<Object?, Object?>>(
        'installedCounts',
      );
      if (raw == null) return const {};
      return {
        for (final entry in raw.entries)
          if (entry.key is String && entry.value is int)
            entry.key as String: entry.value as int,
      };
    } catch (e) {
      debugPrint('Home widgets count failed: $e');
      return const {};
    }
  }
}
