import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';

import '../constants/app_enums.dart';

/// The language chosen before anyone is signed in.
///
/// Deliberately *not* user-scoped: [UserPreferencesEntity] lives in a per-account
/// box that cannot be opened until auth resolves, but the splash and the login
/// have to render in some language before that. This box is device-wide and
/// holds nothing but the language.
///
/// Once an account is signed in, its own stored language takes over.
class DeviceLocaleStore {
  static final DeviceLocaleStore _instance = DeviceLocaleStore._internal();
  factory DeviceLocaleStore() => _instance;
  DeviceLocaleStore._internal();

  static const boxName = 'deviceSettingsBox';
  static const _languageKey = 'language';

  /// String rather than a model, so the box needs no adapter and can be opened
  /// before [AdaptersController] has done anything.
  Future<Box<String>> _open() => Hive.openBox<String>(boxName);

  /// Null when the user has never chosen one — the caller then falls back to
  /// the device locale.
  Future<AppLanguage?> read() async {
    try {
      final stored = (await _open()).get(_languageKey);
      if (stored == null) return null;
      return AppLanguage.values.where((l) => l.name == stored).firstOrNull;
    } catch (e) {
      debugPrint('Device language read failed: $e');
      return null;
    }
  }

  Future<void> write(AppLanguage language) async {
    try {
      await (await _open()).put(_languageKey, language.name);
    } catch (e) {
      debugPrint('Device language write failed: $e');
    }
  }
}
