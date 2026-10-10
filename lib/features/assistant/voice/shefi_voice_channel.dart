import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/i18n/strings.g.dart';
import 'shefi_voice_runner.dart';

/// `easy_plate/shefi_voice`: where a system assistant's request reaches
/// Shefi. The Siri intent (ShefiVoiceBridge.swift) calls `ask` on the app's
/// own engine when it is alive, or on a short-lived headless engine started
/// for the request (see `shefi_voice_headless.dart`); the Android side is
/// prepared the same way for Gemini.
class ShefiVoiceChannel {
  static const _channel = MethodChannel('easy_plate/shefi_voice');

  static ShefiVoiceRunner? _runner;

  /// Answers requests with [runner] from now on.
  static void bind(ShefiVoiceRunner runner) {
    _runner = runner;
    _channel.setMethodCallHandler(_handle);
  }

  static Future<Object?> _handle(MethodCall call) async {
    final args = call.arguments;
    final runner = _runner;
    final sessionId = args is Map ? args['sessionId'] as String? : null;
    if (call.method == 'end') {
      if (sessionId != null) runner?.endConversation(sessionId);
      return null;
    }
    if (call.method != 'ask') return null;
    final text = args is Map ? (args['text'] as String? ?? '') : '';
    if (runner == null) {
      return sessionId == null
          ? t.voiceAssistants.failed
          : {'reply': t.voiceAssistants.failed, 'end': true};
    }
    final signedIn = FirebaseAuth.instance.currentUser != null;
    // Siri asks one-off and expects the sentence; the Android panel holds
    // a conversation and also needs to know when it is over.
    if (sessionId == null) return runner.ask(text, signedIn: signedIn);
    final turn = await runner.converse(
      text,
      signedIn: signedIn,
      sessionId: sessionId,
    );
    return {'reply': turn.reply, 'end': turn.end};
  }

  /// The headless engine tells the native side it can take the request.
  static Future<void> ready() async {
    try {
      await _channel.invokeMethod<void>('ready');
    } catch (e) {
      debugPrint('Shefi voice ready failed: $e');
    }
  }
}
