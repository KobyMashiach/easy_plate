import 'dart:async';

import 'package:easy_plate/core/hive/user_scope.dart';
import 'package:easy_plate/core/sync/recipe_image_store.dart';
import 'package:easy_plate/core/sync/user_cloud_collection.dart';
import 'package:easy_plate/features/recipe_books/data/datasources/recipe_books_local_datasource.dart';
import 'package:easy_plate/features/recipe_books/data/models/recipe_book_model.dart';
import 'package:easy_plate/features/recipe_books/data/repositories_impl/recipe_books_repository_impl.dart';
import 'package:easy_plate/features/recipe_books/domain/entities/recipe_book_entity.dart';
import 'package:flutter_test/flutter_test.dart';

class _Local implements RecipeBooksLocalDataSource {
  final Map<String, RecipeBookModel> store = {};
  @override
  Future<List<RecipeBookModel>> getBooks() async => store.values.toList();
  @override
  Stream<List<RecipeBookModel>> watchBooks() =>
      Stream.value(store.values.toList());
  @override
  Future<RecipeBookModel?> getBookById(String id) async => store[id];
  @override
  Future<void> saveBook(RecipeBookModel book) async => store[book.id] = book;
  @override
  Future<void> deleteBook(String id) async => store.remove(id);
}

/// Counts uploads and, when gated, holds them until the test lets go.
class _Images implements RecipeImageStore {
  int uploads = 0;
  String? result = 'recipe_images/u1/cover.jpg';
  Completer<void>? gate;
  @override
  Future<String?> upload(String fileName, {required String uid}) async {
    uploads++;
    if (gate != null) await gate!.future;
    return result;
  }

  @override
  Future<void> remove(String? storagePath, {required String? uid}) async {}
  @override
  Future<String?> ensureCached(String fileName, String storagePath) async =>
      null;
  @override
  void resetForTest() {}
}

class _Cloud implements UserCloudCollection<RecipeBookModel> {
  final pushed = <RecipeBookModel>[];
  @override
  Future<void> push(RecipeBookModel value) async => pushed.add(value);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _Local local;
  late _Images images;
  late _Cloud cloud;
  late RecipeBooksRepositoryImpl repository;

  final book = RecipeBookEntity(
    id: 'b1',
    title: 'Shabbat',
    recipeRefs: const [],
    createdAt: DateTime(2026, 1, 1),
    coverImageFileName: 'cover.jpg',
    collabId: 'c1',
  );

  setUp(() async {
    await UserScope().switchTo('u1');
    local = _Local();
    images = _Images();
    cloud = _Cloud();
    repository = RecipeBooksRepositoryImpl(
      localDataSource: local,
      cloud: cloud,
      images: images,
    );
  });
  tearDown(() => UserScope().resetForTest());

  test(
    'a share right after a save waits for the one upload the save started',
    () async {
      images.gate = Completer<void>();
      await repository.saveBook(book);
      // The save returned with the cover still travelling.
      expect(images.uploads, 1);
      expect(local.store['b1']!.coverImageStoragePath, isNull);

      final ready = repository.readyForSharing(book);
      await Future<void>.delayed(Duration.zero);
      expect(images.uploads, 1, reason: 'no second upload of the same file');

      images.gate!.complete();
      final published = await ready;
      expect(published.coverImageStoragePath, 'recipe_images/u1/cover.jpg');
      expect(
        local.store['b1']!.coverImageStoragePath,
        'recipe_images/u1/cover.jpg',
      );
      await Future<void>.delayed(Duration.zero);
      expect(
        cloud.pushed.map((m) => m.coverImageStoragePath),
        contains('recipe_images/u1/cover.jpg'),
      );
      // The title the save stamped is kept, not overwritten by the entity.
      expect(local.store['b1']!.contentLang, isNotNull);
    },
  );

  test('a failed upload leaves the book as it was, to try again', () async {
    images.result = null;
    await repository.saveBook(book);
    // Let the save's own attempt settle, so the share tries afresh.
    await Future<void>.delayed(Duration.zero);
    final ready = await repository.readyForSharing(book);
    expect(ready.coverImageStoragePath, isNull);
    expect(local.store['b1']!.coverImageStoragePath, isNull);
    // The in-flight entry is gone, so the next attempt really uploads again.
    await repository.readyForSharing(book);
    expect(images.uploads, 3);
  });

  test('nothing to upload is a no-op', () async {
    await repository.readyForSharing(
      book.copyWith(coverImageStoragePath: 'recipe_images/u1/cover.jpg'),
    );
    await repository.readyForSharing(book.copyWith(removeCoverImage: true));
    expect(images.uploads, 0);
  });

  test(
    'a cover replaced while the first one travelled is not undone',
    () async {
      images.gate = Completer<void>();
      final ready = repository.readyForSharing(book);
      await local.saveBook(
        book.copyWith(coverImageFileName: 'other.jpg').toModel(),
      );
      images.gate!.complete();
      final published = await ready;
      // The caller still gets its path; the box keeps the newer cover.
      expect(published.coverImageStoragePath, 'recipe_images/u1/cover.jpg');
      expect(local.store['b1']!.coverImageFileName, 'other.jpg');
      expect(local.store['b1']!.coverImageStoragePath, isNull);
    },
  );

  test('pass 7: a failed upload pushes the book as it is now', () async {
    images
      ..result = null
      ..gate = Completer<void>();
    await repository.saveBook(book);
    // Renamed (here, or pulled in from the website) while the cover travelled.
    local.store['b1'] = local.store['b1']!.copyWith(title: 'Renamed');
    images.gate!.complete();
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(cloud.pushed.last.title, 'Renamed');
  });
}
