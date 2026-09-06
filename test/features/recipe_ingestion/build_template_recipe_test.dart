import 'package:easy_plate/core/constants/app_enums.dart';
import 'package:easy_plate/features/recipe_ingestion/domain/usecases/build_template_recipe.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every line becomes a step, the first one also the title', () {
    final recipe = buildTemplateRecipe(
      id: 'r1',
      text: 'שקשוקה\n4 ביצים\nמטגנים בצל',
      channel: RecipeIngestionChannel.rawText,
      untitled: 'מתכון ללא שם',
    );

    expect(recipe.title, 'שקשוקה');
    // The title line stays in the steps: the steps are the full original text,
    // and that is what a later analysis is run on.
    expect(recipe.steps, ['שקשוקה', '4 ביצים', 'מטגנים בצל']);
    expect(recipe.rawText, 'שקשוקה\n4 ביצים\nמטגנים בצל');
    expect(recipe.pendingAnalysis, isTrue);
    expect(recipe.ingredients, isEmpty, reason: 'nothing is guessed');
  });

  test('blank lines are dropped, whitespace trimmed', () {
    final recipe = buildTemplateRecipe(
      id: 'r1',
      text: '  שקשוקה  \n\n\n   \n4 ביצים\n',
      channel: RecipeIngestionChannel.rawText,
      untitled: 'x',
    );
    expect(recipe.steps, ['שקשוקה', '4 ביצים']);
  });

  test('a paragraph-long first line is cut down for the title only', () {
    final long = 'א' * 200;
    final recipe = buildTemplateRecipe(
      id: 'r1',
      text: long,
      channel: RecipeIngestionChannel.rawText,
      untitled: 'x',
    );
    expect(recipe.title.length, 78);
    expect(recipe.title, endsWith('…'));
    expect(recipe.steps.single, long, reason: 'the step keeps the full text');
  });

  test('empty text falls back to the untitled label', () {
    final recipe = buildTemplateRecipe(
      id: 'r1',
      text: '   \n  ',
      channel: RecipeIngestionChannel.rawText,
      untitled: 'מתכון ללא שם',
    );
    expect(recipe.title, 'מתכון ללא שם');
    expect(recipe.steps, isEmpty);
  });

  test('the origin is kept so the details screen can retry the same way', () {
    final recipe = buildTemplateRecipe(
      id: 'r1',
      text: 'x',
      channel: RecipeIngestionChannel.urlScrape,
      untitled: 'x',
      sourceUrl: 'https://example.com/r',
    );
    expect(recipe.sourceChannel, RecipeIngestionChannel.urlScrape);
    expect(recipe.sourceUrl, 'https://example.com/r');
  });

  test('a blank recipe is empty, not pending, and marked as hand-written', () {
    final recipe = buildBlankRecipe(id: 'r1');
    expect(recipe.title, isEmpty);
    expect(recipe.steps, isEmpty);
    expect(recipe.ingredients, isEmpty);
    expect(recipe.pendingAnalysis, isFalse);
    expect(recipe.sourceChannel, RecipeIngestionChannel.manual);
  });
}
