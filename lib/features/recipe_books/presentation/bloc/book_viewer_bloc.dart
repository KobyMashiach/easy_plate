import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

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
