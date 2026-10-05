import '../entities/recipe_book_entity.dart';

abstract class RecipeBooksRepository {
  Future<List<RecipeBookEntity>> getBooks();

  /// The shelf, kept current as books are written from anywhere: an
  /// accepted invite, a co-editor's change pulled on resume, a language
  /// switch. The library tab lives in an IndexedStack and would otherwise
  /// show the shelf as it was when the app started.
  Stream<List<RecipeBookEntity>> watchBooks();
  Future<RecipeBookEntity?> getBookById(String id);

  /// See [RecipesRepository.saveRecipe] for [stampLanguage].
  Future<void> saveBook(RecipeBookEntity book, {bool stampLanguage = true});
  Future<void> deleteBook(String id);
}
