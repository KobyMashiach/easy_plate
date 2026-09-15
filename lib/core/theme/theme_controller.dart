import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_ce/hive.dart';

import '../constants/app_colors.dart';
import '../services/device_locale_store.dart';

/// What the user asked for. [system] follows the phone; the other two pin it.
enum AppThemeMode {
  system,
  light,
  dark;

  ThemeMode get material => switch (this) {
        AppThemeMode.system => ThemeMode.system,
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark => ThemeMode.dark,
      };
}

/// The one writer of `AppColors.palette`.
///
/// Holds the chosen mode, resolves it against the phone's own setting, swaps
/// the palette and tells the app to rebuild. Device-wide rather than per
/// account, like the pre-sign-in language: the login screen has to be dark
/// too, before there is an account to read a preference from.
///
/// Listeners get one notification per *effective* change — choosing "dark"
/// while the phone is already dark under "system" is silent.
class ThemeController extends ChangeNotifier {
  static final ThemeController _instance = ThemeController._internal();
  factory ThemeController() => _instance;
  ThemeController._internal();

  static const _key = 'themeMode';

  AppThemeMode _mode = AppThemeMode.system;

  AppThemeMode get mode => _mode;
  bool get isDark => AppColors.isDark;

  /// Reads the stored choice and applies it. Before `runApp`, so the first
  /// frame is already the right colour.
  Future<void> init() async {
    try {
      final stored = (await _box()).get(_key);
      _mode = AppThemeMode.values.where((m) => m.name == stored).firstOrNull ?? AppThemeMode.system;
    } catch (e) {
      debugPrint('Theme read failed: $e');
    }
    _apply(notify: false);
  }

  Future<void> setMode(AppThemeMode mode) async {
    if (mode == _mode) return;
    _mode = mode;
    _apply(notify: true);
    try {
      await (await _box()).put(_key, mode.name);
    } catch (e) {
      debugPrint('Theme write failed: $e');
    }
  }

  /// The phone flipped its own setting; only matters under [AppThemeMode.system].
  void onPlatformBrightnessChanged() {
    if (_mode == AppThemeMode.system) _apply(notify: true);
  }

  /// Whether [mode] would come out dark right now — what the switch animation
  /// needs to know before it commits.
  bool resolvesDark(AppThemeMode mode) => switch (mode) {
        AppThemeMode.light => false,
        AppThemeMode.dark => true,
        AppThemeMode.system =>
          WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark,
      };

  void _apply({required bool notify}) {
    final dark = resolvesDark(_mode);
    if (dark == AppColors.isDark && notify) return;
    AppColors.palette = dark ? AppPalette.dark : AppPalette.light;
    // Status bar icons have to flip with the page behind them.
    SystemChrome.setSystemUIOverlayStyle(
      dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
    );
    if (!notify) return;
    notifyListeners();
    _rebuildEverything();
  }

  /// Marks every element in the tree dirty, so the whole app repaints in the
  /// new colours in the very next frame.
  ///
  /// Needed because `AppColors` is read through plain static getters, not an
  /// inherited widget: nothing subscribes to it. The `ListenableBuilder` in
  /// `main.dart` rebuilds `MaterialApp`, and that reaches the widgets that
  /// depend on `Theme.of` — but the tabs in the `IndexedStack`, pages under
  /// the router and anything else whose parent hands it the same widget
  /// instance are skipped, and stayed in the old theme until something else
  /// rebuilt them. This is the same sweep hot reload does, minus the
  /// `reassemble` calls that would reset states.
  void _rebuildEverything() {
    final root = WidgetsBinding.instance.rootElement;
    if (root == null) return;
    void visit(Element element) {
      element.markNeedsBuild();
      element.visitChildren(visit);
    }
    visit(root);
  }

  /// Same device-wide box as the language, and the same string-only shape so
  /// it needs no adapter.
  Future<Box<String>> _box() => Hive.openBox<String>(DeviceLocaleStore.boxName);
}
