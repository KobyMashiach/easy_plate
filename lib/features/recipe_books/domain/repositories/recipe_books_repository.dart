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

  /// The book with its cover guaranteed uploaded, for the paths that publish
  /// it to other accounts — the books twin of
  /// `RecipesRepository.readyForSharing`.
  ///
  /// [saveBook] uploads the cover in the background. A shared book published
  /// in the seconds after its cover was picked would go out with no
  /// `coverImageStoragePath`, and the members' copies would stay coverless.
  /// Waits for the upload the save started rather than starting another.
  /// Returns the book unchanged when there is nothing to upload or the
  /// upload failed.
  Future<RecipeBookEntity> readyForSharing(RecipeBookEntity book);
}
