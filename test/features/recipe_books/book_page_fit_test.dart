import 'package:easy_plate/core/constants/app_enums.dart';
import 'package:easy_plate/features/more/presentation/pages/tutorial_book_page.dart';
import 'package:easy_plate/features/my_recipes/domain/entities/recipe_entity.dart';
import 'package:easy_plate/features/my_recipes/domain/entities/recipe_ingredient_entity.dart';
import 'package:easy_plate/features/recipe_books/presentation/widgets/book_spread_flip.dart';
import 'package:easy_plate/features/recipe_books/presentation/widgets/open_book_shell.dart';
import 'package:easy_plate/features/recipe_books/presentation/widgets/recipe_book_page.dart';
import 'package:easy_plate/features/recipe_books/presentation/widgets/table_of_contents_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

RecipeEntity recipe() => RecipeEntity(
      id: 'r',
      title: 'עוף בתנור עם תפוחי אדמה ורוזמרין טרי מהגינה',
      prepTimeMinutes: 20,
      cookTimeMinutes: 75,
      ingredients: const [
        RecipeIngredientEntity(name: 'כרעיים עוף', amount: 4, unit: MeasurementUnit.unit),
        RecipeIngredientEntity(name: 'תפוחי אדמה', amount: 800, unit: MeasurementUnit.gram),
      ],
      steps: const ['מחממים תנור.', 'אופים 75 דקות.'],
      dietaryTags: const [DietaryPreference.meat, DietaryPreference.kosher],
      createdAt: DateTime(2026, 1, 1),
    );

/// Collects layout errors while the body runs. The test font draws every
/// glyph a full em wide, so Hebrew runs far wider than on a phone and a
/// sideways overflow here means nothing; only a vertical one is real.
Future<List<String>> verticalOverflows(Future<void> Function() body) async {
  final errors = <String>[];
  final previous = FlutterError.onError;
  FlutterError.onError = (details) => errors.add(details.toString());
  try {
    await body();
  } finally {
    FlutterError.onError = previous;
  }
  return [
    for (final error in errors)
      if (!error.contains('overflowed by') ||
          error.contains('on the bottom') ||
          error.contains('on the top'))
        _summary(error),
  ];
}

/// The message plus the widget it points at, so a failure names the page.
String _summary(String error) {
  final lines = error.split('\n');
  final message = lines.firstWhere(
    (line) => line.contains('overflowed by') || line.contains('Exception'),
    orElse: () => lines.skip(1).first,
  );
  final at = lines.indexWhere((line) => line.contains('error-causing widget'));
  if (at == -1) return message;
  final where = lines.skip(at + 1).take(3).map((l) => l.trim()).join(' ');
  return '$message @ $where';
}

Widget host(Size size, Widget child, {TextDirection direction = TextDirection.rtl}) {
  return MaterialApp(
    home: Directionality(
      textDirection: direction,
      child: Center(child: SizedBox.fromSize(size: size, child: child)),
    ),
  );
}

/// A phone upright, and half a phone on its side.
const leaves = [Size(390, 700), Size(400, 222), Size(360, 200)];

void main() {
  for (final size in leaves) {
    testWidgets('a recipe page fits a ${size.width}x${size.height} leaf', (tester) async {
      final errors = await verticalOverflows(() async {
        await tester.pumpWidget(host(size, RecipeBookPage(recipe: recipe(), pageNumber: 2)));
        await tester.pumpAndSettle();
      });
      expect(errors, isEmpty);
    });

    testWidgets('a contents page fits a ${size.width}x${size.height} leaf', (tester) async {
      final errors = await verticalOverflows(() async {
        await tester.pumpWidget(host(
          size,
          TableOfContentsPage(bookTitle: 'ספר', recipes: [recipe()], onSelectRecipe: (_) {}),
        ));
        await tester.pumpAndSettle();
      });
      expect(errors, isEmpty);
    });
  }

  testWidgets('every page of the guide fits a phone on its side', (tester) async {
    tester.view.physicalSize = const Size(844, 390);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final errors = await verticalOverflows(() async {
      await tester.pumpWidget(const MaterialApp(
        home: Directionality(textDirection: TextDirection.rtl, child: TutorialBookPage()),
      ));
      await tester.pumpAndSettle();
      // Leaf by leaf to the back cover. A Hebrew book turns forward to the right.
      for (var i = 0; i < 6; i++) {
        await tester.drag(find.byType(BookSpreadFlip), const Offset(300, 0));
        await tester.pumpAndSettle();
      }
    });
    expect(errors, isEmpty);
  });

  testWidgets('a Hebrew book opens with its first page on the right', (tester) async {
    tester.view.physicalSize = const Size(844, 390);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: OpenBookShell(
          pages: (_) => const [Center(child: Text('first')), Center(child: Text('second'))],
          actions: (_) => const [],
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(BookSpreadFlip), findsOneWidget);
    expect(
      tester.getCenter(find.text('first')).dx,
      greaterThan(tester.getCenter(find.text('second')).dx),
    );
  });
}
