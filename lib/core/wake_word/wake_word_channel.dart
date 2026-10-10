import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The native "Hey Shefi" listeners: `WakeWordChannel.kt` (a speech
/// recognizer loop, in the app or in a microphone foreground service) and
/// `WakeWordChannel.swift` (Apple's recognizer while the app is open, and the
/// Siri shortcut for when it is not).
///
/// Dart decides *whether* to listen; the native side only does it, and keeps
/// the last instruction on disk so an Android service that outlived the
/// engine still knows its words and its notification texts.
class WakeWordChannel {
  static const _channel = MethodChannel('easy_plate/wake_word');

  /// The wake words were heard (or Siri ran the shortcut). [command] is what
  /// followed them, empty when nothing did.
  void Function(String command)? onDetected;

  /// Android: the user pressed Stop on the listening notification.
  VoidCallback? onBackgroundStopped;

  WakeWordChannel() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'detected') {
        final args = call.arguments;
        final command = args is Map ? (args['command'] as String? ?? '') : '';
        onDetected?.call(command);
      } else if (call.method == 'backgroundStopped') {
        onBackgroundStopped?.call();
      }
      return null;
    });
  }

  static bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// Starts, updates or stops the listener in one call. [mode] is `off`,
  /// `foreground` (only while the app is visible) or `background` (Android:
  /// a foreground service that keeps going when the app is closed).
  /// [paused] keeps the configuration but releases the microphone, for the
  /// moments the app needs it itself.
  Future<void> configure({
    required String mode,
    required bool paused,
    required String locale,
    required Map<String, Object> phrases,
    required Map<String, String> texts,
  }) => _invoke('configure', {
    'mode': mode,
    'paused': paused,
    'locale': locale,
    'phrases': phrases,
    'texts': texts,
  });

  /// A detection paused the listener; the chat it opened has closed (or
  /// never opened), so it may listen again.
  Future<void> resumeAfterDetection() => _invoke('resumeAfterDetection');

  /// Android: whether Stop was pressed on the notification while no engine
  /// was alive to hear about it.
  Future<bool> takeBackgroundStop() async =>
      await _invoke<bool>('takeBackgroundStop') ?? false;

  /// Microphone (and, on iOS, speech recognition) permission: `granted`,
  /// `denied`, `permanentlyDenied` or `unknown`.
  Future<String> permission() async =>
      await _invoke<String>('permission') ?? 'unknown';

  /// Asks for it; returns the status afterwards.
  Future<String> requestPermission() async =>
      await _invoke<String>('requestPermission') ?? 'unknown';

  /// Android: whether a detection with the app closed may open it straight
  /// away ("display over other apps"). Without it a notification asks for a
  /// tap instead. Always true on iOS, where the question does not arise.
  Future<bool> canOpenFromBackground() async =>
      await _invoke<bool>('canOpenFromBackground') ?? true;

  /// Android: the system screen where that permission is granted.
  Future<void> openBackgroundSettings() => _invoke('openBackgroundSettings');

  /// The app's page in the system settings, for a permission refused for
  /// good.
  Future<void> openAppSettings() => _invoke('openAppSettings');

  /// iOS: a Siri run that opened the app before Dart was listening.
  Future<bool> takePendingLaunch() async =>
      await _invoke<bool>('takePendingLaunch') ?? false;

  Future<T?> _invoke<T>(String method, [Object? arguments]) async {
    if (!supported) return null;
    try {
      return await _channel.invokeMethod<T>(method, arguments);
    } catch (e) {
      debugPrint('Wake word $method failed: $e');
      return null;
    }
  }
}
