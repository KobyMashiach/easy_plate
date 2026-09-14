import 'package:easy_plate/core/constants/app_enums.dart';
import 'package:easy_plate/core/walkthrough/demo_content.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every sample recipe is complete enough to show every part of a page', () {
    for (final recipe in DemoContent.recipes()) {
      expect(recipe.title, isNotEmpty);
      expect(recipe.ingredients, isNotEmpty, reason: recipe.id);
      expect(recipe.steps, isNotEmpty, reason: recipe.id);
      expect(recipe.dietaryTags, isNotEmpty, reason: recipe.id);
      expect(recipe.prepTimeMinutes, isNotNull, reason: recipe.id);
      expect(recipe.sourceChannel, isNotNull, reason: recipe.id);
    }
  });

  test('the samples cover the allergy detail and every source channel', () {
    final recipes = DemoContent.recipes();
    expect(recipes.any((r) => r.allergens.isNotEmpty && r.mayContain.isNotEmpty), isTrue);
    expect(
      recipes.map((r) => r.sourceChannel).toSet(),
      containsAll([
        RecipeIngestionChannel.rawText,
        RecipeIngestionChannel.aiRequest,
        RecipeIngestionChannel.urlScrape,
        RecipeIngestionChannel.socialVideo,
        RecipeIngestionChannel.manual,
      ]),
    );
  });

  test('every sample book resolves all of its recipes, in order', () {
    for (final book in DemoContent.books()) {
      final recipes = DemoContent.recipesOf(book);
      expect(recipes, hasLength(book.recipeRefs.length), reason: book.id);
      expect(
        recipes.map((r) => r.id).toList(),
        book.orderedRefs.map((ref) => ref.recipeId).toList(),
      );
    }
  });
}
