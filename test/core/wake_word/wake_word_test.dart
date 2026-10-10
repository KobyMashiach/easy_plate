import 'package:easy_plate/core/wake_word/wake_word_phrases.dart';
import 'package:easy_plate/core/wake_word/wake_word_service.dart';
import 'package:easy_plate/core/wake_word/wake_word_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const phrases = WakeWordPhrases.all;

  group('matching', () {
    test('the greeting and the name, in every language', () {
      for (final said in [
        'היי שפי',
        'הי שפי',
        'Hey Shefi',
        'hey chefy',
        'هاي شيفي',
        'Hé Shefi',
        'Эй, Шефи',
        'хей шефи',
      ]) {
        expect(phrases.match(said), isNotNull, reason: said);
      }
    });

    test('what follows is the command', () {
      expect(phrases.match('היי שפי, מה לבשל היום?')?.command, 'מה לבשל היום');
      expect(
        phrases.match('Hey Shefi add milk to the list')?.command,
        'add milk to the list',
      );
      expect(phrases.match('hey shefi')?.command, '');
    });

    test('the wake words may come mid-sentence', () {
      expect(
        phrases.match('ok so hey shefi set a timer')?.command,
        'set a timer',
      );
    });

    test('run together as one word', () {
      expect(phrases.match('הישפי תוסיף ביצים')?.command, 'תוסיף ביצים');
    });

    test('the name alone, or the greeting alone, is not a wake', () {
      expect(phrases.match('אמרתי לשפי שזה טעים'), isNull);
      expect(phrases.match('the shefi app is nice'), isNull);
      expect(phrases.match('hey how are you'), isNull);
      expect(phrases.match('ok chef'), isNull);
      expect(phrases.match(''), isNull);
    });

    test('vowel points and punctuation are ignored', () {
      expect(phrases.match('הַיי שֶׁפִי!'), isNotNull);
      expect(WakeWordPhrases.normalize('  Hey,   SHEFI!! '), 'hey shefi');
    });
  });

  group('when to listen', () {
    ({String mode, bool paused}) decide({
      bool enabled = true,
      bool background = true,
      bool flagsOpen = true,
      bool sessionReady = true,
      bool permissionGranted = true,
      bool appResumed = true,
      bool android = true,
      bool held = false,
    }) => WakeWordService.decide(
      enabled: enabled,
      background: background,
      flagsOpen: flagsOpen,
      sessionReady: sessionReady,
      permissionGranted: permissionGranted,
      appResumed: appResumed,
      android: android,
      held: held,
    );

    test('every condition is required', () {
      expect(decide().mode, 'background');
      expect(decide(enabled: false).mode, 'off');
      expect(decide(flagsOpen: false).mode, 'off');
      expect(decide(sessionReady: false).mode, 'off');
      expect(decide(permissionGranted: false).mode, 'off');
    });

    test('Android keeps listening when closed only if asked to', () {
      expect(decide(appResumed: false).mode, 'background');
      expect(decide(background: false).mode, 'foreground');
      expect(decide(background: false, appResumed: false).mode, 'off');
    });

    test('iOS listens only while the app is open', () {
      expect(decide(android: false).mode, 'foreground');
      expect(decide(android: false, appResumed: false).mode, 'off');
    });

    test('a hold pauses only while the app is in front', () {
      expect(decide(held: true).paused, isTrue);
      expect(decide(held: true, appResumed: false).paused, isFalse);
    });
  });

  test('settings survive a round trip and default to off', () {
    const off = WakeWordSettings();
    expect(off.enabled, isFalse);
    expect(off.background, isTrue);
    final on = off.copyWith(enabled: true, background: false);
    expect(WakeWordSettings.fromJson(on.toJson()), on);
    expect(WakeWordSettings.fromJson(const {}), off);
  });
}
