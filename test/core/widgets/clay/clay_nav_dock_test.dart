import 'package:easy_plate/core/widgets/clay/clay_nav_dock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const destinations = [
    ClayNavDestination(icon: Icons.home, label: 'A'),
    ClayNavDestination(icon: Icons.book, label: 'B'),
    ClayNavDestination(icon: Icons.calendar_today, label: 'C'),
    ClayNavDestination(icon: Icons.shopping_cart, label: 'D'),
    ClayNavDestination(icon: Icons.groups, label: 'E'),
  ];

  Widget harness(
    List<int> selected, {
    TextDirection direction = TextDirection.ltr,
  }) {
    return MaterialApp(
      home: Directionality(
        textDirection: direction,
        child: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: ClayNavDock(
              selectedIndex: selected.lastOrNull ?? 0,
              onSelected: selected.add,
              destinations: destinations,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('a tap selects the tab', (tester) async {
    final selected = <int>[];
    await tester.pumpWidget(harness(selected));
    await tester.tap(find.text('D'));
    expect(selected, [3]);
  });

  testWidgets('a drag across the dock selects the tab under the finger', (
    tester,
  ) async {
    final selected = <int>[];
    await tester.pumpWidget(harness(selected));
    final a = tester.getCenter(find.text('A'));
    final c = tester.getCenter(find.text('C'));
    await tester.timedDragFrom(a, c - a, const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(selected, [2]);
  });

  testWidgets('a drag in a right-to-left row lands on the right tab', (
    tester,
  ) async {
    final selected = <int>[];
    await tester.pumpWidget(harness(selected, direction: TextDirection.rtl));
    final a = tester.getCenter(find.text('A'));
    final c = tester.getCenter(find.text('C'));
    await tester.timedDragFrom(a, c - a, const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(selected, [2]);
  });

  testWidgets('a drag that stays within the current tab selects nothing', (
    tester,
  ) async {
    final selected = <int>[];
    await tester.pumpWidget(harness(selected));
    final a = tester.getCenter(find.text('A'));
    // Past the touch slop, so it is a drag and not a tap, but short of the
    // next tab: the lozenge glides back to where it was.
    await tester.timedDragFrom(
      a,
      const Offset(20, 0),
      const Duration(milliseconds: 300),
    );
    await tester.pumpAndSettle();
    expect(selected, isEmpty);
  });
}
