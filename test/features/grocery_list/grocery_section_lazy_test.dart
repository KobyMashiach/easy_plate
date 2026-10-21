import 'package:easy_plate/core/constants/app_enums.dart';
import 'package:easy_plate/features/grocery_list/domain/entities/grocery_item_entity.dart';
import 'package:easy_plate/features/grocery_list/presentation/bloc/grocery_list_bloc.dart';
import 'package:easy_plate/features/grocery_list/presentation/widgets/grocery_item_card.dart';
import 'package:easy_plate/features/grocery_list/presentation/widgets/grocery_section.dart';
import 'package:easy_plate/features/price_book/domain/repositories/price_book_repository.dart';
import 'package:easy_plate/features/price_book/presentation/price_book_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _Bloc extends Mock implements GroceryListBloc {}

class _Prices extends Mock implements PriceBookRepository {}

List<GroceryItemEntity> _items(int count, {bool checked = false}) => [
  for (var i = 0; i < count; i++)
    GroceryItemEntity(
      id: '${checked ? 'c' : 'u'}$i',
      name: 'Item $i',
      unit: MeasurementUnit.unit,
      sources: const [],
      category: 'other',
      isChecked: checked,
    ),
];

Widget _host(List<Widget> slivers) {
  final service = PriceBookService(repository: _Prices());
  return MaterialApp(
    home: Provider<GroceryListBloc>.value(
      value: _Bloc(),
      child: ChangeNotifierProvider<PriceBookService>.value(
        value: service,
        child: Scaffold(body: CustomScrollView(slivers: slivers)),
      ),
    ),
  );
}

void main() {
  testWidgets('a 300-line section builds only the rows on screen', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host([GrocerySection(title: 'To collect', items: _items(300))]),
    );
    await tester.pump();

    final built = find.byType(GroceryItemCard, skipOffstage: false);
    expect(built, findsWidgets);
    expect(tester.widgetList(built).length, lessThan(40));
    expect(find.text('Item 0'), findsOneWidget);
    expect(find.text('Item 299', skipOffstage: false), findsNothing);

    // Scrolling to the end builds the end, and drops the start.
    await tester.scrollUntilVisible(find.text('Item 299'), 2000);
    expect(find.text('Item 299'), findsOneWidget);
    expect(find.text('Item 0', skipOffstage: false), findsNothing);
  });

  testWidgets('a collapsed section builds no rows, and opens on a tap', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host([
        GrocerySection(
          title: 'In the basket',
          items: _items(300, checked: true),
          initiallyExpanded: false,
        ),
      ]),
    );
    expect(
      find.byType(GroceryItemCard, skipOffstage: false),
      findsNothing,
    );
    expect(find.text('300'), findsOneWidget);

    await tester.tap(find.text('In the basket'));
    await tester.pumpAndSettle();
    expect(find.text('Item 0'), findsOneWidget);
    expect(
      tester
          .widgetList(find.byType(GroceryItemCard, skipOffstage: false))
          .length,
      lessThan(40),
    );

    // Closing again takes the rows out once the animation ends.
    await tester.tap(find.text('In the basket'));
    await tester.pumpAndSettle();
    expect(
      find.byType(GroceryItemCard, skipOffstage: false),
      findsNothing,
    );
  });
}
