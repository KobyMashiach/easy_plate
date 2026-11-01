import 'package:easy_plate/core/widgets/pop_if_current.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// home → pushed "picker page" → a bottom sheet with one row. Returns the
  /// row's context and a getter for what the sheet's future completed with.
  Future<(BuildContext, String? Function())> openSheet(
    WidgetTester tester,
  ) async {
    BuildContext? rowContext;
    String? answer;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => Scaffold(
                  body: TextButton(
                    onPressed: () async {
                      answer = await showModalBottomSheet<String>(
                        context: context,
                        builder: (sheetContext) => Builder(
                          builder: (context) {
                            rowContext = context;
                            return const Text('row');
                          },
                        ),
                      );
                    },
                    child: const Text('picker page'),
                  ),
                ),
              ),
            ),
            child: const Text('home'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('home'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('picker page'));
    await tester.pumpAndSettle();
    expect(find.text('row'), findsOneWidget);
    return (rowContext!, () => answer);
  }

  testWidgets('a double tap on a sheet row closes the sheet, not the page '
      'under it', (tester) async {
    final (context, answer) = await openSheet(tester);

    // Two taps before a frame: the second runs on a sheet already closing.
    expect(popIfCurrent(context, 'first'), isTrue);
    expect(popIfCurrent(context, 'second'), isFalse);
    await tester.pumpAndSettle();

    expect(find.text('row'), findsNothing);
    expect(find.text('picker page'), findsOneWidget);
    expect(answer(), 'first');
  });

  testWidgets('the bare pop it replaces took the page under the sheet', (
    tester,
  ) async {
    final (context, _) = await openSheet(tester);

    Navigator.of(context).pop('first');
    Navigator.of(context).pop('second');
    await tester.pumpAndSettle();

    expect(find.text('picker page'), findsNothing);
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('pops with no result', (tester) async {
    final (context, answer) = await openSheet(tester);

    expect(popIfCurrent<String>(context), isTrue);
    await tester.pumpAndSettle();

    expect(find.text('row'), findsNothing);
    expect(answer(), isNull);
  });
}
