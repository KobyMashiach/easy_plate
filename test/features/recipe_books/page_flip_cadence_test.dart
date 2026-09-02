import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:page_flip/page_flip.dart';

/// The book viewer's fast-forward paces itself on `onPageFlipped` firing once
/// per completed turn. These tests pin that contract down against the real
/// package, since the whole jump animation stalls if a landing is ever missed.
void main() {
  const flipDuration = Duration(milliseconds: 200);

  Future<List<int>> pumpBook(
    WidgetTester tester,
    PageFlipController controller, {
    int pageCount = 5,
  }) async {
    final flipped = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: PageFlipWidget(
          controller: controller,
          duration: flipDuration,
          onPageFlipped: flipped.add,
          children: [
            for (var i = 0; i < pageCount; i++)
              ColoredBox(color: Colors.white, key: ValueKey(i)),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    return flipped;
  }

  testWidgets('reports exactly one landing per forward turn', (tester) async {
    final controller = PageFlipController();
    final flipped = await pumpBook(tester, controller);

    for (var i = 0; i < 3; i++) {
      controller.nextPage();
      await tester.pumpAndSettle();
    }

    expect(flipped, [1, 2, 3]);
  });

  testWidgets('reports each landing when turning back', (tester) async {
    final controller = PageFlipController();
    final flipped = await pumpBook(tester, controller);

    for (var i = 0; i < 3; i++) {
      controller.nextPage();
      await tester.pumpAndSettle();
    }
    flipped.clear();

    for (var i = 0; i < 2; i++) {
      controller.previousPage();
      await tester.pumpAndSettle();
    }

    expect(flipped, [2, 1]);
  });

  testWidgets('a turn lands within the configured duration', (tester) async {
    final controller = PageFlipController();
    final flipped = await pumpBook(tester, controller);

    controller.nextPage();
    // One frame short of the flip duration the turn is still in flight.
    await tester.pump();
    await tester.pump(flipDuration - const Duration(milliseconds: 20));
    expect(flipped, isEmpty);

    await tester.pumpAndSettle();
    expect(flipped, [1]);
  });

  testWidgets('refuses to turn past the last page', (tester) async {
    final controller = PageFlipController();
    final flipped = await pumpBook(tester, controller, pageCount: 2);

    controller.nextPage();
    await tester.pumpAndSettle();
    // Already on the final page: the flip is refused and nothing is reported,
    // which is why the viewer clamps its target and guards with a timeout.
    controller.nextPage();
    await tester.pumpAndSettle();

    expect(flipped, [1]);
  });
}
