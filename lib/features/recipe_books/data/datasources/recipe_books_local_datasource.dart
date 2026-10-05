import '../../../../core/hive/box_stream.dart';
import '../../../../core/hive/user_scope.dart';

import '../models/recipe_book_model.dart';

abstract class RecipeBooksLocalDataSource {
  Future<List<RecipeBookModel>> getBooks();

  /// The shelf, now and after every write — see [watchBoxValues].
  Stream<List<RecipeBookModel>> watchBooks();
  Future<RecipeBookModel?> getBookById(String id);
  Future<void> saveBook(RecipeBookModel book);
  Future<void> deleteBook(String id);
}

class RecipeBooksLocalDataSourceImpl implements RecipeBooksLocalDataSource {
  @override
  Future<List<RecipeBookModel>> getBooks() async {
    final box = await UserScope().open<RecipeBookModel>(
      RecipeBookModel.hiveKey,
    );
    return box.values.toList();
  }

  @override
  Stream<List<RecipeBookModel>> watchBooks() => watchBoxValues(
    () => UserScope().open<RecipeBookModel>(RecipeBookModel.hiveKey),
  );

  @override
  Future<RecipeBookModel?> getBookById(String id) async {
    final box = await UserScope().open<RecipeBookModel>(
      RecipeBookModel.hiveKey,
    );
    return box.get(id);
  }

  @override
  Future<void> saveBook(RecipeBookModel book) async {
    final box = await UserScope().open<RecipeBookModel>(
      RecipeBookModel.hiveKey,
    );
    await box.put(book.id, book);
  }

  @override
  Future<void> deleteBook(String id) async {
    final box = await UserScope().open<RecipeBookModel>(
      RecipeBookModel.hiveKey,
    );
    await box.delete(id);
  }
}
