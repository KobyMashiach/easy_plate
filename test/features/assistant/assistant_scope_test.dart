import 'package:easy_plate/features/assistant/domain/assistant_prompt.dart';
import 'package:easy_plate/features/assistant/domain/assistant_scope.dart';
import 'package:easy_plate/features/assistant/domain/assistant_tools.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a scoped conversation only gets the tools of its item', () {
    for (final scope in [
      const AssistantScope.recipe(id: 'r', title: 'Shakshuka'),
      const AssistantScope.mealPlan(id: 'p', title: 'Week'),
      const AssistantScope.groceryList(id: 'l', title: 'Shabbat'),
    ]) {
      final tools = AssistantTools.declarationsFor(scope.toolNames);
      final names = tools.map((d) => d['name'] as String).toSet();
      expect(names, scope.toolNames, reason: scope.kind.name);
      expect(names, isNot(contains(AssistantTools.deleteRecipe)));
      expect(names, isNot(contains(AssistantTools.importRecipe)));
    }
    // Every scoped tool really exists in the declarations.
    final all = AssistantTools.declarations.map((d) => d['name']).toSet();
    for (final kind in AssistantScopeKind.values) {
      final scope = AssistantScope(kind: kind, id: 'x', title: 'X');
      expect(all.containsAll(scope.toolNames), isTrue, reason: kind.name);
    }
  });

  test('the recipe scope keeps the list and plan write tools out', () {
    const scope = AssistantScope.recipe(id: 'r', title: 'X');
    expect(scope.toolNames, isNot(contains(AssistantTools.addGroceryItems)));
    expect(scope.toolNames, isNot(contains(AssistantTools.removePlannedItem)));
    expect(scope.toolNames, contains(AssistantTools.groceryListFromRecipe));
    expect(scope.toolNames, contains(AssistantTools.planMeal));
  });

  test(
    'the scope lock names the item, carries its details and the refusal',
    () {
      const scope = AssistantScope.groceryList(id: 'l1', title: 'Shabbat');
      final section = scope.promptSection(
        details: '- [ ] milk',
        offTopicReply: 'Only Shabbat here.',
      );
      expect(section, contains('ONE grocery list only'));
      expect(section, contains('"Shabbat" (id: l1)'));
      expect(section, contains('- [ ] milk'));
      expect(section, contains('"Only Shabbat here."'));
      final system = AssistantPrompt.system(
        snapshot: 'snap',
        language: 'he',
        offTopicReply: 'nope',
        scope: section,
      );
      expect(system, endsWith(section));
      expect(
        AssistantPrompt.system(
          snapshot: 'snap',
          language: 'he',
          offTopicReply: 'nope',
        ),
        isNot(contains('SCOPE LOCK')),
      );
    },
  );
}
