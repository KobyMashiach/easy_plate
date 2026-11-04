import 'package:easy_plate/core/utils/i18n/strings.g.dart';
import 'package:easy_plate/features/assistant/domain/assistant_tools.dart';
import 'package:easy_plate/features/assistant/presentation/pages/assistant_page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.he));

  test('a running tool is named in the app language, never by its id', () {
    expect(
      assistantWorkingLabel(AssistantTools.addGroceryItems),
      'מבצע: קניות',
    );
    expect(assistantWorkingLabel(AssistantTools.planMeal), 'מבצע: תפריטים');
    // No area of the app to name: just "thinking".
    expect(
      assistantWorkingLabel(AssistantTools.convertMeasurement),
      t.assistant.thinking,
    );
    expect(assistantWorkingLabel('some_future_tool'), t.assistant.thinking);

    // Every declared tool: no snake_case identifier reaches the screen.
    for (final declaration in AssistantTools.declarations) {
      final name = declaration['name'] as String;
      final label = assistantWorkingLabel(name);
      expect(label, isNot(contains('_')), reason: name);
      expect(label, isNot(contains(name.replaceAll('_', ' '))), reason: name);
    }
  });
}
