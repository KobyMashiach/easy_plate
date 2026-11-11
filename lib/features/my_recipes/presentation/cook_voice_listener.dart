import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:hive_ce/hive.dart';

import '../../../core/services/device_locale_store.dart';
import '../../../core/wake_word/wake_word_service.dart';
import '../../assistant/presentation/assistant_voice.dart';
import '../domain/cook_voice_command.dart';

/// Why listening stopped on its own, for the page to say so.
enum CookVoiceProblem { unavailable }

/// Keeps the microphone open while cook mode is on screen and turns short
/// spoken commands into [CookVoiceCommand]s.
///
/// The platform recognizer (through Shefi's [AssistantVoice]) stops after a
/// few quiet seconds, so this restarts it in a loop. The loop pauses:
/// - while the step is being read aloud, so it does not hear itself (and
///   because opening the microphone stops the voice);
/// - while the app is not in the foreground;
/// - for good when the screen closes or the cook turns it off.
/// While it runs, the "Hey Shefi" listener is held, so the two never fight
/// over the microphone.
///
/// Nothing is recorded: the recognizer hands back text, which is matched
/// on the device and dropped.
class CookVoiceListener with WidgetsBindingObserver {
  final void Function(CookVoiceCommand command) onCommand;

  CookVoiceListener({required this.onCommand});

  static const _holdReason = 'cookVoice';
  static const _storeKey = 'cookVoiceNext';

  final AssistantVoice _voice = AssistantVoice();

  /// The cook's switch, remembered on this device.
  final enabled = ValueNotifier<bool>(false);

  /// The microphone is open right now.
  final listening = ValueNotifier<bool>(false);

  /// The last command understood, for the indicator.
  final lastHeard = ValueNotifier<CookVoiceCommand?>(null);

  final problem = ValueNotifier<CookVoiceProblem?>(null);

  bool _foreground = true;
  bool _loopRunning = false;
  bool _speaking = false;
  bool _disposed = false;

  /// Bumped on every pause or stop, so a loop from before it ends.
  int _generation = 0;

  /// Reads the remembered switch and starts if it was on.
  Future<void> init() async {
    WidgetsBinding.instance.addObserver(this);
    try {
      final box = await Hive.openBox<String>(DeviceLocaleStore.boxName);
      enabled.value = box.get(_storeKey) == 'on';
    } catch (_) {}
    if (enabled.value && !_disposed) _start();
  }

  Future<void> setEnabled(bool on) async {
    if (on == enabled.value) return;
    enabled.value = on;
    problem.value = null;
    on ? _start() : await _pause();
    try {
      final box = await Hive.openBox<String>(DeviceLocaleStore.boxName);
      await box.put(_storeKey, on ? 'on' : 'off');
    } catch (_) {}
  }

  /// Reads [text] aloud with Shefi's voice, the microphone closed for it.
  Future<void> speak(String text) async {
    if (_disposed) return;
    _speaking = true;
    await _voice.stopListening();
    try {
      _voice.speakReplies.value = true;
      await _voice.speak(text);
    } finally {
      _speaking = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final foreground = state == AppLifecycleState.resumed;
    if (foreground == _foreground) return;
    _foreground = foreground;
    if (foreground) {
      if (enabled.value) _start();
    } else {
      unawaited(_pause());
    }
  }

  void _start() {
    if (_disposed || _loopRunning || !_foreground || !enabled.value) return;
    WakeWordService().hold(_holdReason);
    unawaited(_loop(++_generation));
  }

  Future<void> _pause() async {
    _generation++;
    if (!_disposed) listening.value = false;
    await _voice.stopListening();
    await _voice.stopSpeaking();
    WakeWordService().release(_holdReason);
  }

  bool _current(int generation) =>
      !_disposed && generation == _generation && enabled.value && _foreground;

  Future<void> _loop(int generation) async {
    _loopRunning = true;
    var quickEnds = 0;
    try {
      if (!await _voice.prepare()) {
        if (!_current(generation)) return;
        // No recognizer, or the microphone was refused: the switch goes
        // back off and the page says why.
        problem.value = CookVoiceProblem.unavailable;
        enabled.value = false;
        await _pause();
        return;
      }
      while (_current(generation)) {
        if (_speaking) {
          await Future<void>.delayed(const Duration(milliseconds: 200));
          continue;
        }
        final started = DateTime.now();
        final ended = Completer<void>();
        void onListening() {
          if (!_voice.listening.value && !ended.isCompleted) ended.complete();
        }

        _voice.listening.addListener(onListening);
        var handled = false;
        final ok = await _voice.listen((words, {required isFinal}) {
          if (handled || !_current(generation)) return;
          // Partial results too: "next" acts as soon as it is heard, not
          // three quiet seconds later.
          final command = CookVoiceCommands.match(words);
          if (command == null) return;
          handled = true;
          lastHeard.value = command;
          onCommand(command);
          unawaited(_voice.stopListening());
        });
        if (_disposed) break;
        listening.value = ok && _current(generation);
        if (ok) {
          // The recognizer's own limit is under a minute; the timeout only
          // guards against a "done" that never comes.
          await ended.future.timeout(
            const Duration(seconds: 60),
            onTimeout: () {},
          );
        }
        if (_disposed) break;
        _voice.listening.removeListener(onListening);
        listening.value = false;
        if (!_current(generation)) break;

        // A session that ends at once is an error (busy recognizer, no
        // network): back off instead of spinning, up to five seconds.
        final lasted = DateTime.now().difference(started);
        quickEnds = (!ok || lasted < const Duration(seconds: 1))
            ? quickEnds + 1
            : 0;
        final wait = Duration(
          milliseconds: quickEnds == 0
              ? 250
              : (500 * quickEnds).clamp(500, 5000).toInt(),
        );
        await Future<void>.delayed(wait);
      }
    } finally {
      _loopRunning = false;
      // A switch flipped back on during the last wait starts a fresh loop.
      if (!_disposed && _current(_generation) && generation != _generation) {
        _start();
      }
    }
  }

  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    // Marked first: the loop checks it after every wait and touches none
    // of the notifiers below once it is set.
    _disposed = true;
    _generation++;
    WakeWordService().release(_holdReason);
    enabled.dispose();
    listening.dispose();
    lastHeard.dispose();
    problem.dispose();
    await _voice.dispose();
  }
}
