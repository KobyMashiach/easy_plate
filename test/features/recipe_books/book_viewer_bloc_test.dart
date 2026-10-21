import 'package:easy_plate/core/constants/app_enums.dart';
import 'package:easy_plate/core/hive/user_scope.dart';
import 'package:easy_plate/features/collab_containers/domain/container_sharing_service.dart';
import 'package:easy_plate/features/collab_containers/domain/usecases/container_collab.dart';
import 'package:easy_plate/features/my_recipes/domain/entities/recipe_entity.dart';
import 'package:easy_plate/features/my_recipes/domain/repositories/recipes_repository.dart';
import 'package:easy_plate/features/recipe_books/domain/entities/book_recipe_ref_entity.dart';
import 'package:easy_plate/features/recipe_books/domain/entities/recipe_book_entity.dart';
import 'package:easy_plate/features/recipe_books/domain/repositories/recipe_books_repository.dart';
import 'package:easy_plate/features/recipe_books/domain/usecases/get_book_by_id_usecase.dart';
import 'package:easy_plate/features/recipe_books/domain/usecases/save_book_usecase.dart';
import 'package:easy_plate/features/recipe_books/presentation/bloc/book_viewer_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Books extends Mock implements RecipeBooksRepository {}

class _Recipes extends Mock implements RecipesRepository {}

class _FakeBook extends Fake implements RecipeBookEntity {}

class _Sharing extends Mock implements ContainerSharingService {}

class _BookCollab extends Mock implements ContainerCollab<RecipeBookEntity> {}

void main() {
  setUpAll(() => registerFallbackValue(_FakeBook()));

  late _Books books;
  late _Recipes recipes;
  late RecipeBookEntity stored;
  late BookViewerBloc bloc;

  RecipeEntity recipe(String id) => RecipeEntity(
    id: id,
    title: id,
    createdAt: DateTime(2026),
    ingredients: const [],
    steps: const [],
  );

  setUp(() async {
    books = _Books();
    recipes = _Recipes();
    // r2 is a ref to a recipe this device does not have.
    stored = RecipeBookEntity(
      id: 'b',
      title: 'Book',
      recipeRefs: const [
        BookRecipeRefEntity(recipeId: 'r1', order: 0),
        BookRecipeRefEntity(recipeId: 'r2', order: 1),
        BookRecipeRefEntity(recipeId: 'r3', order: 2),
      ],
      createdAt: DateTime(2026),
    );
    when(() => books.getBookById('b')).thenAnswer((_) async => stored);
    when(
      () => books.saveBook(any(), stampLanguage: any(named: 'stampLanguage')),
    ).thenAnswer((inv) async {
      // A slow disk: long enough for a second tap to arrive mid-save.
      await Future<void>.delayed(const Duration(milliseconds: 30));
      stored = inv.positionalArguments.first as RecipeBookEntity;
    });
    when(() => recipes.getRecipeById(any())).thenAnswer((inv) async {
      final id = inv.positionalArguments.first as String;
      return id == 'r2' ? null : recipe(id);
    });
    bloc = BookViewerBloc(
      getBookByIdUseCase: GetBookByIdUseCase(books),
      saveBookUseCase: SaveBookUseCase(books),
      recipesRepository: recipes,
    );
    bloc.add(const BookViewerEvent.init('b'));
    await Future<void>.delayed(const Duration(milliseconds: 20));
  });

  tearDown(() => bloc.close());

  List<String> ids() => [for (final r in stored.orderedRefs) r.recipeId];

  test('an add and a remove tapped together both land', () async {
    bloc
      ..add(const BookViewerEvent.addRecipe('r4'))
      ..add(const BookViewerEvent.removeRecipe('r1'));
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(ids(), containsAll(['r3', 'r4']));
    expect(ids(), isNot(contains('r1')));
  });

  test('a reorder moves the recipe shown at that position', () async {
    // On screen: r1, r3. Dragging r3 to the top.
    bloc.add(const BookViewerEvent.reorderRecipes(1, 0));
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(ids(), ['r3', 'r1', 'r2']);
  });

  test('a book that fails to read ends on not-found, not a spinner', () async {
    when(() => books.getBookById('x')).thenThrow(StateError('box closed'));
    final other = BookViewerBloc(
      getBookByIdUseCase: GetBookByIdUseCase(books),
      saveBookUseCase: SaveBookUseCase(books),
      recipesRepository: recipes,
    );
    addTearDown(other.close);
    other.add(const BookViewerEvent.init('x'));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(other.state, isA<BookViewerNotFound>());
  });

  test(
    'settled waits for queued reorders (quick-nav looks ids up after)',
    () async {
      bloc
        ..add(const BookViewerEvent.reorderRecipes(1, 0))
        ..add(const BookViewerEvent.reorderRecipes(1, 0));
      await Future<void>.delayed(Duration.zero);
      await bloc.settled;
      final state = bloc.state as BookViewerLoaded;
      // Two swaps of the two shown recipes: back where they started.
      expect([for (final r in state.recipes) r.id], ['r1', 'r3']);
      bloc.add(const BookViewerEvent.reorderRecipes(1, 0));
      await Future<void>.delayed(Duration.zero);
      await bloc.settled;
      expect(
        [
          for (final r in (bloc.state as BookViewerLoaded).recipes) r.id,
        ],
        ['r3', 'r1'],
      );
    },
  );

  test('pass 7: an add keeps a rename the website made meanwhile', () async {
    // Written elsewhere after the viewer read the book.
    stored = RecipeBookEntity(
      id: 'b',
      title: 'Renamed on the web',
      recipeRefs: stored.recipeRefs,
      createdAt: DateTime(2026),
    );
    bloc.add(const BookViewerEvent.addRecipe('r4'));
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(stored.title, 'Renamed on the web');
    expect(ids(), ['r1', 'r2', 'r3', 'r4']);
  });

  test(
    'pass 7: an edit to a book deleted elsewhere does not revive it',
    () async {
      when(() => books.getBookById('b')).thenAnswer((_) async => null);
      bloc.add(const BookViewerEvent.removeRecipe('r1'));
      await Future<void>.delayed(const Duration(milliseconds: 100));
      verifyNever(
        () => books.saveBook(any(), stampLanguage: any(named: 'stampLanguage')),
      );
      expect(bloc.state, isA<BookViewerNotFound>());
    },
  );

  test(
    'pass 8: a refused publish still ends the edit, the local save standing',
    () async {
      UserScope().resetForTest();
      await UserScope().switchTo('me');
      addTearDown(UserScope().resetForTest);
      stored = stored.copyWith(collabId: 'c', collabRole: CollabRole.editor);
      final sharing = _Sharing();
      final collab = _BookCollab();
      when(() => sharing.books).thenReturn(collab);
      when(
        () => collab.sync(any(), uid: any(named: 'uid')),
      ).thenAnswer(
        (inv) async => inv.positionalArguments.first as RecipeBookEntity,
      );
      when(
        () => collab.publish(any(), uid: any(named: 'uid')),
      ).thenThrow(Exception('[cloud_firestore/permission-denied]'));
      when(() => books.readyForSharing(any())).thenAnswer(
        (inv) async => inv.positionalArguments.first as RecipeBookEntity,
      );
      final shared = BookViewerBloc(
        getBookByIdUseCase: GetBookByIdUseCase(books),
        saveBookUseCase: SaveBookUseCase(books),
        recipesRepository: recipes,
        sharing: sharing,
      );
      addTearDown(shared.close);
      shared.add(const BookViewerEvent.init('b'));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final next = shared.stream.first.timeout(const Duration(seconds: 2));
      shared.add(const BookViewerEvent.addRecipe('r4'));
      final state = await next;
      expect(state, isA<BookViewerLoaded>());
      expect(ids(), contains('r4'));
    },
  );
}
