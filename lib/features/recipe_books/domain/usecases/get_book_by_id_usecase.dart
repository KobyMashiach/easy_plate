import '../entities/recipe_book_entity.dart';
import '../repositories/recipe_books_repository.dart';

class GetBookByIdUseCase {
  final RecipeBooksRepository repository;
  GetBookByIdUseCase(this.repository);

  Future<RecipeBookEntity?> call(String id) => repository.getBookById(id);
}
