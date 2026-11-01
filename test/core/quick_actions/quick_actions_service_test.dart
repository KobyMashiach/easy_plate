import 'package:easy_plate/core/features/features_flags.dart';
import 'package:easy_plate/core/home_widgets/home_widget_launch.dart';
import 'package:easy_plate/core/quick_actions/quick_actions_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => FeaturesFlags.overrides = null);

  List<String> types() =>
      QuickActionsService.items().map((i) => i.type).toList();

  test('the four shortcuts, in order, with an icon and a title each', () {
    FeaturesFlags.overrides = {};
    final items = QuickActionsService.items();
    expect(items.map((i) => i.type), [
      QuickActionsService.assistant,
      QuickActionsService.groceryAdd,
      QuickActionsService.receipt,
      QuickActionsService.support,
    ]);
    for (final item in items) {
      expect(item.localizedTitle, isNotEmpty);
      expect(item.icon, startsWith('qa_'));
    }
  });

  test('hidden in the console, there is no menu at all', () {
    FeaturesFlags.overrides = {
      FeaturesFlags.quickActions: FeatureFlagValue.hidden,
    };
    expect(types(), isEmpty);
  });

  test('a hidden feature loses its shortcut, a Premium-only one keeps it', () {
    FeaturesFlags.overrides = {
      FeaturesFlags.assistant: FeatureFlagValue.premiumOnly,
      FeaturesFlags.receiptScan: FeatureFlagValue.hidden,
    };
    expect(types(), [
      QuickActionsService.assistant,
      QuickActionsService.groceryAdd,
      QuickActionsService.support,
    ]);
  });

  test('each shortcut is a launch the main screen acts on', () {
    final shefi = QuickActionsService.launchFor(QuickActionsService.assistant)!;
    expect(shefi.action, HomeWidgetAction.assistant);
    expect(shefi.fromShortcut, isTrue);
    expect(shefi.voice, isTrue);

    final grocery = QuickActionsService.launchFor(
      QuickActionsService.groceryAdd,
    )!;
    expect(grocery.action, HomeWidgetAction.grocery);
    expect(grocery.add, isTrue);
    expect(grocery.listId, isNull);

    expect(
      QuickActionsService.launchFor(QuickActionsService.receipt)!.action,
      HomeWidgetAction.receipt,
    );
    expect(
      QuickActionsService.launchFor(QuickActionsService.support)!.action,
      HomeWidgetAction.support,
    );
    expect(QuickActionsService.launchFor('nope'), isNull);
  });
}
