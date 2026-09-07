import 'package:easy_plate/core/services/app_update_service.dart';
import 'package:easy_plate/core/utils/i18n/strings.g.dart';
import 'package:easy_plate/core/widgets/update_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final service = AppUpdateService();

  tearDown(() => service.requirement.value = UpdateRequirement.none);

  Future<void> pump(WidgetTester tester, UpdateRequirement requirement) async {
    service.requirement.value = requirement;
    await tester.pumpWidget(
      TranslationProvider(
        child: const MaterialApp(
          home: UpdateGate(child: Scaffold(body: Text('the app'))),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('nothing is shown while the build is current', (tester) async {
    await pump(tester, UpdateRequirement.none);
    expect(find.text('the app'), findsOneWidget);
    expect(find.byKey(barrierKey), findsNothing);
  });

  testWidgets('a forced update offers no way out', (tester) async {
    await pump(tester, UpdateRequirement.forced);
    expect(find.text(t.update.forcedTitle), findsOneWidget);
    expect(find.text(t.update.updateNow), findsOneWidget);
    // The skip button is the whole difference between the two prompts.
    expect(find.text(t.update.later), findsNothing);
  });

  testWidgets('an optional update can be skipped', (tester) async {
    await pump(tester, UpdateRequirement.optional);
    expect(find.text(t.update.optionalTitle), findsOneWidget);
    expect(find.text(t.update.later), findsOneWidget);
  });

  testWidgets('the prompt sits over the app rather than replacing it', (tester) async {
    await pump(tester, UpdateRequirement.optional);
    expect(find.text('the app'), findsOneWidget);
    expect(find.byKey(barrierKey), findsOneWidget);
  });
}
