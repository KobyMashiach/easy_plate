import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';

import '../features/features_flags.dart';
import '../services/device_locale_store.dart';
import '../utils/rebuild_everything.dart';

/// The in-app text size. The phone's own font setting stays ignored (the
/// layouts clipped under it, 2026-11-02); this is the app's replacement:
/// three steps the screens are checked against, chosen in Settings.
enum AppTextSize {
  normal(1.0),
  large(1.15),
  extraLarge(1.3)
  ;

  final double scale;
  const AppTextSize(this.scale);

  static AppTextSize fromName(String? name) =>
      values.where((s) => s.name == name).firstOrNull ?? normal;
}

/// Holds the chosen [AppTextSize] and hands the MaterialApp builder the
/// scaler to apply.
///
/// Per device, like the theme's device copy: a bigger phone or a parent's
/// tablet each wants its own, and the account preferences have no field for
/// it (a new one would need generated Hive code).
class TextSizeController extends ChangeNotifier {
  static final TextSizeController _instance = TextSizeController._internal();
  factory TextSizeController() => _instance;
  TextSizeController._internal();

  static const _key = 'textSize';

  AppTextSize _size = AppTextSize.normal;

  AppTextSize get size => _size;

  /// What the app is drawn at. Only the flag being on lets a stored choice
  /// through: with it off the app is exactly as before, at 1.0.
  TextScaler get scaler => scalerFor(_size, FeaturesFlags.textSize.isEnabled);

  /// Pure, for tests.
  static TextScaler scalerFor(AppTextSize size, bool enabled) =>
      !enabled || size == AppTextSize.normal
      ? TextScaler.noScaling
      : TextScaler.linear(size.scale);

  /// Before `runApp`, so the first frame is already at the chosen size.
  Future<void> init() async {
    try {
      _size = AppTextSize.fromName((await _box()).get(_key));
    } catch (e) {
      debugPrint('Text size read failed: $e');
    }
  }

  Future<void> setSize(AppTextSize size) async {
    if (size == _size) return;
    _size = size;
    notifyListeners();
    // Text measured once and cached (header extents, painters held in
    // state) has to be measured again at the new size.
    rebuildEverything();
    try {
      await (await _box()).put(_key, size.name);
    } catch (e) {
      debugPrint('Text size write failed: $e');
    }
  }

  /// The same device-wide, string-only box as the theme and the language.
  Future<Box<String>> _box() => Hive.openBox<String>(DeviceLocaleStore.boxName);
}
