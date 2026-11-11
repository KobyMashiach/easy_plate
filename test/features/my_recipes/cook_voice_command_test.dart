import 'package:easy_plate/features/my_recipes/domain/cook_voice_command.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  CookVoiceCommand? match(String s) => CookVoiceCommands.match(s);

  group('the five languages', () {
    test('next', () {
      for (final s in ['הבא', 'next', 'suivant', 'дальше', 'التالي']) {
        expect(match(s), CookVoiceCommand.next, reason: s);
      }
    });
    test('previous', () {
      for (final s in ['הקודם', 'back', 'précédent', 'назад', 'السابق']) {
        expect(match(s), CookVoiceCommand.previous, reason: s);
      }
    });
    test('repeat', () {
      for (final s in ['שוב', 'again', 'encore', 'повтори', 'مرة أخرى']) {
        expect(match(s), CookVoiceCommand.repeat, reason: s);
      }
    });
    test('timer', () {
      for (final s in [
        'טיימר',
        'start timer',
        'minuteur',
        'таймер',
        'المؤقت',
      ]) {
        expect(match(s), CookVoiceCommand.timer, reason: s);
      }
    });
  });

  test('case, punctuation and marks do not matter', () {
    expect(match('Next!'), CookVoiceCommand.next);
    expect(match('  NEXT step. '), CookVoiceCommand.next);
    expect(match('Ещё раз'), CookVoiceCommand.repeat);
    expect(match('еще раз'), CookVoiceCommand.repeat);
    expect(match('הַבָּא'), CookVoiceCommand.next);
    expect(match('التَّالِي'), CookVoiceCommand.next);
    expect(match('« suivant »'), CookVoiceCommand.next);
  });

  test('a few polite words around the command are fine', () {
    expect(match('okay next please'), CookVoiceCommand.next);
    expect(match('אוקיי הבא'), CookVoiceCommand.next);
    expect(match('go back'), CookVoiceCommand.previous);
  });

  test('a long sentence is talk, not a command', () {
    expect(match('what do we do next with the onions'), isNull);
    expect(match('אני לא יודע מה הבא בתור'), isNull);
  });

  test('the last command said wins', () {
    expect(match('back no next'), CookVoiceCommand.next);
    expect(match('next no back'), CookVoiceCommand.previous);
  });

  test('a longer phrase is not split into its words', () {
    // "start timer" is one command, not "start" + "timer" fighting.
    expect(match('start the timer'), CookVoiceCommand.timer);
    expect(match('say that again'), CookVoiceCommand.repeat);
  });

  test('words that merely contain a command do not match', () {
    expect(match('nextdoor'), isNull);
    expect(match('feedback'), isNull);
    expect(match('timers are fun to watch'), isNull);
    expect(match(''), isNull);
    expect(match('hello'), isNull);
  });
}
