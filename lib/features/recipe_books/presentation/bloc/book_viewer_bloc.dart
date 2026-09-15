import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/hive/user_scope.dart';
import '../../../../core/services/image_storage_service.dart';
import '../../../../core/sync/recipe_image_store.dart';
import '../../../collab_containers/domain/container_sharing_service.dart';
import '../../../my_recipes/domain/entities/recipe_entity.dart';
import '../../../my_recipes/domain/repositories/recipes_repository.dart';
import '../../domain/entities/book_recipe_ref_entity.dart';
import '../../domain/entities/recipe_book_entity.dart';
import '../../domain/repositories/recipe_books_repository.dart';
import '../../domain/usecases/get_book_by_id_usecase.dart';
import '../../domain/usecases/save_book_usecase.dart';

part 'book_viewer_bloc.freezed.dart';

@freezed
sealed class BookViewerEvent with _$BookViewerEvent {
  const factory BookViewerEvent.init(String bookId) = _Init;
  const factory BookViewerEvent.addRecipe(String recipeId) = _AddRecipe;
  const factory BookViewerEvent.removeRecipe(String recipeId) = _RemoveRecipe;
  const factory BookViewerEvent.reorderRecipes(int oldIndex, int newIndex) = _ReorderRecipes;
  const factory BookViewerEvent.setCoverImage(String? fileName) = _SetCoverImage;
}

@freezed
sealed class BookViewerState with _$BookViewerState {
  const factory BookViewerState.loading() = BookViewerLoading;
  const factory BookViewerState.loaded(RecipeBookEntity book, List<RecipeEntity> recipes) =
      BookViewerLoaded;
  const factory BookViewerState.notFound() = BookViewerNotFound;
}

class BookViewerBloc extends Bloc<BookViewerEvent, BookViewerState> {
  final GetBookByIdUseCase getBookByIdUseCase;
  final SaveBookUseCase saveBookUseCase;
  final RecipesRepository recipesRepository;

  /// Refreshes a shared book on open and carries edits to it across
  /// accounts. Null in tests.
  final ContainerSharingService? sharing;

  BookViewerBloc({
    required this.getBookByIdUseCase,
    required this.saveBookUseCase,
    required this.recipesRepository,
    this.sharing,
  }) : super(const BookViewerState.loading()) {
    on<_Init>(_init);
    on<_AddRecipe>(_addRecipe);
    on<_RemoveRecipe>(_removeRecipe);
    on<_ReorderRecipes>(_reorderRecipes);
    on<_SetCoverImage>(_setCoverImage);
  }

  factory BookViewerBloc.fromContext(BuildContext context) {
    return BookViewerBloc(
      getBookByIdUseCase: GetBookByIdUseCase(context.read<RecipeBooksRepository>()),
      saveBookUseCase: SaveBookUseCase(context.read<RecipeBooksRepository>()),
      recipesRepository: context.read(),
      sharing: context.read(),
    );
  }

  Future<void> _saveAndPublish(RecipeBookEntity book) async {
    await saveBookUseCase(book);
    final uid = UserScope().uid;
    if (book.isShared && uid != null) await sharing?.books.publish(book, uid: uid);
  }

  Future<void> _loadAndEmit(RecipeBookEntity book, Emitter<BookViewerState> emit) async {
    final recipes = <RecipeEntity>[];
    for (final ref in book.orderedRefs) {
      final recipe = await recipesRepository.getRecipeById(ref.recipeId);
      if (recipe != null) recipes.add(recipe);
    }
    emit(.loaded(book, recipes));
  }

  Future<void> _init(_Init event, Emitter<BookViewerState> emit) async {
    final stored = await getBookByIdUseCase(event.bookId);
    if (stored == null) {
      emit(const BookViewerState.notFound());
      return;
    }
    var book = stored;
    // A shared book is refreshed from its document on open, the way a shared
    // recipe is; offline, the cached copy is shown as it is.
    final uid = UserScope().uid;
    if (book.isShared && uid != null && sharing != null) {
      try {
        book = await sharing!.books.sync(book, uid: uid);
      } catch (e) {
        debugPrint('Shared book refresh failed: $e');
      }
    }
    await _loadAndEmit(book, emit);
  }

  Future<void> _addRecipe(_AddRecipe event, Emitter<BookViewerState> emit) async {
    final current = state;
    if (current is! BookViewerLoaded) return;
    if (!current.book.canEdit) return;
    if (current.book.recipeRefs.any((r) => r.recipeId == event.recipeId)) return;
    final nextOrder = current.book.recipeRefs.length;
    final updatedBook = current.book.copyWith(
      recipeRefs: [
        ...current.book.recipeRefs,
        BookRecipeRefEntity(recipeId: event.recipeId, order: nextOrder),
      ],
    );
    await _saveAndPublish(updatedBook);
    await _loadAndEmit(updatedBook, emit);
  }

  /// Moves the recipe at [_ReorderRecipes.oldIndex] to
  /// [_ReorderRecipes.newIndex] and renumbers the whole list, so `order` stays
  /// a dense 0..n-1 sequence rather than drifting into gaps.
  Future<void> _reorderRecipes(_ReorderRecipes event, Emitter<BookViewerState> emit) async {
    final current = state;
    if (current is! BookViewerLoaded) return;

    if (!current.book.canEdit) return;
    final refs = [...current.book.orderedRefs];
    if (event.oldIndex < 0 || event.oldIndex >= refs.length) return;
    final newIndex = event.newIndex.clamp(0, refs.length - 1);
    if (newIndex == event.oldIndex) return;

    refs.insert(newIndex, refs.removeAt(event.oldIndex));

    final updatedBook = current.book.copyWith(
      recipeRefs: [
        for (var i = 0; i < refs.length; i++)
          BookRecipeRefEntity(recipeId: refs[i].recipeId, order: i),
      ],
    );
    await _saveAndPublish(updatedBook);
    await _loadAndEmit(updatedBook, emit);
  }

  /// Replacing or clearing the cover deletes the previous file so removed
  /// photos don't pile up in the app's image directory.
  Future<void> _setCoverImage(_SetCoverImage event, Emitter<BookViewerState> emit) async {
    final current = state;
    if (current is! BookViewerLoaded) return;

    if (!current.book.canEdit) return;

    final previous = current.book.coverImageFileName;
    // Read before the copyWith clears it, so the replaced upload can go too.
    final previousRemote = current.book.coverImageStoragePath;
    var updatedBook = current.book.copyWith(
      coverImageFileName: event.fileName,
      removeCoverImage: event.fileName == null,
    );
    await saveBookUseCase(updatedBook);
    if (previous != null && previous != event.fileName) {
      await ImageStorageService().delete(previous);
      // A shared book's members still point at the uploaded cover; it stays.
      if (!current.book.isShared) {
        unawaited(RecipeImageStore().remove(previousRemote, uid: UserScope().uid));
      }
    }
    final uid = UserScope().uid;
    if (updatedBook.isShared && uid != null) {
      // The cover has to travel before the document says where it is; the
      // repository uploads it after the save, so re-read for the path.
      updatedBook = await getBookByIdUseCase(updatedBook.id) ?? updatedBook;
      await sharing?.books.publish(updatedBook, uid: uid);
    }
    await _loadAndEmit(updatedBook, emit);
  }

  Future<void> _removeRecipe(_RemoveRecipe event, Emitter<BookViewerState> emit) async {
    final current = state;
    if (current is! BookViewerLoaded || !current.book.canEdit) return;
    final updatedBook = current.book.copyWith(
      recipeRefs: current.book.recipeRefs.where((r) => r.recipeId != event.recipeId).toList(),
    );
    await _saveAndPublish(updatedBook);
    await _loadAndEmit(updatedBook, emit);
  }
}
