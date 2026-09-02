import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/recipe_book_entity.dart';
import '../../domain/usecases/delete_book_usecase.dart';
import '../../domain/usecases/get_books_usecase.dart';
import '../../domain/usecases/save_book_usecase.dart';

part 'library_bloc.freezed.dart';

@freezed
sealed class LibraryEvent with _$LibraryEvent {
  const factory LibraryEvent.init() = _Init;
  const factory LibraryEvent.createBook(String title) = _CreateBook;
  const factory LibraryEvent.deleteBook(String id) = _DeleteBook;
}

@freezed
sealed class LibraryState with _$LibraryState {
  const factory LibraryState.loading() = LibraryLoading;
  const factory LibraryState.loaded(List<RecipeBookEntity> books) = LibraryLoaded;
  const factory LibraryState.errorMessage(String error) = LibraryError;
}

class LibraryBloc extends Bloc<LibraryEvent, LibraryState> {
  final GetBooksUseCase getBooksUseCase;
  final SaveBookUseCase saveBookUseCase;
  final DeleteBookUseCase deleteBookUseCase;
  static const _uuid = Uuid();

  LibraryBloc({
    required this.getBooksUseCase,
    required this.saveBookUseCase,
    required this.deleteBookUseCase,
  }) : super(const LibraryState.loading()) {
    on<_Init>(_init);
    on<_CreateBook>(_createBook);
    on<_DeleteBook>(_deleteBook);
    add(const LibraryEvent.init());
  }

  factory LibraryBloc.fromContext(BuildContext context) {
    return LibraryBloc(
      getBooksUseCase: GetBooksUseCase(context.read()),
      saveBookUseCase: SaveBookUseCase(context.read()),
      deleteBookUseCase: DeleteBookUseCase(context.read()),
    );
  }

  Future<void> _emitBooks(Emitter<LibraryState> emit, [Future<void> Function()? action]) async {
    try {
      await action?.call();
      emit(.loaded(await getBooksUseCase()));
    } catch (e) {
      debugPrint('Library error: $e');
      emit(.errorMessage(e.toString()));
    }
  }

  Future<void> _init(_Init event, Emitter<LibraryState> emit) => _emitBooks(emit);

  Future<void> _createBook(_CreateBook event, Emitter<LibraryState> emit) {
    return _emitBooks(emit, () {
      return saveBookUseCase(
        RecipeBookEntity(
          id: _uuid.v4(),
          title: event.title,
          recipeRefs: const [],
          createdAt: DateTime.now(),
        ),
      );
    });
  }

  Future<void> _deleteBook(_DeleteBook event, Emitter<LibraryState> emit) {
    return _emitBooks(emit, () => deleteBookUseCase(event.id));
  }
}
