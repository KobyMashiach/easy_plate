import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../core/constants/api_config.dart';
import '../../../core/network/ai_auth_header.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/utils/i18n/strings.g.dart';
import '../domain/assistant_text.dart';

/// Talking to the assistant and hearing it back: speech recognition for the
/// input and text-to-speech for the replies, both through the platform's own
/// engines (Apple's and Google's), in the app's language.
///
/// Nothing is recorded or kept by the app: recognition hands back text, and
/// the audio never reaches our servers.
class AssistantVoice {
  final SpeechToText _stt = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  /// Plays the cloud voice; the device engine above is the fallback.
  final AudioPlayer _player = AudioPlayer();
  final Dio _speech = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      responseType: ResponseType.bytes,
      headers: const {'Content-Type': 'application/json'},
    ),
  );

  /// Which utterance is current: a newer one, or a stop, retires an older
  /// request that was still downloading.
  int _utterance = 0;

  bool _sttReady = false;
  bool _ttsReady = false;

  /// True while the microphone is open.
  final listening = ValueNotifier<bool>(false);

  /// True while a reply is being read out.
  final speaking = ValueNotifier<bool>(false);

  /// Whether the reply to the current turn is read out: true for a turn
  /// that was spoken, false for a typed one. A conversation is only a
  /// conversation when the user talks.
  final speakReplies = ValueNotifier<bool>(false);

  /// Null until [prepare] ran; false means the device has no recognizer or
  /// the permission was refused.
  bool? available;

  static String get _languageCode => LocaleSettings.currentLocale.languageCode;

  /// BCP-47 for text-to-speech, the recognizer's underscore form otherwise.
  static String ttsLocale([String? code]) => switch (code ?? _languageCode) {
    'he' => 'he-IL',
    'ar' => 'ar-SA',
    'fr' => 'fr-FR',
    'ru' => 'ru-RU',
    _ => 'en-US',
  };

  static String sttLocale([String? code]) =>
      ttsLocale(code).replaceAll('-', '_');

  /// Asks for the microphone and speech permissions on first use.
  Future<bool> prepare() async {
    if (_sttReady) return available ?? false;
    try {
      available = await _stt.initialize(
        onStatus: (status) {
          // The recognizer stops on its own after silence or a time limit.
          if (status == 'done' || status == 'notListening') {
            listening.value = false;
          }
        },
        onError: (_) => listening.value = false,
      );
    } catch (e) {
      debugPrint('Speech recognition unavailable: $e');
      available = false;
    }
    _sttReady = true;
    return available ?? false;
  }

  /// Opens the microphone. [onText] gets every partial transcript as the
  /// user speaks and the final one when they stop, with [isFinal] true.
  Future<bool> listen(
    void Function(String text, {required bool isFinal}) onText,
  ) async {
    if (!await prepare()) return false;
    await _tts.stop();
    speaking.value = false;
    listening.value = true;
    try {
      await _stt.listen(
        listenOptions: SpeechListenOptions(
          localeId: sttLocale(),
          partialResults: true,
          cancelOnError: true,
          listenMode: ListenMode.dictation,
          // Stops on its own after three quiet seconds, or after a minute
          // of talking.
          pauseFor: const Duration(seconds: 3),
          listenFor: const Duration(seconds: 45),
        ),
        onResult: (result) {
          onText(result.recognizedWords, isFinal: result.finalResult);
          if (result.finalResult) listening.value = false;
        },
      );
      return true;
    } catch (e) {
      debugPrint('Listen failed: $e');
      listening.value = false;
      return false;
    }
  }

  Future<void> stopListening() async {
    if (!listening.value) return;
    listening.value = false;
    try {
      await _stt.stop();
    } catch (_) {}
  }

  Future<void> _prepareTts() async {
    if (_ttsReady) return;
    _ttsReady = true;
    try {
      await _tts.awaitSpeakCompletion(true);
      _tts.setStartHandler(() => speaking.value = true);
      _tts.setCompletionHandler(() => speaking.value = false);
      _tts.setCancelHandler(() => speaking.value = false);
      _tts.setErrorHandler((_) => speaking.value = false);
    } catch (e) {
      debugPrint('Text-to-speech unavailable: $e');
    }
  }

  /// Reads [text] out loud when replies are wanted. The reply's cards are
  /// not read: they are on the screen. Google's cloud voice first (the
  /// natural one, chosen per language in the console); the device's own
  /// engine when the console turns the cloud off or the call fails.
  Future<void> speak(String text) async {
    // Words only: markdown, bullets and symbols are not read out.
    final trimmed = AssistantText.speech(text);
    if (!speakReplies.value || trimmed.isEmpty) return;
    final utterance = ++_utterance;
    await stopSpeaking(keepTurn: true);
    speaking.value = true;
    if (cloudVoiceEnabled && await _speakCloud(trimmed, utterance)) return;
    if (utterance != _utterance) return;
    await _speakDevice(trimmed);
  }

  /// The console's switch: `tts_cloud_enabled`, and only behind the proxy,
  /// where the speak function lives.
  static bool get cloudVoiceEnabled =>
      ApiConfig.usesProxy &&
      FirebaseService().remoteBool(FirebaseService.ttsCloudEnabledKey);

  Future<bool> _speakCloud(String text, int utterance) async {
    try {
      final headers = await aiProxyAuthHeader();
      final response = await _speech.post<List<int>>(
        ApiConfig.speakUrl,
        data: {'text': text, 'lang': _languageCode},
        options: Options(headers: headers),
      );
      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) return false;
      if (utterance != _utterance) return true;
      // just_audio plays files and streams, not bytes: the clip lands in
      // the temp directory under its utterance number.
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/shefi_$utterance.mp3');
      await file.writeAsBytes(bytes, flush: true);
      if (utterance != _utterance) return true;
      await _player.setFilePath(file.path);
      await _player.play();
      // play() resolves when the clip ends (or is stopped).
      if (utterance == _utterance) speaking.value = false;
      file.delete().catchError((_) => file);
      return true;
    } catch (e) {
      debugPrint('Cloud voice failed, device voice instead: $e');
      return false;
    }
  }

  Future<void> _speakDevice(String text) async {
    await _prepareTts();
    try {
      await _tts.stop();
      await _tts.setLanguage(ttsLocale());
      await _tts.setSpeechRate(0.5);
      speaking.value = true;
      await _tts.speak(text);
    } catch (e) {
      debugPrint('Speak failed: $e');
      speaking.value = false;
    }
  }

  Future<void> stopSpeaking({bool keepTurn = false}) async {
    if (!keepTurn) _utterance++;
    speaking.value = false;
    try {
      await _player.stop();
    } catch (_) {}
    try {
      await _tts.stop();
    } catch (_) {}
  }

  Future<void> dispose() async {
    await stopListening();
    await stopSpeaking();
    await _player.dispose();
    listening.dispose();
    speaking.dispose();
    speakReplies.dispose();
  }
}
