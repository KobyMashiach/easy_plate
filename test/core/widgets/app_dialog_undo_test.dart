import 'package:easy_plate/core/utils/i18n/strings.g.dart';
import 'package:easy_plate/core/widgets/app_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget host(void Function(BuildContext context) onTap) => MaterialApp(
  home: Scaffold(
    body: Builder(
      builder: (context) => TextButton(
        onPressed: () => onTap(context),
        child: const Text('open'),
      ),
    ),
  ),
);

void main() {
  testWidgets('a notice without an action is unchanged and closes once', (
    tester,
  ) async {
    var closed = 0;
    await tester.pumpWidget(
      host(
        (context) => const AppDialog.success(
          message: 'saved',
        ).notify(context, onClosed: () => closed++),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump();
    expect(find.text('saved'), findsOneWidget);
    expect(find.byType(TextButton), findsOneWidget); // only the host's
    await tester.pump(AppDialog.noticeDuration);
    await tester.pumpAndSettle();
    expect(find.text('saved'), findsNothing);
    expect(closed, 1);
  });

  testWidgets('undo runs onUndo and never onCommit', (tester) async {
    var undone = 0;
    var committed = 0;
    await tester.pumpWidget(
      host(
        (context) => AppDialog.undo(
          context,
          message: 'deleted',
          onUndo: () => undone++,
          onCommit: () => committed++,
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.recipe.undo));
    await tester.pumpAndSettle();
    expect(find.text('deleted'), findsNothing);
    expect(undone, 1);
    expect(committed, 0);
  });

  testWidgets('left alone, the undo notice commits when it goes', (
    tester,
  ) async {
    var committed = 0;
    await tester.pumpWidget(
      host(
        (context) => AppDialog.undo(
          context,
          message: 'deleted',
          onUndo: () {},
          onCommit: () => committed++,
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(AppDialog.undoDuration);
    await tester.pumpAndSettle();
    expect(committed, 1);
  });

  testWidgets('a newer notice commits the one it replaces', (tester) async {
    var committed = 0;
    late BuildContext ctx;
    await tester.pumpWidget(
      host((context) {
        ctx = context;
        AppDialog.undo(
          context,
          message: 'deleted',
          onUndo: () {},
          onCommit: () => committed++,
        );
      }),
    );
    await tester.tap(find.text('open'));
    await tester.pump();
    const AppDialog.info(message: 'other').notify(ctx);
    await tester.pump();
    expect(committed, 1);
    expect(find.text('other'), findsOneWidget);
    await tester.pump(AppDialog.noticeDuration);
    await tester.pumpAndSettle();
  });
}
