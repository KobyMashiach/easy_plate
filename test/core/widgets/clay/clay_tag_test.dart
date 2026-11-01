import 'package:easy_plate/core/widgets/clay/clay_tag.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const long =
      'תפריט שבועי למשפחה עם ילדים קטנים, בלי גלוטן ובלי אגוזים, חורף 2026';

  testWidgets('a long user-named tag ellipsizes inside a Wrap', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: SizedBox(
              width: 300,
              child: Wrap(
                children: [
                  ClayTag(label: long, icon: Icons.calendar_today_rounded),
                  ClayTag(label: 'קצר'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byType(ClayTag).first).width,
      lessThanOrEqualTo(300),
    );
  });

  testWidgets('a tag in a plain Row still lays out', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Row(children: [ClayTag(label: 'Premium')]),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Premium'), findsOneWidget);
  });
}
