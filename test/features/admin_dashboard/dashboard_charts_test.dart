import 'package:easy_plate/features/admin_dashboard/presentation/widgets/dashboard_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

List<BarDatum> _bars(int n) => [
  for (var i = 0; i < n; i++)
    BarDatum(value: i + 1.0, label: '', tooltip: 'day $i'),
];

Widget _chart(int n) => MaterialApp(
  home: Scaffold(
    body: SizedBox(width: 300, child: ClayBarChart(data: _bars(n))),
  ),
);

void main() {
  testWidgets('a bar tapped in a longer range does not outlive it', (
    tester,
  ) async {
    await tester.pumpWidget(_chart(30));
    // The last bar of thirty (LTR: the right edge).
    final box = tester.getRect(find.byType(CustomPaint).last);
    await tester.tapAt(Offset(box.right - 2, box.center.dy));
    await tester.pump();
    expect(find.text('day 29'), findsOneWidget);

    await tester.pumpWidget(_chart(7));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.textContaining('day '), findsNothing);
  });
}
