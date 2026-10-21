import 'package:easy_plate/features/my_recipes/domain/entities/recipe_entity.dart';
import 'package:easy_plate/features/my_recipes/domain/entities/recipe_ingredient_entity.dart';
import 'package:easy_plate/features/my_recipes/presentation/pages/recipe_details_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final before = RecipeEntity(
    id: 'r',
    title: 'Soup',
    ingredients: const [],
    steps: const [],
    createdAt: DateTime(2026),
    imageFileName: 'a.jpg',
    sharedRecipeId: 'post1',
  );

  test('what landed while the editor was open is kept', () {
    final edited = before.copyWith(title: 'Better soup');
    // The photo upload wrote its path back; the post was taken down.
    final fresh = before.copyWith(
      imageStoragePath: 'users/u/a.jpg',
      clearSharedRecipeId: true,
    );
    final merged = mergeEditedRecipe(edited, before, fresh);
    expect(merged.title, 'Better soup');
    expect(merged.imageFileName, 'a.jpg');
    expect(merged.imageStoragePath, 'users/u/a.jpg');
    expect(merged.sharedRecipeId, isNull);
  });

  test('nothing changed elsewhere: the edit is saved as returned', () {
    final edited = before.copyWith(title: 'Better soup');
    expect(mergeEditedRecipe(edited, before, before), same(edited));
    expect(mergeEditedRecipe(edited, before, null), same(edited));
  });

  test('only a missing post unlinks the recipe', () {
    expect(
      isPostGone(
        FirebaseException(plugin: 'cloud_firestore', code: 'not-found'),
      ),
      isTrue,
    );
    expect(
      isPostGone(
        FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
      ),
      isFalse,
    );
    expect(isPostGone(StateError('timeout')), isFalse);
  });

  test(
    'pass 7: a field changed on the website and left alone here is kept',
    () {
      final edited = before.copyWith(steps: ['Boil', 'Serve']);
      final fresh = before.copyWith(title: 'Web soup', servings: 4);
      final merged = mergeEditedRecipe(edited, before, fresh);
      expect(merged.title, 'Web soup');
      expect(merged.servings, 4);
      expect(merged.steps, ['Boil', 'Serve']);
    },
  );

  test('pass 7: a field changed on both sides keeps the edit made here', () {
    final edited = before.copyWith(title: 'Phone soup');
    final fresh = before.copyWith(title: 'Web soup');
    expect(mergeEditedRecipe(edited, before, fresh).title, 'Phone soup');
  });

  test('pass 7: ingredients edited elsewhere survive a title edit here', () {
    final edited = before.copyWith(title: 'Better soup');
    final fresh = before.copyWith(
      ingredients: const [RecipeIngredientEntity(name: 'Salt', amount: 1)],
    );
    final merged = mergeEditedRecipe(edited, before, fresh);
    expect(merged.title, 'Better soup');
    expect(merged.ingredients.single.name, 'Salt');
  });
}
