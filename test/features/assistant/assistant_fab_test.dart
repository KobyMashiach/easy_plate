import 'package:easy_plate/core/utils/i18n/strings.g.dart';
import 'package:easy_plate/features/assistant/presentation/widgets/assistant_fab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() => LocaleSettings.setLocale(AppLocale.he));

  testWidgets('the floating pill shows the assistant name and a sparkle', (
    tester,
  ) async {
    await tester.pumpWidget(
      TranslationProvider(
        child: const MaterialApp(
          locale: Locale('he'),
          home: Scaffold(body: Center(child: AssistantFab())),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('העוזר'), findsOneWidget);
    expect(find.byIcon(Icons.auto_awesome_rounded), findsOneWidget);
  });
}
