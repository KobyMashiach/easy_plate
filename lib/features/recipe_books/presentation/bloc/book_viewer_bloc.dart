import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/services/image_storage_service.dart';
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

  BookViewerBloc({
    required this.getBookByIdUseCase,
    required this.saveBookUseCase,
    required this.recipesRepository,
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
    );
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
    final book = await getBookByIdUseCase(event.bookId);
    if (book == null) {
      emit(const BookViewerState.notFound());
      return;
    }
    await _loadAndEmit(book, emit);
  }

  Future<void> _addRecipe(_AddRecipe event, Emitter<BookViewerState> emit) async {
    final current = state;
    if (current is! BookViewerLoaded) return;
    if (current.book.recipeRefs.any((r) => r.recipeId == event.recipeId)) return;
    final nextOrder = current.book.recipeRefs.length;
    final updatedBook = current.book.copyWith(
      recipeRefs: [
        ...current.book.recipeRefs,
        BookRecipeRefEntity(recipeId: event.recipeId, order: nextOrder),
      ],
    );
    await saveBookUseCase(updatedBook);
    await _loadAndEmit(updatedBook, emit);
  }

  /// Moves the recipe at [_ReorderRecipes.oldIndex] to
  /// [_ReorderRecipes.newIndex] and renumbers the whole list, so `order` stays
  /// a dense 0..n-1 sequence rather than drifting into gaps.
  Future<void> _reorderRecipes(_ReorderRecipes event, Emitter<BookViewerState> emit) async {
    final current = state;
    if (current is! BookViewerLoaded) return;

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
    await saveBookUseCase(updatedBook);
    await _loadAndEmit(updatedBook, emit);
  }

  /// Replacing or clearing the cover deletes the previous file so removed
  /// photos don't pile up in the app's image directory.
  Future<void> _setCoverImage(_SetCoverImage event, Emitter<BookViewerState> emit) async {
    final current = state;
    if (current is! BookViewerLoaded) return;

    final previous = current.book.coverImageFileName;
    final updatedBook = current.book.copyWith(
      coverImageFileName: event.fileName,
      removeCoverImage: event.fileName == null,
    );
    await saveBookUseCase(updatedBook);
    if (previous != null && previous != event.fileName) {
      await ImageStorageService().delete(previous);
    }
    await _loadAndEmit(updatedBook, emit);
  }

  Future<void> _removeRecipe(_RemoveRecipe event, Emitter<BookViewerState> emit) async {
    final current = state;
    if (current is! BookViewerLoaded) return;
    final updatedBook = current.book.copyWith(
      recipeRefs: current.book.recipeRefs.where((r) => r.recipeId != event.recipeId).toList(),
    );
    await saveBookUseCase(updatedBook);
    await _loadAndEmit(updatedBook, emit);
  }
}
