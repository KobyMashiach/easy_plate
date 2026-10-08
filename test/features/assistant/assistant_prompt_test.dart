import 'package:easy_plate/features/assistant/domain/assistant_prompt.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the prompt carries the strict scope and the exact deflection', () {
    final p = AssistantPrompt.system(
      snapshot: 'Today: 2026-10-06',
      language: 'he',
      offTopicReply: 'רק מטבח',
    );
    expect(p, contains('Scope (strict)'));
    expect(p, contains('"רק מטבח"'));
    expect(p, contains('do you like pizza?'));
    expect(p, contains('Today: 2026-10-06'));
  });
}
