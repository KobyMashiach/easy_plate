import '../entities/recipe_book_entity.dart';
import '../repositories/recipe_books_repository.dart';

class SaveBookUseCase {
  final RecipeBooksRepository repository;
  SaveBookUseCase(this.repository);

  Future<void> call(RecipeBookEntity book) => repository.saveBook(book);
}
