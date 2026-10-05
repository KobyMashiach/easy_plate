import '../entities/recipe_book_entity.dart';
import '../repositories/recipe_books_repository.dart';

class WatchBooksUseCase {
  final RecipeBooksRepository repository;
  WatchBooksUseCase(this.repository);

  Stream<List<RecipeBookEntity>> call() => repository.watchBooks();
}
