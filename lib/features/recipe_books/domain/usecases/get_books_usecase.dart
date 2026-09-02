import '../entities/recipe_book_entity.dart';
import '../repositories/recipe_books_repository.dart';

class GetBooksUseCase {
  final RecipeBooksRepository repository;
  GetBooksUseCase(this.repository);

  Future<List<RecipeBookEntity>> call() => repository.getBooks();
}
