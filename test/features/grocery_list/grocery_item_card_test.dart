import 'package:easy_plate/core/constants/app_enums.dart';
import 'package:easy_plate/core/features/features_flags.dart';
import 'package:easy_plate/core/utils/i18n/strings.g.dart';
import 'package:easy_plate/features/grocery_list/domain/entities/grocery_item_entity.dart';
import 'package:easy_plate/features/grocery_list/domain/entities/grocery_item_source_entity.dart';
import 'package:easy_plate/features/grocery_list/presentation/bloc/grocery_list_bloc.dart';
import 'package:easy_plate/features/grocery_list/presentation/widgets/grocery_item_card.dart';
import 'package:easy_plate/features/price_book/domain/repositories/price_book_repository.dart';
import 'package:easy_plate/features/price_book/presentation/price_book_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _Bloc extends Mock implements GroceryListBloc {}

class _Prices extends Mock implements PriceBookRepository {}

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.he));
  tearDown(() => FeaturesFlags.overrides = null);

  Widget host() => MaterialApp(
    home: Provider<GroceryListBloc>.value(
      value: _Bloc(),
      child: ChangeNotifierProvider<PriceBookService>.value(
        value: PriceBookService(repository: _Prices()),
        child: const Scaffold(
          body: GroceryItemCard(
            item: GroceryItemEntity(
              id: 'milk',
              name: 'חלב',
              unit: MeasurementUnit.unit,
              sources: [],
              category: 'dairy',
            ),
          ),
        ),
      ),
    ),
  );

  testWidgets('the line offers its price while the price book is on', (
    tester,
  ) async {
    await tester.pumpWidget(host());
    expect(find.text(t.receipt.noData), findsOneWidget);
  });

  for (final off in [FeaturesFlags.priceBook, FeaturesFlags.groceryCost]) {
    for (final value in [
      FeatureFlagValue.hidden,
      FeatureFlagValue.comingSoon,
    ]) {
      testWidgets('no price on the line with ${off.key} ${value.name}', (
        tester,
      ) async {
        FeaturesFlags.overrides = {off: value};
        await tester.pumpWidget(host());
        expect(find.text('חלב'), findsOneWidget);
        expect(find.text(t.receipt.noData), findsNothing);
      });
    }
  }

  testWidgets('a long line at a large text size stays inside the card', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(720, 1600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(360, 800),
            textScaler: TextScaler.linear(1.6),
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Provider<GroceryListBloc>.value(
              value: _Bloc(),
              child: ChangeNotifierProvider<PriceBookService>.value(
                value: PriceBookService(repository: _Prices()),
                child: Scaffold(
                  // In a list, as on the groceries tab: the card grows.
                  body: ListView(
                    children: const [
                      GroceryItemCard(
                        item: GroceryItemEntity(
                          id: 'long',
                          name:
                              'גבינה צהובה מגוררת עמק 28% שומן, אריזה משפחתית גדולה במיוחד',
                          unit: MeasurementUnit.gram,
                          sources: [
                            GroceryItemSourceEntity(
                              label: 'פיצה ביתית עם הרבה גבינה וירקות',
                              amount: 1250.5,
                              recipeId: 'r1',
                            ),
                            GroceryItemSourceEntity(
                              label: 'לזניה',
                              amount: 400,
                              recipeId: 'r2',
                            ),
                          ],
                          category: 'dairy',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  for (final direction in TextDirection.values) {
    testWidgets('an open line points its chevron down (${direction.name})', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: direction,
            child: Provider<GroceryListBloc>.value(
              value: _Bloc(),
              child: ChangeNotifierProvider<PriceBookService>.value(
                value: PriceBookService(repository: _Prices()),
                child: const Scaffold(
                  body: GroceryItemCard(
                    item: GroceryItemEntity(
                      id: 'eggs',
                      name: 'ביצים',
                      unit: MeasurementUnit.unit,
                      sources: [
                        GroceryItemSourceEntity(
                          label: 'שקשוקה',
                          amount: 6,
                          recipeId: 'r1',
                        ),
                      ],
                      category: 'dairy',
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('ביצים'));
      await tester.pumpAndSettle();
      final rotation = tester.widget<AnimatedRotation>(
        find.byType(AnimatedRotation),
      );
      // chevron_right mirrors under RTL, so the turn that lands it pointing
      // down is clockwise in LTR and counter-clockwise in RTL.
      expect(
        rotation.turns,
        direction == TextDirection.rtl ? -0.25 : 0.25,
      );
    });
  }
}
