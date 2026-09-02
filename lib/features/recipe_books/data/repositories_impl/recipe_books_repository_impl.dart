import '../../domain/entities/recipe_book_entity.dart';
import '../../domain/repositories/recipe_books_repository.dart';
import '../datasources/recipe_books_local_datasource.dart';
import '../models/recipe_book_model.dart';

class RecipeBooksRepositoryImpl implements RecipeBooksRepository {
  final RecipeBooksLocalDataSource localDataSource;

  RecipeBooksRepositoryImpl({required this.localDataSource});

  @override
  Future<List<RecipeBookEntity>> getBooks() async {
    final models = await localDataSource.getBooks();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<RecipeBookEntity?> getBookById(String id) async {
    final model = await localDataSource.getBookById(id);
    return model?.toEntity();
  }

  @override
  Future<void> saveBook(RecipeBookEntity book) {
    return localDataSource.saveBook(book.toModel());
  }

  @override
  Future<void> deleteBook(String id) {
    return localDataSource.deleteBook(id);
  }
}
