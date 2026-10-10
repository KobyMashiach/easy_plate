import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';

import '../services/device_locale_store.dart';

/// The "Hey Shefi" switches. Device-wide, in the settings box beside the
/// pre-sign-in language: the microphone belongs to this phone, and a second
/// device of the same account should not start listening because the first
/// one was told to.
class WakeWordSettings {
  /// Off until the user turns it on: an always-open microphone is never a
  /// default.
  final bool enabled;

  /// Android only: keep listening after the app is closed, through a
  /// foreground service with a permanent notification. iOS has no such
  /// thing; there Siri covers the closed app.
  final bool background;

  const WakeWordSettings({this.enabled = false, this.background = true});

  WakeWordSettings copyWith({bool? enabled, bool? background}) =>
      WakeWordSettings(
        enabled: enabled ?? this.enabled,
        background: background ?? this.background,
      );

  Map<String, Object> toJson() => {
    'enabled': enabled,
    'background': background,
  };

  factory WakeWordSettings.fromJson(Map<String, Object?> json) =>
      WakeWordSettings(
        enabled: json['enabled'] == true,
        background: json['background'] != false,
      );

  @override
  bool operator ==(Object other) =>
      other is WakeWordSettings &&
      other.enabled == enabled &&
      other.background == background;

  @override
  int get hashCode => Object.hash(enabled, background);
}

class WakeWordSettingsStore {
  static final WakeWordSettingsStore _instance =
      WakeWordSettingsStore._internal();
  factory WakeWordSettingsStore() => _instance;
  WakeWordSettingsStore._internal();

  static const _key = 'wakeWord';

  final listenable = ValueNotifier<WakeWordSettings>(const WakeWordSettings());

  WakeWordSettings get value => listenable.value;

  Future<Box<String>> _open() =>
      Hive.openBox<String>(DeviceLocaleStore.boxName);

  Future<WakeWordSettings> read() async {
    try {
      final stored = (await _open()).get(_key);
      if (stored != null) {
        final decoded = jsonDecode(stored);
        if (decoded is Map) {
          listenable.value = WakeWordSettings.fromJson(
            decoded.cast<String, Object?>(),
          );
        }
      }
    } catch (e) {
      debugPrint('Wake word settings read failed: $e');
    }
    return listenable.value;
  }

  Future<void> write(WakeWordSettings settings) async {
    listenable.value = settings;
    try {
      await (await _open()).put(_key, jsonEncode(settings.toJson()));
    } catch (e) {
      debugPrint('Wake word settings write failed: $e');
    }
  }
}
