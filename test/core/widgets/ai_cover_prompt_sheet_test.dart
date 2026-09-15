import 'package:easy_plate/core/utils/i18n/strings.g.dart';
import 'package:easy_plate/core/widgets/ai_cover_prompt_sheet.dart';
import 'package:easy_plate/core/widgets/clay/clay.dart';
import 'package:easy_plate/features/recipe_ingestion/domain/usecases/generate_image_usecase.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.he));

  group('bookCoverPrompt', () {
    test('a theme and a subject are combined, the subject in front', () {
      final p = GenerateImageUseCase.bookCoverPrompt('ספר', theme: CoverTheme.indulgent, subject: 'המבורגר');
      expect(p, contains('featuring המבורגר, gloriously indulgent'));
      expect(p, contains('titled "ספר"'));
    });

    test('either alone still makes a cover, and blank text counts as none', () {
      expect(GenerateImageUseCase.bookCoverPrompt('b', theme: CoverTheme.kids), contains('kid-friendly'));
      expect(GenerateImageUseCase.bookCoverPrompt('b', subject: 'סושי'), contains('featuring סושי'));
      expect(GenerateImageUseCase.bookCoverPrompt('b', subject: '   '), contains('warm, inviting'));
    });
  });

  Future<String?> open(WidgetTester tester) async {
    String? result;
    await tester.pumpWidget(TranslationProvider(
      child: MaterialApp(
        locale: const Locale('he'),
        supportedLocales: AppLocaleUtils.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => result = await showCoverPromptSheet(context, bookTitle: 'שבת'),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return result;
  }

  ClayButton generateButton(WidgetTester tester) =>
      tester.widget<ClayButton>(find.widgetWithText(ClayButton, t.image.coverGenerate));

  testWidgets('nothing chosen means no button, a chip alone is enough', (tester) async {
    await open(tester);
    expect(generateButton(tester).onPressed, isNull);
    expect(find.text(t.image.coverRequired), findsOneWidget);

    await tester.tap(find.text(t.image.themeHealthy));
    await tester.pumpAndSettle();
    expect(generateButton(tester).onPressed, isNotNull);
    expect(find.text(t.image.coverRequired), findsNothing);

    // Tapping the chosen chip again clears it.
    await tester.tap(find.text(t.image.themeHealthy));
    await tester.pumpAndSettle();
    expect(generateButton(tester).onPressed, isNull);
  });

  testWidgets('chip plus text come back as one prompt', (tester) async {
    String? result;
    await tester.pumpWidget(TranslationProvider(
      child: MaterialApp(
        locale: const Locale('he'),
        supportedLocales: AppLocaleUtils.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => result = await showCoverPromptSheet(context, bookTitle: 'שבת'),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.image.themeIndulgent));
    await tester.enterText(find.byType(TextField), 'המבורגר');
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.image.coverGenerate));
    await tester.pumpAndSettle();
    expect(result, contains('featuring המבורגר, gloriously indulgent'));
  });
}
