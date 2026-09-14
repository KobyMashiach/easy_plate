import 'package:easy_plate/features/recipe_books/presentation/widgets/book_spread_flip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Five pages make three spreads; the last faces a blank.
List<Widget> pages() => [for (var i = 0; i < 5; i++) Center(child: Text('p$i'))];

Widget host(
  BookSpreadController controller, {
  TextDirection direction = TextDirection.ltr,
  ValueChanged<int>? onSpreadChanged,
}) {
  return MaterialApp(
    home: Directionality(
      textDirection: direction,
      child: SizedBox(
        width: 800,
        height: 400,
        child: BookSpreadFlip(
          pages: pages(),
          controller: controller,
          onSpreadChanged: onSpreadChanged,
          duration: const Duration(milliseconds: 100),
        ),
      ),
    ),
  );
}

void main() {
  test('pages pair into spreads, an odd last page facing a blank', () {
    expect(BookSpreadFlip.spreadCount(5), 3);
    expect(BookSpreadFlip.spreadCount(4), 2);
    expect(BookSpreadFlip.spreadCount(0), 1);
  });

  testWidgets('opens at the first spread, showing its two pages', (tester) async {
    await tester.pumpWidget(host(BookSpreadController()));
    expect(find.text('p0'), findsOneWidget);
    expect(find.text('p1'), findsOneWidget);
    expect(find.text('p2'), findsNothing);
  });

  testWidgets('a turn lands on the next spread and reports it', (tester) async {
    final controller = BookSpreadController();
    final seen = <int>[];
    await tester.pumpWidget(host(controller, onSpreadChanged: seen.add));

    final turn = controller.next();
    await tester.pumpAndSettle();
    await turn;

    expect(controller.spread, 1);
    expect(seen, [1]);
    expect(find.text('p2'), findsOneWidget);
    expect(find.text('p3'), findsOneWidget);
    expect(find.text('p0'), findsNothing);
  });

  testWidgets('the book stops at its covers', (tester) async {
    final controller = BookSpreadController();
    await tester.pumpWidget(host(controller));

    controller.previous();
    await tester.pumpAndSettle();
    expect(controller.spread, 0);

    for (var i = 0; i < 5; i++) {
      controller.next();
      await tester.pumpAndSettle();
    }
    expect(controller.spread, 2);
    expect(find.text('p4'), findsOneWidget);
  });

  testWidgets('a jump opens the book straight there', (tester) async {
    final controller = BookSpreadController();
    await tester.pumpWidget(host(controller));

    controller.jumpTo(2);
    await tester.pump();

    expect(controller.spread, 2);
    expect(find.text('p4'), findsOneWidget);
  });

  testWidgets('a drag toward the start turns forward in a Latin book', (tester) async {
    final controller = BookSpreadController();
    await tester.pumpWidget(host(controller));

    await tester.drag(find.byType(BookSpreadFlip), const Offset(-300, 0));
    await tester.pumpAndSettle();

    expect(controller.spread, 1);
  });

  testWidgets('a short drag falls back onto the same spread', (tester) async {
    final controller = BookSpreadController();
    await tester.pumpWidget(host(controller));

    await tester.drag(find.byType(BookSpreadFlip), const Offset(-40, 0));
    await tester.pumpAndSettle();

    expect(controller.spread, 0);
    expect(find.text('p0'), findsOneWidget);
  });

  testWidgets('a Hebrew book turns the other way', (tester) async {
    final controller = BookSpreadController();
    await tester.pumpWidget(host(controller, direction: TextDirection.rtl));

    // Leftward is backward here, and there is nothing before the first spread.
    await tester.drag(find.byType(BookSpreadFlip), const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(controller.spread, 0);

    await tester.drag(find.byType(BookSpreadFlip), const Offset(300, 0));
    await tester.pumpAndSettle();
    expect(controller.spread, 1);
  });
}
