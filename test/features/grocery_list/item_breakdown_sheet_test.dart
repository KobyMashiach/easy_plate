import 'package:easy_plate/core/constants/app_enums.dart';
import 'package:easy_plate/core/utils/i18n/strings.g.dart';
import 'package:easy_plate/features/grocery_list/domain/entities/grocery_item_entity.dart';
import 'package:easy_plate/features/grocery_list/domain/entities/grocery_item_source_entity.dart';
import 'package:easy_plate/features/grocery_list/presentation/widgets/item_breakdown_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() => LocaleSettings.setLocale(AppLocale.en));

  const item = GroceryItemEntity(
    id: 'i',
    name: 'flour',
    unit: MeasurementUnit.gram,
    category: 'pantry',
    sources: [
      GroceryItemSourceEntity(label: 'bread', amount: 1.125, recipeId: 'r1'),
      GroceryItemSourceEntity(label: 'cake', amount: 0.3333, recipeId: 'r2'),
    ],
  );

  Future<List<double>> openAndClose(
    WidgetTester tester, {
    String? typeInFirst,
  }) async {
    final adjusted = <double>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showItemBreakdownSheet(
                context,
                item,
                onAdjustSource: (_, _, amount) => adjusted.add(amount),
                onRemoveSource: (_, _) {},
                onChangeUnit: (_) {},
                onAddBuffer: (_) {},
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    if (typeInFirst != null) {
      await tester.enterText(find.byType(TextField).first, typeInFirst);
    }
    // Swipe the sheet away: the route pops and the body is disposed.
    Navigator.of(tester.element(find.text('flour'))).pop();
    await tester.pumpAndSettle();
    return adjusted;
  }

  testWidgets('closing untouched leaves amounts with more decimals alone', (
    tester,
  ) async {
    expect(await openAndClose(tester), isEmpty);
  });

  testWidgets('a typed amount is still committed on close', (tester) async {
    expect(await openAndClose(tester, typeInFirst: '2,5'), [2.5]);
  });
}
