import 'package:easy_plate/features/my_recipes/domain/entities/recipe_entity.dart';
import 'package:easy_plate/features/my_recipes/domain/entities/recipe_ingredient_entity.dart';
import 'package:easy_plate/features/my_recipes/presentation/pages/cook_mode_page.dart';
import 'package:easy_plate/core/constants/app_enums.dart';
import 'package:easy_plate/core/services/cook_session_service.dart';
import 'package:easy_plate/core/widgets/cook_timer_banner.dart';
import 'package:easy_plate/core/utils/i18n/strings.g.dart';
import 'package:easy_plate/core/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final recipe = RecipeEntity(
    id: 'r1',
    title: 'Creamy Tuscan Salmon',
    createdAt: DateTime(2026),
    ingredients: const [
      RecipeIngredientEntity(
        name: 'Salmon fillets',
        amount: 4,
        unit: MeasurementUnit.unit,
      ),
      RecipeIngredientEntity(
        name: 'Heavy cream',
        amount: 200,
        unit: MeasurementUnit.milliliter,
      ),
      RecipeIngredientEntity(
        name: 'Baby spinach',
        amount: 100,
        unit: MeasurementUnit.gram,
      ),
    ],
    steps: const [
      'Pat the salmon dry and season it.',
      'Sear the salmon skin-side down for 4 minutes until golden.',
      'Add the cream and spinach, simmer and serve.',
    ],
  );

  // Deferred locale loading needs real async, outside the test's fake clock.
  setUpAll(() => LocaleSettings.setLocale(AppLocale.en));
  // The session is a singleton; each test starts from nothing.
  tearDown(CookSessionService().finishAll);

  Widget app() => TranslationProvider(
    child: MaterialApp(
      locale: const Locale('en'),
      home: CookModePage(recipe: recipe),
    ),
  );

  testWidgets('shows one step at a time with its ingredients and a timer', (
    tester,
  ) async {
    // A tall phone, so every card of a step is on screen without scrolling.
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.text('Pat the salmon dry and season it.'), findsOneWidget);
    expect(find.text('Step 1 of 3'), findsOneWidget);
    // The step names the salmon, so its amount is offered.
    expect(find.text('Salmon fillets'), findsOneWidget);
    expect(find.text('Heavy cream'), findsNothing);

    await tester.tap(find.text('Next step'));
    await tester.pumpAndSettle();
    expect(find.text('Step 2 of 3'), findsOneWidget);
    expect(find.text('04:00'), findsOneWidget);
    expect(find.text('04:00'), findsOneWidget);

    await tester.tap(find.text('Start timer'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('03:58'), findsOneWidget);
    expect(find.text('Pause'), findsOneWidget);

    // The timer keeps running on the next step and is pinned there.
    await tester.tap(find.text('Next step'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Step 3 of 3'), findsOneWidget);
    expect(find.text('Step 2'), findsOneWidget);
    expect(find.textContaining('/04:00'), findsOneWidget);
    expect(find.widgetWithText(ClayButton, 'Done cooking'), findsOneWidget);
    // Leaving the screen keeps the session and its timer alive.
    expect(CookSessionService().isActive, isTrue);
    expect(CookSessionService().hasRunningTimer, isTrue);
    // Pause it so the test ends with no pending periodic timer.
    CookSessionService().toggleTimer(recipe.id, 1);
    await tester.pump();
    expect(CookSessionService().hasRunningTimer, isFalse);
  });

  testWidgets('reopening lands on the saved step; done ends the session', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    CookSessionService().start(recipe);
    CookSessionService().setStep(recipe.id, 2);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(find.text('Step 3 of 3'), findsOneWidget);

    await tester.tap(find.widgetWithText(ClayButton, 'Done cooking'));
    await tester.pumpAndSettle();
    expect(find.text('Enjoy your meal!'), findsOneWidget);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(CookSessionService().isActive, isFalse);
  });

  testWidgets('a running timer shows as a banner on any other screen', (
    tester,
  ) async {
    CookSessionService().start(recipe);
    CookSessionService().toggleTimer(recipe.id, 1);
    await tester.pumpWidget(
      TranslationProvider(
        child: const MaterialApp(
          locale: Locale('en'),
          home: CookTimerBanner(child: Scaffold(body: Text('elsewhere'))),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('Step 2'), findsOneWidget);
    expect(find.text('03:57/04:00'), findsOneWidget);

    // On the cook screen itself the banner steps aside.
    CookSessionService().screenShown(recipe.id);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Step 2'), findsNothing);

    CookSessionService().toggleTimer(recipe.id, 1);
    await tester.pump();
  });

  testWidgets('two recipes cook at once; the banner stacks their timers', (
    tester,
  ) async {
    final second = RecipeEntity(
      id: 'r2',
      title: 'Garlic rice',
      createdAt: DateTime(2026),
      ingredients: const [],
      steps: const ['Simmer the rice for 12 minutes.'],
    );
    final service = CookSessionService();
    service.start(recipe);
    service.start(second);
    service.toggleTimer(recipe.id, 1);
    service.toggleTimer(second.id, 0);
    expect(service.sessions.length, 2);
    expect(service.activeTimers.length, 2);

    await tester.pumpWidget(
      TranslationProvider(
        child: const MaterialApp(
          locale: Locale('en'),
          home: CookTimerBanner(child: Scaffold(body: Text('elsewhere'))),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    // The front pill is the first recipe's; the second is behind it.
    expect(find.text('Creamy Tuscan Salmon'), findsOneWidget);
    expect(find.text('Garlic rice'), findsNothing);

    await tester.drag(find.text('Creamy Tuscan Salmon'), const Offset(0, -80));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Garlic rice'), findsOneWidget);
    expect(find.textContaining('/12:00'), findsOneWidget);

    // Finishing one recipe leaves the other cooking.
    service.finish(recipe.id);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(service.sessions.length, 1);
    expect(find.text('Garlic rice'), findsOneWidget);

    service.toggleTimer(second.id, 0);
    await tester.pump();
  });
}
