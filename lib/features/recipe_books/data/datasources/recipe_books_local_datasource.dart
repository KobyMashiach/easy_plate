import '../../../../core/hive/user_scope.dart';

import '../models/recipe_book_model.dart';

abstract class RecipeBooksLocalDataSource {
  Future<List<RecipeBookModel>> getBooks();
  Future<RecipeBookModel?> getBookById(String id);
  Future<void> saveBook(RecipeBookModel book);
  Future<void> deleteBook(String id);
}

class RecipeBooksLocalDataSourceImpl implements RecipeBooksLocalDataSource {
  @override
  Future<List<RecipeBookModel>> getBooks() async {
    final box = await UserScope().open<RecipeBookModel>(RecipeBookModel.hiveKey);
    return box.values.toList();
  }

  @override
  Future<RecipeBookModel?> getBookById(String id) async {
    final box = await UserScope().open<RecipeBookModel>(RecipeBookModel.hiveKey);
    return box.get(id);
  }

  @override
  Future<void> saveBook(RecipeBookModel book) async {
    final box = await UserScope().open<RecipeBookModel>(RecipeBookModel.hiveKey);
    await box.put(book.id, book);
  }

  @override
  Future<void> deleteBook(String id) async {
    final box = await UserScope().open<RecipeBookModel>(RecipeBookModel.hiveKey);
    await box.delete(id);
  }
}
