import 'dart:math';

import 'package:easy_plate/core/utils/i18n/strings.g.dart';
import 'package:easy_plate/features/assistant/presentation/assistant_suggestions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() => LocaleSettings.setLocale(AppLocale.he));

  test('five distinct, fully filled prompts, different per conversation', () {
    final a = AssistantSuggestions.pick(5, random: Random(1));
    final b = AssistantSuggestions.pick(5, random: Random(2));
    expect(a.length, 5);
    expect(a.toSet().length, 5);
    for (final p in [...a, ...b]) {
      expect(p, isNot(contains('{')));
    }
    expect(a, isNot(equals(b)));
  });

  test('the pool is far larger than what is shown', () {
    final seen = <String>{};
    for (var i = 0; i < 60; i++) {
      seen.addAll(AssistantSuggestions.pick(5, random: Random(i)));
    }
    expect(seen.length, greaterThan(100));
  });
}
