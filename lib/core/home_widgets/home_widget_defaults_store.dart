import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';

import '../services/device_locale_store.dart';
import 'home_widgets_snapshot.dart';

/// The widgets' defaults, kept in the device-wide settings box beside the
/// pre-sign-in language: a widget sits on this phone's home screen, so its
/// defaults are the phone's, not the account's.
class HomeWidgetDefaultsStore {
  static final HomeWidgetDefaultsStore _instance =
      HomeWidgetDefaultsStore._internal();
  factory HomeWidgetDefaultsStore() => _instance;
  HomeWidgetDefaultsStore._internal();

  static const _key = 'homeWidgetDefaults';

  final listenable = ValueNotifier<HomeWidgetDefaults>(
    const HomeWidgetDefaults(),
  );

  HomeWidgetDefaults get value => listenable.value;

  Future<Box<String>> _open() => Hive.openBox<String>(DeviceLocaleStore.boxName);

  Future<HomeWidgetDefaults> read() async {
    try {
      final stored = (await _open()).get(_key);
      if (stored != null) {
        final decoded = jsonDecode(stored);
        if (decoded is Map) {
          listenable.value = HomeWidgetDefaults.fromJson(
            decoded.cast<String, Object?>(),
          );
        }
      }
    } catch (e) {
      debugPrint('Home widget defaults read failed: $e');
    }
    return listenable.value;
  }

  Future<void> write(HomeWidgetDefaults defaults) async {
    listenable.value = defaults;
    try {
      await (await _open()).put(_key, jsonEncode(defaults.toJson()));
    } catch (e) {
      debugPrint('Home widget defaults write failed: $e');
    }
  }
}
