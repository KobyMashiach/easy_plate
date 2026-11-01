import 'package:easy_plate/core/widgets/clay/clay_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const label =
      'Enregistrer la recette avec l’IA et l’ajouter au livre de la famille';

  Widget harness({required bool expanded, double textScale = 1.0}) =>
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: 342,
                child: ClayButton(
                  label: label,
                  icon: Icons.auto_awesome_rounded,
                  expanded: expanded,
                  onPressed: () {},
                ),
              ),
            ),
          ),
        ),
      );

  for (final expanded in [true, false]) {
    for (final scale in [1.0, 1.5]) {
      testWidgets(
        'a long label wraps inside the button (expanded: $expanded, '
        'scale $scale)',
        (tester) async {
          await tester.pumpWidget(
            harness(expanded: expanded, textScale: scale),
          );
          expect(tester.takeException(), isNull);
          expect(find.text(label), findsOneWidget);
        },
      );
    }
  }

  testWidgets('a short label keeps the button hugging it', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: ClayButton(label: 'Save', onPressed: null)),
        ),
      ),
    );
    expect(tester.getSize(find.byType(ClayButton)).width, lessThan(200));
  });

  testWidgets('it still lays out where its width is unbounded', (
    tester,
  ) async {
    // A button as a plain child of a Row (no Expanded) or of a horizontal
    // list gets an infinite width; the Flexible label must not assert.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              Row(children: [ClayButton(label: 'Save', onPressed: () {})]),
              SizedBox(
                height: 80,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [ClayButton(label: 'Next', onPressed: () {})],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Save'), findsOneWidget);
  });
}
