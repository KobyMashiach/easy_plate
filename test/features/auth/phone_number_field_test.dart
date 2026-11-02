import 'package:easy_plate/core/utils/i18n/strings.g.dart';
import 'package:easy_plate/features/auth/domain/phone_number.dart';
import 'package:easy_plate/features/auth/presentation/widgets/link_credential_sheets.dart';
import 'package:easy_plate/features/auth/presentation/widgets/phone_number_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.he));

  Future<PhoneFieldController> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final controller = PhoneFieldController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: PhoneNumberField(controller: controller),
            ),
          ),
        ),
      ),
    );
    return controller;
  }

  testWidgets('dashes and letters never reach the field', (tester) async {
    final controller = await pump(tester);
    await tester.enterText(find.byType(TextField), '050-824-7743x');
    expect(controller.text, '0508247743');
    expect(readPhoneField(controller).phone, '+972508247743');
  });

  testWidgets('the code menu sits left of the number in Hebrew too', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text('+972'), findsOneWidget);
    final menu = tester.getCenter(find.text('+972'));
    final field = tester.getCenter(find.byType(TextField));
    expect(menu.dx, lessThan(field.dx));
    expect(find.text('0501234567'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an autofilled +33 number switches the menu to France', (
    tester,
  ) async {
    final controller = await pump(tester);
    await tester.enterText(find.byType(TextField), '+33612345678');
    await tester.pump();
    expect(controller.country.value.iso, 'FR');
    expect(controller.text, '612345678');
    expect(find.text('+33'), findsOneWidget);
  });

  testWidgets('the field starts on Israel', (tester) async {
    final controller = await pump(tester);
    expect(controller.country.value, PhoneCountry.israel);
  });

  testWidgets('the code menu searches by name and by code', (tester) async {
    final controller = await pump(tester);
    await tester.tap(find.text('+972'));
    await tester.pumpAndSettle();
    expect(find.text(t.auth.countrySearch), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, 'צרפ');
    await tester.pumpAndSettle();
    expect(find.text('צרפת'), findsOneWidget);
    expect(find.text('ישראל'), findsNothing);

    await tester.enterText(find.byType(TextField).last, 'germ');
    await tester.pumpAndSettle();
    expect(find.text('גרמניה'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, '+44');
    await tester.pumpAndSettle();
    expect(find.text('בריטניה'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, 'zzz');
    await tester.pumpAndSettle();
    expect(find.text(t.auth.countryNotFound), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, 'אוקר');
    await tester.pumpAndSettle();
    await tester.tap(find.text('אוקראינה'));
    await tester.pumpAndSettle();
    expect(controller.country.value.iso, 'UA');
    expect(find.text('+380'), findsOneWidget);
  });
}
