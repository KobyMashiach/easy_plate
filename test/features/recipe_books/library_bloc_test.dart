import 'package:easy_plate/core/constants/app_enums.dart';
import 'package:easy_plate/core/hive/user_scope.dart';
import 'package:easy_plate/core/utils/i18n/strings.g.dart';
import 'package:easy_plate/features/collab_containers/domain/container_sharing_service.dart';
import 'package:easy_plate/features/collab_containers/domain/usecases/container_collab.dart';
import 'package:easy_plate/features/recipe_books/domain/entities/book_recipe_ref_entity.dart';
import 'package:easy_plate/features/recipe_books/domain/entities/book_spine.dart';
import 'package:easy_plate/features/recipe_books/domain/entities/recipe_book_entity.dart';
import 'package:easy_plate/features/recipe_books/domain/repositories/recipe_books_repository.dart';
import 'package:easy_plate/features/recipe_books/domain/usecases/delete_book_usecase.dart';
import 'package:easy_plate/features/recipe_books/domain/usecases/get_books_usecase.dart';
import 'package:easy_plate/features/recipe_books/domain/usecases/save_book_usecase.dart';
import 'package:easy_plate/features/recipe_books/presentation/bloc/library_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Sharing extends Mock implements ContainerSharingService {}

class _BookCollab extends Mock implements ContainerCollab<RecipeBookEntity> {}

class _FakeBook extends Fake implements RecipeBookEntity {}

class _Books implements RecipeBooksRepository {
  final stored = <String, RecipeBookEntity>{};

  @override
  Future<List<RecipeBookEntity>> getBooks() async => stored.values.toList();

  @override
  Future<RecipeBookEntity?> getBookById(String id) async => stored[id];

  @override
  Future<void> saveBook(
    RecipeBookEntity book, {
    bool stampLanguage = true,
  }) async => stored[book.id] = book;

  @override
  Future<void> deleteBook(String id) async => stored.remove(id);

  @override
  Future<RecipeBookEntity> readyForSharing(RecipeBookEntity book) async => book;

  @override
  noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeBook());
    return LocaleSettings.setLocale(AppLocale.en);
  });

  late _Books books;
  late LibraryBloc bloc;

  RecipeBookEntity book({
    String title = 'Book',
    List<String> refs = const [],
  }) => RecipeBookEntity(
    id: 'b',
    title: title,
    recipeRefs: [
      for (var i = 0; i < refs.length; i++)
        BookRecipeRefEntity(recipeId: refs[i], order: i),
    ],
    createdAt: DateTime(2026),
  );

  setUp(() async {
    books = _Books()..stored['b'] = book(refs: ['r1']);
    bloc = LibraryBloc(
      getBooksUseCase: GetBooksUseCase(books),
      saveBookUseCase: SaveBookUseCase(books),
      deleteBookUseCase: DeleteBookUseCase(books),
    );
    await bloc.stream.firstWhere((s) => s is LibraryLoaded);
  });

  tearDown(() => bloc.close());

  test('pass 7: a rename keeps a recipe added elsewhere meanwhile', () async {
    // The website added a recipe after the shelf read the book.
    books.stored['b'] = book(refs: ['r1', 'r2']);
    bloc.add(const LibraryEvent.renameBook('b', 'Shabbat'));
    await bloc.stream.firstWhere((s) => s is LibraryLoaded);
    expect(books.stored['b']!.title, 'Shabbat');
    expect(books.stored['b']!.recipeRefs.map((r) => r.recipeId), ['r1', 'r2']);
  });

  test('pass 7: a spine change keeps a rename made elsewhere', () async {
    books.stored['b'] = book(title: 'Web title', refs: ['r1']);
    bloc.add(const LibraryEvent.setSpine('b', BookSpine.teal));
    await bloc.stream.firstWhere((s) => s is LibraryLoaded);
    expect(books.stored['b']!.title, 'Web title');
  });

  test(
    'pass 7: a rename of a book deleted elsewhere does not revive it',
    () async {
      books.stored.remove('b');
      bloc.add(const LibraryEvent.renameBook('b', 'Shabbat'));
      await bloc.stream.firstWhere((s) => s is LibraryLoaded);
      expect(books.stored, isEmpty);
    },
  );

  test('a refused publish of a shared rename keeps the shelf', () async {
    UserScope().resetForTest();
    await UserScope().switchTo('me');
    addTearDown(UserScope().resetForTest);
    books.stored['b'] = book(
      refs: ['r1'],
    ).copyWith(collabId: 'c', collabRole: CollabRole.editor);
    final sharing = _Sharing();
    final collab = _BookCollab();
    when(() => sharing.books).thenReturn(collab);
    when(
      () => collab.publish(any(), uid: any(named: 'uid')),
    ).thenThrow(Exception('permission-denied'));
    final shared = LibraryBloc(
      getBooksUseCase: GetBooksUseCase(books),
      saveBookUseCase: SaveBookUseCase(books),
      deleteBookUseCase: DeleteBookUseCase(books),
      sharing: sharing,
    );
    addTearDown(shared.close);
    await shared.stream.firstWhere((s) => s is LibraryLoaded);
    shared.add(const LibraryEvent.renameBook('b', 'Shabbat'));
    final next = await shared.stream.first;
    expect(next, isA<LibraryLoaded>());
    expect(books.stored['b']!.title, 'Shabbat');
  });
}
