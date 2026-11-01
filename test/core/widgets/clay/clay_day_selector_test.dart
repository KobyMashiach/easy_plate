import 'package:easy_plate/core/widgets/clay/clay_day_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget harness(double textScale) => MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: ClayDaySelector(
            labels: const ['ראשון', 'שני', 'שלישי', 'רביעי'],
            selectedIndex: 1,
            counts: const [0, 3, 1, 2],
            onSelected: (_) {},
          ),
        ),
      ),
    ),
  );

  for (final scale in [1.0, 1.5, 2.0]) {
    testWidgets('day tiles fit at text scale $scale', (tester) async {
      await tester.pumpWidget(harness(scale));
      expect(tester.takeException(), isNull);
      expect(find.text('3'), findsOneWidget);
    });
  }

  testWidgets('the row keeps its 90 px at the normal text size', (
    tester,
  ) async {
    await tester.pumpWidget(harness(1.0));
    final box = tester.renderObject<RenderBox>(
      find.descendant(
        of: find.byType(ClayDaySelector),
        matching: find.byType(SizedBox),
      ).first,
    );
    expect(box.size.height, 90);
  });
}
