import 'package:easy_plate/core/constants/app_enums.dart';
import 'package:easy_plate/features/my_recipes/domain/entities/recipe_entity.dart';
import 'package:easy_plate/features/my_recipes/domain/entities/recipe_ingredient_entity.dart';
import 'package:easy_plate/features/my_recipes/presentation/pages/recipe_editor_page.dart';
import 'package:easy_plate/features/recipe_ingestion/domain/entities/web_search_result_entity.dart';
import 'package:easy_plate/features/recipe_ingestion/domain/repositories/recipe_ingestion_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeIngestionRepository implements RecipeIngestionRepository {
  RecipeEntity? refined;
  bool? refinedTimesChanged;
  int refineCalls = 0;

  /// Stands in for the model's rewrite of the free-text fields.
  RecipeEntity Function(RecipeEntity)? onRefine;

  @override
  Future<RecipeEntity> refineRecipe(RecipeEntity recipe, {required bool timesChanged}) async {
    refineCalls++;
    refined = recipe;
    refinedTimesChanged = timesChanged;
    return onRefine?.call(recipe) ?? recipe;
  }

  @override
  Future<RecipeEntity> parseRawText(String text, List<DietaryPreference> preferences) =>
      throw UnimplementedError();

  @override
  Future<List<WebSearchResultEntity>> searchWeb(String q, List<DietaryPreference> p) =>
      throw UnimplementedError();

  @override
  Future<RecipeEntity> parseFromUrl(String url, List<DietaryPreference> preferences) =>
      throw UnimplementedError();

  @override
  Future<RecipeEntity> parseFromSocialVideo(String url, List<DietaryPreference> preferences) =>
      throw UnimplementedError();
}

RecipeEntity buildRecipe() => RecipeEntity(
      id: 'r1',
      title: 'שקשוקה',
      prepTimeMinutes: 10,
      cookTimeMinutes: 20,
      ingredients: const [
        RecipeIngredientEntity(name: 'עגבניות', amount: 400, unit: MeasurementUnit.gram),
      ],
      steps: const ['ערבוב עפ מלח פלפל', 'מבשלים 20 דקות'],
      createdAt: DateTime(2026, 1, 1),
    );

// Field order in the editor: title, prep, cook, then each ingredient's amount
// and name, then one field per step.
const _title = 0;
const _prep = 1;
const _cook = 2;
const _firstStep = 5;

void main() {
  late _FakeIngestionRepository repository;
  RecipeEntity? popped;

  /// Mirrors the app, where the repositories are provided above
  /// `MaterialApp.router` and are therefore ancestors of every pushed route.
  Future<void> openEditor(WidgetTester tester, RecipeEntity recipe) async {
    popped = null;
    await tester.pumpWidget(
      RepositoryProvider<RecipeIngestionRepository>.value(
        value: repository,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  popped = await Navigator.of(context).push<RecipeEntity>(
                    MaterialPageRoute(builder: (_) => RecipeEditorPage(recipe: recipe)),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<void> save(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.check_rounded));
    await tester.pumpAndSettle();
  }

  /// Drags step [from] onto step [to]. The move is walked in small increments
  /// because the reorder recognizer recomputes the drop slot per pointer
  /// update — a single jump reports one move and lands nowhere.
  Future<void> dragStep(WidgetTester tester, int from, int to) async {
    final handles = find.byIcon(Icons.drag_handle_rounded);
    final start = tester.getCenter(handles.at(from));
    final end = tester.getCenter(handles.at(to));

    final gesture = await tester.startGesture(start);
    await tester.pump(const Duration(milliseconds: 100));

    const steps = 12;
    final step = (end - start) / steps.toDouble();
    for (var i = 0; i < steps; i++) {
      await gesture.moveBy(step);
      await tester.pump(const Duration(milliseconds: 16));
    }

    await gesture.up();
    await tester.pumpAndSettle();
  }

  setUp(() {
    repository = _FakeIngestionRepository();

    // The editor is a lazy ListView; a tall viewport keeps every field built so
    // the indices above stay stable.
    final view = TestWidgetsFlutterBinding.ensureInitialized().platformDispatcher.views.first;
    view.physicalSize = const Size(1200, 4000);
    view.devicePixelRatio = 1.0;
    addTearDown(() {
      view.resetPhysicalSize();
      view.resetDevicePixelRatio();
    });
  });

  testWidgets('loads the recipe into the structured fields', (tester) async {
    await openEditor(tester, buildRecipe());

    final fields = tester.widgetList<TextField>(find.byType(TextField)).toList();
    expect(fields[_title].controller?.text, 'שקשוקה');
    expect(fields[_prep].controller?.text, '10');
    expect(fields[_cook].controller?.text, '20');
    expect(fields[_firstStep].controller?.text, 'ערבוב עפ מלח פלפל');
  });

  testWidgets('edits the title and pops the recipe without calling the model', (tester) async {
    await openEditor(tester, buildRecipe());

    await tester.enterText(find.byType(TextField).at(_title), 'שקשוקה ירושלמית');
    await save(tester);

    expect(popped?.title, 'שקשוקה ירושלמית');
    // Amounts and units survive a title-only edit.
    expect(popped?.ingredients.single.amount, 400);
    expect(popped?.ingredients.single.unit, MeasurementUnit.gram);
    expect(repository.refineCalls, 0, reason: 'times unchanged, so no refine');
  });

  testWidgets('an empty title blocks saving', (tester) async {
    await openEditor(tester, buildRecipe());

    await tester.enterText(find.byType(TextField).at(_title), '   ');
    await save(tester);

    expect(popped, isNull);
    expect(find.byType(RecipeEditorPage), findsOneWidget);
  });

  testWidgets('changing the cook time re-syncs the steps through the model', (tester) async {
    repository.onRefine = (recipe) => recipe.copyWith(steps: ['ערבוב עם מלח פלפל', 'מבשלים 35 דקות']);
    await openEditor(tester, buildRecipe());

    await tester.enterText(find.byType(TextField).at(_cook), '35');
    await save(tester);

    expect(repository.refinedTimesChanged, isTrue);
    expect(repository.refined?.cookTimeMinutes, 35);
    expect(popped?.cookTimeMinutes, 35);
    expect(popped?.steps.last, 'מבשלים 35 דקות');
  });

  testWidgets('clearing a time field stores null instead of the old value', (tester) async {
    await openEditor(tester, buildRecipe());

    await tester.enterText(find.byType(TextField).at(_prep), '');
    await save(tester);

    expect(popped?.prepTimeMinutes, isNull);
    expect(popped?.cookTimeMinutes, 20);
  });

  testWidgets('the spellcheck action rewrites the fields in place', (tester) async {
    repository.onRefine = (recipe) => recipe.copyWith(steps: ['ערבוב עם מלח פלפל', recipe.steps[1]]);
    await openEditor(tester, buildRecipe());

    await tester.tap(find.byIcon(Icons.spellcheck_rounded));
    await tester.pumpAndSettle();

    expect(repository.refinedTimesChanged, isFalse);
    final fields = tester.widgetList<TextField>(find.byType(TextField)).toList();
    expect(fields[_firstStep].controller?.text, 'ערבוב עם מלח פלפל');
  });

  testWidgets('a correction that changes nothing does not claim it fixed something',
      (tester) async {
    // onRefine left null: the model hands the text straight back.
    await openEditor(tester, buildRecipe());

    await tester.tap(find.byIcon(Icons.spellcheck_rounded));
    await tester.pumpAndSettle();

    expect(find.text('לא נמצאו שגיאות כתיב'), findsOneWidget);
    expect(find.text('המתכון תוקן'), findsNothing);
  });

  testWidgets('a real correction reports that it fixed something', (tester) async {
    repository.onRefine = (recipe) => recipe.copyWith(steps: ['ערבוב עם מלח פלפל', recipe.steps[1]]);
    await openEditor(tester, buildRecipe());

    await tester.tap(find.byIcon(Icons.spellcheck_rounded));
    await tester.pumpAndSettle();

    expect(find.text('המתכון תוקן'), findsOneWidget);
  });

  testWidgets('a blank row does not shift the corrections onto it', (tester) async {
    // Blanking the first step leaves one step to correct, so a correction that
    // walked all rows would land the result on the blank row instead.
    repository.onRefine = (recipe) => recipe.copyWith(steps: ['מבשלים 30 דקות']);
    await openEditor(tester, buildRecipe());

    await tester.enterText(find.byType(TextField).at(_firstStep), '');
    await tester.tap(find.byIcon(Icons.spellcheck_rounded));
    await tester.pumpAndSettle();

    expect(repository.refined?.steps, ['מבשלים 20 דקות']);
    final fields = tester.widgetList<TextField>(find.byType(TextField)).toList();
    expect(fields[_firstStep].controller?.text, isEmpty);
    expect(fields[_firstStep + 1].controller?.text, 'מבשלים 30 דקות');
  });

  testWidgets('a refine failure leaves the edits intact and still saves', (tester) async {
    repository.onRefine = (_) => throw Exception('offline');
    await openEditor(tester, buildRecipe());

    await tester.enterText(find.byType(TextField).at(_cook), '35');
    await save(tester);

    expect(popped?.cookTimeMinutes, 35);
    expect(popped?.steps.first, 'ערבוב עפ מלח פלפל');
  });

  testWidgets('topics can be set on a recipe that had none', (tester) async {
    // Nothing else in the app sets dietaryTags, so without this the community's
    // topic filter could never match a recipe the user wrote.
    await openEditor(tester, buildRecipe());
    expect(buildRecipe().dietaryTags, isEmpty);

    await tester.tap(find.text('חלבי'));
    await tester.pumpAndSettle();
    await save(tester);

    expect(popped?.dietaryTags, [DietaryPreference.dairy]);
  });

  testWidgets('an existing topic can be removed', (tester) async {
    final tagged = RecipeEntity(
      id: 'r1',
      title: 'שקשוקה',
      ingredients: const [],
      steps: const ['ערבוב'],
      dietaryTags: const [DietaryPreference.dairy, DietaryPreference.vegetarian],
      createdAt: DateTime(2026, 1, 1),
    );
    await openEditor(tester, tagged);

    await tester.tap(find.text('חלבי'));
    await tester.pumpAndSettle();
    await save(tester);

    expect(popped?.dietaryTags, [DietaryPreference.vegetarian]);
  });

  testWidgets('dragging a step by its handle reorders the saved recipe', (tester) async {
    await openEditor(tester, buildRecipe());

    await dragStep(tester, 0, 1);
    await save(tester);

    expect(popped?.steps, ['מבשלים 20 דקות', 'ערבוב עפ מלח פלפל']);
  });

  testWidgets('reordering carries the text with the step, not the position',
      (tester) async {
    await openEditor(tester, buildRecipe());

    await tester.enterText(find.byType(TextField).at(_firstStep), 'שלב ראשון ערוך');
    await tester.pumpAndSettle();

    await dragStep(tester, 0, 1);
    await save(tester);

    expect(popped?.steps.last, 'שלב ראשון ערוך');
  });

  testWidgets('dropping a step removes it from the saved recipe', (tester) async {
    await openEditor(tester, buildRecipe());

    await tester.tap(find.byIcon(Icons.remove_circle_outline_rounded).last);
    await tester.pumpAndSettle();
    await save(tester);

    expect(popped?.steps, ['ערבוב עפ מלח פלפל']);
  });
}
