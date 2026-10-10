import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../features/features_flags.dart';
import '../home_widgets/home_widget_launch.dart';
import '../services/auth_session_service.dart';
import '../utils/i18n/strings.g.dart';
import 'wake_word_channel.dart';
import 'wake_word_phrases.dart';
import 'wake_word_settings.dart';

/// "Hey Shefi": decides when the native listener runs, and turns a detection
/// into an open Shefi conversation.
///
/// Listening needs every one of these at once: the user switched it on (a
/// device setting, off by default), the console has `ff_wake_word`,
/// `ff_assistant` and `ff_assistant_voice` open for this account, a signed-in
/// session past every gate, and the microphone permission. Then:
///
/// * Android with "also when closed": a microphone foreground service with a
///   permanent notification, alive after the app is swiped away.
/// * Otherwise only while the app is in the foreground.
///
/// Anything in the app that needs the microphone itself (the Shefi chat,
/// mainly) takes a [hold], which pauses the listener without forgetting it.
class WakeWordService with WidgetsBindingObserver {
  static final WakeWordService _instance = WakeWordService._internal();
  factory WakeWordService() => _instance;
  WakeWordService._internal();

  final WakeWordChannel _channel = WakeWordChannel();
  final WakeWordSettingsStore _settings = WakeWordSettingsStore();

  final Set<String> _holds = {};
  bool _bound = false;
  bool _resumed = true;

  /// The last microphone permission answer: `granted`, `denied`,
  /// `permanentlyDenied` or `unknown`. The settings page draws it.
  final permission = ValueNotifier<String>('unknown');

  /// What was last sent to the native side, so nothing is sent twice.
  String? _sent;

  bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;

  /// Wires the inputs. Called once from `main.dart` after the session exists.
  Future<void> bind() async {
    if (_bound || !WakeWordChannel.supported) return;
    _bound = true;
    _channel.onDetected = _onDetected;
    _channel.onBackgroundStopped = () => unawaited(setBackground(false));
    WidgetsBinding.instance.addObserver(this);
    _resumed =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    await _settings.read();
    permission.value = await _channel.permission();
    _settings.listenable.addListener(_apply);
    FeaturesFlags.listenable.addListener(_apply);
    AuthSessionService().addListener(_apply);
    LocaleSettings.getLocaleStream().listen((_) => _apply());
    _apply();
    await _takeSiriLaunch();
    await _takeBackgroundStop();
  }

  /// Pauses listening while [reason] holds the microphone.
  void hold(String reason) {
    if (_holds.add(reason)) _apply();
  }

  void release(String reason) {
    if (!_holds.remove(reason)) return;
    _apply();
    // The chat a detection opened has closed: listen again.
    if (_holds.isEmpty) unawaited(_channel.resumeAfterDetection());
  }

  /// Turns the feature on or off from the settings page, asking for the
  /// microphone first. Returns false when the permission was refused.
  Future<bool> setEnabled(bool on) async {
    if (on) {
      var status = await _channel.permission();
      if (status != 'granted') status = await _channel.requestPermission();
      permission.value = status;
      if (status != 'granted') return false;
    }
    await _settings.write(_settings.value.copyWith(enabled: on));
    return true;
  }

  Future<void> setBackground(bool on) =>
      _settings.write(_settings.value.copyWith(background: on));

  Future<bool> canOpenFromBackground() => _channel.canOpenFromBackground();
  Future<void> openBackgroundSettings() => _channel.openBackgroundSettings();
  Future<void> openAppSettings() => _channel.openAppSettings();

  /// Re-reads the permission (after a trip to the system settings).
  Future<void> refreshPermission() async {
    permission.value = await _channel.permission();
    _apply(force: true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final resumed = state == AppLifecycleState.resumed;
    if (resumed == _resumed) return;
    _resumed = resumed;
    if (resumed) {
      // Permission may have changed in the system settings meanwhile, and
      // Siri may have opened the app on the shortcut.
      unawaited(refreshPermission());
      unawaited(_takeSiriLaunch());
      unawaited(_takeBackgroundStop());
    }
    _apply();
  }

  /// The rule on its own, for tests: which mode the listener runs in, and
  /// whether it is paused.
  @visibleForTesting
  static ({String mode, bool paused}) decide({
    required bool enabled,
    required bool background,
    required bool flagsOpen,
    required bool sessionReady,
    required bool permissionGranted,
    required bool appResumed,
    required bool android,
    required bool held,
  }) {
    final allowed = enabled && flagsOpen && sessionReady && permissionGranted;
    final mode = !allowed
        ? 'off'
        : android && background
        ? 'background'
        : appResumed
        ? 'foreground'
        : 'off';
    // A hold is the app's own use of the microphone, which only happens
    // while it is in front: in the background the listener carries on.
    return (mode: mode, paused: held && appResumed);
  }

  static bool get flagsOpen =>
      FeaturesFlags.wakeWord.isEnabled &&
      FeaturesFlags.assistant.isEnabled &&
      FeaturesFlags.assistantVoice.isEnabled;

  void _apply({bool force = false}) {
    if (!_bound) return;
    final settings = _settings.value;
    final decision = decide(
      enabled: settings.enabled,
      background: settings.background,
      flagsOpen: flagsOpen,
      sessionReady: AuthSessionService().stage == AuthStage.ready,
      permissionGranted: permission.value == 'granted',
      appResumed: _resumed,
      android: _isAndroid,
      held: _holds.isNotEmpty,
    );
    final locale = LocaleSettings.currentLocale.languageCode;
    final signature = '${decision.mode}|${decision.paused}|$locale';
    if (!force && signature == _sent) return;
    _sent = signature;
    unawaited(
      _channel.configure(
        mode: decision.mode,
        paused: decision.paused,
        locale: _recognizerLocale(locale),
        phrases: WakeWordPhrases.all.toChannel(),
        texts: {
          'listeningTitle': t.wakeWord.notificationTitle,
          'listeningBody': t.wakeWord.notificationBody,
          'stop': t.wakeWord.notificationStop,
          'heardTitle': t.wakeWord.heardTitle,
          'heardBody': t.wakeWord.heardBody,
          'channelListening': t.wakeWord.channelListening,
          'channelHeard': t.wakeWord.channelHeard,
          'overlayListening': t.wakeWord.overlayListening,
          'overlayThinking': t.wakeWord.overlayThinking,
          'overlayAnswer': t.assistant.title,
          'overlayNoSpeech': t.wakeWord.overlayNoSpeech,
          'overlayFailed': t.voiceAssistants.failed,
          'overlayHint': t.wakeWord.overlayHint,
          'overlayTapToTalk': t.wakeWord.overlayTapToTalk,
        },
      ),
    );
  }

  static String _recognizerLocale(String code) => switch (code) {
    'he' => 'he-IL',
    'ar' => 'ar-SA',
    'fr' => 'fr-FR',
    'ru' => 'ru-RU',
    _ => 'en-US',
  };

  /// The native side has already paused itself. The chat opens through the
  /// same path a Shefi widget tap takes; once it is up it holds the
  /// microphone, and when it closes the release resumes listening. If it
  /// never opens (a gate said no), the check a moment later resumes it
  /// instead.
  void _onDetected(String command) {
    PendingHomeWidgetLaunch.notifier.value = HomeWidgetLaunch(
      HomeWidgetAction.assistant,
      {
        'voice': '1',
        'source': 'wake',
        if (command.isNotEmpty) 'prompt': command,
      },
    );
    Timer(const Duration(seconds: 3), () {
      if (_holds.isEmpty) unawaited(_channel.resumeAfterDetection());
    });
  }

  Future<void> _takeBackgroundStop() async {
    if (await _channel.takeBackgroundStop()) await setBackground(false);
  }

  Future<void> _takeSiriLaunch() async {
    if (await _channel.takePendingLaunch()) _onDetected('');
  }
}
