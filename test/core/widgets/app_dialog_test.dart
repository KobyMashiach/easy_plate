import 'package:easy_plate/core/widgets/app_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A page with a button that opens the popup under test and records the answer.
Widget host({required Future<void> Function(BuildContext context) onTap}) {
  return MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () => onTap(context),
          child: const Text('open'),
        ),
      ),
    ),
  );
}

void main() {
  group('show', () {
    testWidgets('confirm resolves true, cancel resolves false', (tester) async {
      bool? answer;
      await tester.pumpWidget(
        host(
          onTap: (context) async {
            answer = await const AppDialog.warning(
              title: 'למחוק?',
              message: 'אין דרך חזרה',
              confirmLabel: 'מחיקה',
              cancelLabel: 'ביטול',
              destructive: true,
            ).show(context);
          },
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('למחוק?'), findsOneWidget);
      await tester.tap(find.text('מחיקה'));
      await tester.pumpAndSettle();
      expect(answer, isTrue);
      expect(find.text('למחוק?'), findsNothing);

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ביטול'));
      await tester.pumpAndSettle();
      expect(answer, isFalse);
    });

    testWidgets('a popup with no cancel offers the common OK', (tester) async {
      await tester.pumpWidget(
        host(
          onTap: (context) async {
            await const AppDialog.error(message: 'משהו השתבש').show(context);
          },
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('הבנתי'), findsOneWidget);
      expect(find.text('ביטול'), findsNothing);
    });

    testWidgets('content is shown between the message and the buttons', (
      tester,
    ) async {
      final controller = TextEditingController();
      await tester.pumpWidget(
        host(
          onTap: (context) async {
            await AppDialog.general(
              title: 'שם',
              content: TextField(controller: controller),
              confirmLabel: 'שמירה',
            ).show(context);
          },
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'ספר חדש');
      await tester.tap(find.text('שמירה'));
      await tester.pumpAndSettle();
      expect(controller.text, 'ספר חדש');
    });
  });

  group('notify', () {
    testWidgets('floats in, then leaves on its own', (tester) async {
      await tester.pumpWidget(
        host(
          onTap: (context) async {
            const AppDialog.success(message: 'נשמר').notify(context);
          },
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('נשמר'), findsOneWidget);
      // The page underneath stays usable — nothing modal was pushed.
      expect(find.text('open'), findsOneWidget);

      await tester.pump(AppDialog.noticeDuration);
      await tester.pumpAndSettle();
      expect(find.text('נשמר'), findsNothing);
    });

    testWidgets('a new notice takes the place of the one still showing', (
      tester,
    ) async {
      var n = 0;
      await tester.pumpWidget(
        host(
          onTap: (context) async {
            AppDialog.info(message: 'הודעה ${++n}').notify(context);
          },
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('הודעה 1'), findsNothing);
      expect(find.text('הודעה 2'), findsOneWidget);
    });

    testWidgets('a tap dismisses it early', (tester) async {
      await tester.pumpWidget(
        host(
          onTap: (context) async {
            const AppDialog.success(message: 'נשמר').notify(context);
          },
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('נשמר'));
      await tester.pumpAndSettle();
      expect(find.text('נשמר'), findsNothing);
    });
  });
}
