import 'dart:async';

import '../../../../core/hive/user_scope.dart';
import '../../../../core/sync/recipe_image_store.dart';
import '../../../../core/sync/user_cloud_collection.dart';
import '../../../../core/translation/content_translation.dart';
import '../../domain/entities/recipe_book_entity.dart';
import '../../domain/repositories/recipe_books_repository.dart';
import '../datasources/recipe_books_local_datasource.dart';
import '../models/recipe_book_model.dart';

class RecipeBooksRepositoryImpl implements RecipeBooksRepository {
  final RecipeBooksLocalDataSource localDataSource;

  /// Mirrors every write into the account's own Firestore subtree, so the
  /// library travels with the account for the same reason its recipes do.
  final UserCloudCollection<RecipeBookModel>? cloud;

  /// Sends the cover photo itself to Storage; the mirror carries only fields.
  final RecipeImageStore? images;

  RecipeBooksRepositoryImpl({
    required this.localDataSource,
    this.cloud,
    this.images,
  });

  @override
  Future<List<RecipeBookEntity>> getBooks() async {
    final models = await localDataSource.getBooks();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Stream<List<RecipeBookEntity>> watchBooks() => localDataSource
      .watchBooks()
      .map((models) => models.map((m) => m.toEntity()).toList());

  @override
  Future<RecipeBookEntity?> getBookById(String id) async {
    final model = await localDataSource.getBookById(id);
    return model?.toEntity();
  }

  @override
  Future<void> saveBook(
    RecipeBookEntity book, {
    bool stampLanguage = true,
  }) async {
    if (stampLanguage) {
      book = await _stamped(book);
    }
    final model = book.toModel();
    await localDataSource.saveBook(model);
    unawaited(_publish(model));
  }

  /// Uploads the cover if it has not travelled yet, then mirrors the book.
  /// Not awaited by [saveBook] — the library should not wait on a picture.
  Future<void> _publish(RecipeBookModel model) async {
    final store = images;
    final fileName = model.coverImageFileName;
    final uid = UserScope().uid;

    RecipeBookModel? uploaded;
    if (store != null &&
        fileName != null &&
        uid != null &&
        model.coverImageStoragePath == null) {
      final path = await store.upload(fileName, uid: uid);
      // A failed upload leaves the path null so the next save tries again,
      // rather than recording one that resolves to nothing.
      if (path != null) {
        uploaded = model.copyWith(coverImageStoragePath: path);
        await localDataSource.saveBook(uploaded);
      }
    }

    await (cloud?.push(uploaded ?? model) ?? Future.value());
  }

  @override
  Future<void> deleteBook(String id) async {
    // Read first, so the cover goes with the book rather than being left in the
    // bucket with nothing pointing at it.
    final doomed = await localDataSource.getBookById(id);
    await localDataSource.deleteBook(id);
    unawaited(cloud?.remove(id) ?? Future.value());
    unawaited(
      images?.remove(doomed?.coverImageStoragePath, uid: UserScope().uid) ??
          Future.value(),
    );
  }

  /// See the same method on the recipes repository.
  Future<RecipeBookEntity> _stamped(RecipeBookEntity book) async {
    // One key lookup, not the whole box mapped to find one record.
    final previous = (await localDataSource.getBookById(book.id))?.toEntity();
    final edited = previous == null || previous.title != book.title;
    if (!edited && book.contentLang != null) return book;
    return book.copyWith(
      contentLang: currentContentLanguage().code,
      contentVersion: edited && previous != null
          ? previous.contentVersion + 1
          : book.contentVersion,
    );
  }
}
