import 'package:easy_plate/core/sync/recipe_image_store.dart';
import 'package:easy_plate/features/my_recipes/domain/entities/recipe_entity.dart';
import 'package:easy_plate/features/recipe_books/domain/entities/recipe_book_entity.dart';
import 'package:flutter_test/flutter_test.dart';

/// A recipe photo lives on disk under a file name and in Storage under a path,
/// and the two have to stay in step. When they drift, nothing crashes — every
/// other copy of the recipe just quietly shows the wrong picture, or none.
void main() {
  RecipeEntity buildRecipe({String? fileName = 'old.jpg', String? storagePath}) => RecipeEntity(
        id: 'r1',
        title: 'שקשוקה',
        ingredients: const [],
        steps: const [],
        createdAt: DateTime.utc(2026, 9, 7),
        imageFileName: fileName,
        imageStoragePath: storagePath,
      );

  group('replacing a recipe photo', () {
    test('a new file drops the path the old one was uploaded to', () {
      final recipe = buildRecipe(storagePath: 'recipe_images/uid-1/old.jpg');

      final updated = recipe.copyWith(imageFileName: 'new.jpg');

      expect(updated.imageFileName, 'new.jpg');
      // Carrying the old path over is the bug worth guarding: the shared copy,
      // the community post and the same account on another phone would all go
      // on showing the picture that was just replaced.
      expect(updated.imageStoragePath, isNull);
    });

    test('removing the photo drops both halves', () {
      final recipe = buildRecipe(storagePath: 'recipe_images/uid-1/old.jpg');

      final updated = recipe.copyWith(removeImage: true);

      expect(updated.imageFileName, isNull);
      expect(updated.imageStoragePath, isNull);
    });

    test('an edit that does not touch the photo keeps it uploaded', () {
      final recipe = buildRecipe(storagePath: 'recipe_images/uid-1/old.jpg');

      final updated = recipe.copyWith(title: 'שקשוקה חריפה');

      expect(updated.imageFileName, 'old.jpg');
      // Otherwise every rename would re-upload the same bytes.
      expect(updated.imageStoragePath, 'recipe_images/uid-1/old.jpg');
    });

    test('the upload result can be recorded without disturbing the file name', () {
      final recipe = buildRecipe();

      final updated = recipe.copyWith(imageStoragePath: 'recipe_images/uid-1/old.jpg');

      expect(updated.imageFileName, 'old.jpg');
      expect(updated.imageStoragePath, 'recipe_images/uid-1/old.jpg');
    });
  });

  group('replacing a book cover', () {
    RecipeBookEntity buildBook({String? storagePath}) => RecipeBookEntity(
          id: 'b1',
          title: 'האוסף שלי',
          recipeRefs: const [],
          createdAt: DateTime.utc(2026, 9, 1),
          coverImageFileName: 'old.png',
          coverImageStoragePath: storagePath,
        );

    test('a new cover drops the old upload, and clearing drops both', () {
      final book = buildBook(storagePath: 'recipe_images/uid-1/old.png');

      expect(book.copyWith(coverImageFileName: 'new.png').coverImageStoragePath, isNull);

      final cleared = book.copyWith(removeCoverImage: true);
      expect(cleared.coverImageFileName, isNull);
      expect(cleared.coverImageStoragePath, isNull);
    });

    test('renaming the book leaves the cover alone', () {
      final book = buildBook(storagePath: 'recipe_images/uid-1/old.png');
      final renamed = book.copyWith(title: 'אוסף חדש');

      expect(renamed.coverImageStoragePath, 'recipe_images/uid-1/old.png');
    });
  });

  group('RecipeImageStore.ownsPath', () {
    test('an account may delete its own photo', () {
      expect(RecipeImageStore.ownsPath('recipe_images/uid-1/a.jpg', 'uid-1'), isTrue);
    });

    test('a recipe saved from the community keeps the author\'s path, and it is theirs', () {
      // Importing a community recipe copies the author's Storage path rather
      // than re-uploading. Deleting that saved copy must not try to strip the
      // picture off the original post.
      expect(RecipeImageStore.ownsPath('recipe_images/author-9/a.jpg', 'uid-1'), isFalse);
    });

    test('a uid that merely prefixes another is not a match', () {
      expect(RecipeImageStore.ownsPath('recipe_images/uid-10/a.jpg', 'uid-1'), isFalse);
    });

    test('nothing to delete, and no account, are both refusals', () {
      expect(RecipeImageStore.ownsPath(null, 'uid-1'), isFalse);
      expect(RecipeImageStore.ownsPath('recipe_images/uid-1/a.jpg', null), isFalse);
      expect(RecipeImageStore.ownsPath('recipe_images/uid-1/a.jpg', ''), isFalse);
    });
  });
}
