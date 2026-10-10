import 'package:easy_plate/core/features/features_flags.dart';
import 'package:easy_plate/core/utils/i18n/strings.g.dart';
import 'package:easy_plate/features/assistant/voice/shefi_voice_runner.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => FeaturesFlags.overrides = null);

  test('the voice door has its own flag and rides on Shefi', () {
    FeaturesFlags.overrides = {
      FeaturesFlags.voiceAssistants: FeatureFlagValue.enabled,
      FeaturesFlags.assistant: FeatureFlagValue.enabled,
    };
    expect(ShefiVoiceRunner.gateMessage(), isNull);

    FeaturesFlags.overrides = {
      FeaturesFlags.voiceAssistants: FeatureFlagValue.hidden,
      FeaturesFlags.assistant: FeatureFlagValue.enabled,
    };
    expect(ShefiVoiceRunner.gateMessage(), t.voiceAssistants.unavailable);

    FeaturesFlags.overrides = {
      FeaturesFlags.voiceAssistants: FeatureFlagValue.enabled,
      FeaturesFlags.assistant: FeatureFlagValue.comingSoon,
    };
    expect(ShefiVoiceRunner.gateMessage(), t.voiceAssistants.unavailable);
  });

  test('voice rules ask for short spoken answers in the app language', () {
    final rules = ShefiVoiceRunner.voiceRules('he');
    expect(rules, contains('"he"'));
    expect(rules, contains('No lists, no markdown'));
    expect(rules, contains('Deleting anything'));
  });

  test('a clear goodbye ends the floating conversation without the model', () {
    for (final said in [
      'סיום שיחה',
      'ביי!',
      'זהו, תודה',
      'Bye',
      'end conversation',
      'пока',
    ]) {
      expect(ShefiVoiceRunner.isGoodbye(said), isTrue, reason: said);
    }
    // A bare "no" is the model's call: it only ends after "anything else?".
    for (final said in ['לא', 'no', 'תוסיף ביצים', 'מה ההבדל']) {
      expect(ShefiVoiceRunner.isGoodbye(said), isFalse, reason: said);
    }
  });

  test('conversation rules ask "anything else?" and mark the end', () {
    final rules = ShefiVoiceRunner.voiceRules('he', conversation: true);
    expect(rules, contains(ShefiVoiceRunner.endMarker));
    expect(rules, contains('anything else'));
    expect(
      ShefiVoiceRunner.voiceRules('he'),
      isNot(contains(ShefiVoiceRunner.endMarker)),
    );
  });
}
