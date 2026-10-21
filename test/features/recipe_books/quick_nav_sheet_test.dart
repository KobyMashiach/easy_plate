import 'package:easy_plate/core/utils/i18n/strings.g.dart';
import 'package:easy_plate/features/my_recipes/domain/entities/recipe_entity.dart';
import 'package:easy_plate/features/recipe_books/presentation/widgets/quick_nav_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() => LocaleSettings.setLocale(AppLocale.en));

  RecipeEntity recipe(String id) => RecipeEntity(
    id: id,
    title: 'Recipe $id',
    createdAt: DateTime(2026),
    ingredients: const [],
    steps: const [],
  );

  final recipes = [recipe('a'), recipe('b'), recipe('c')];

  Future<String?> open(
    WidgetTester tester, {
    void Function(int, int)? onReorder,
    required String tap,
  }) async {
    String? picked;
    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          locale: const Locale('en'),
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async => picked = await showQuickNavSheet(
                context,
                recipes,
                onReorder: onReorder,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    if (onReorder == null) {
      expect(find.byIcon(Icons.drag_handle_rounded), findsNothing);
      expect(find.text(t.books.reorderHint), findsNothing);
    } else {
      expect(find.byIcon(Icons.drag_handle_rounded), findsNWidgets(3));
    }
    await tester.tap(find.text(tap));
    await tester.pumpAndSettle();
    return picked;
  }

  testWidgets('read-only: no drag handles, a tap returns the recipe id', (
    tester,
  ) async {
    expect(await open(tester, tap: 'Recipe b'), 'b');
  });

  testWidgets('editable: drag handles shown, a tap returns the id', (
    tester,
  ) async {
    expect(await open(tester, onReorder: (_, _) {}, tap: 'Recipe c'), 'c');
  });
}
