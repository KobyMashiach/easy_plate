import '../entities/recipe_book_entity.dart';

abstract class RecipeBooksRepository {
  Future<List<RecipeBookEntity>> getBooks();
  Future<RecipeBookEntity?> getBookById(String id);
  Future<void> saveBook(RecipeBookEntity book);
  Future<void> deleteBook(String id);
}
