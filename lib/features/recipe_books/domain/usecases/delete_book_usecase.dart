import '../repositories/recipe_books_repository.dart';

class DeleteBookUseCase {
  final RecipeBooksRepository repository;
  DeleteBookUseCase(this.repository);

  Future<void> call(String id) => repository.deleteBook(id);
}
