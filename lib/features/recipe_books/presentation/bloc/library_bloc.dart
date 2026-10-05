import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/translation/content_changes.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/hive/user_scope.dart';
import '../../../../core/services/image_storage_service.dart';
import '../../../../core/sync/recipe_image_store.dart';
import '../../../collab_containers/domain/container_sharing_service.dart';
import '../../domain/entities/book_spine.dart';
import '../../domain/entities/recipe_book_entity.dart';
import '../../domain/usecases/delete_book_usecase.dart';
import '../../domain/usecases/get_books_usecase.dart';
import '../../domain/usecases/save_book_usecase.dart';
import '../../domain/usecases/watch_books_usecase.dart';

part 'library_bloc.freezed.dart';

@freezed
sealed class LibraryEvent with _$LibraryEvent {
  const factory LibraryEvent.init() = _Init;

  /// [id] lets the caller know the new book's id up front — the shelf opens
  /// it as soon as it exists — instead of guessing which one it is.
  const factory LibraryEvent.createBook(
    String title, {
    String? id,
    BookSpine? spine,
  }) = _CreateBook;
  const factory LibraryEvent.deleteBook(String id) = _DeleteBook;
  const factory LibraryEvent.setCoverImage(String id, String? fileName) =
      _SetCoverImage;
  const factory LibraryEvent.renameBook(String id, String title) = _RenameBook;
  const factory LibraryEvent.setSpine(String id, BookSpine spine) = _SetSpine;

  /// The books box changed — from this bloc or from anywhere else.
  const factory LibraryEvent.booksChanged(List<RecipeBookEntity> books) =
      _BooksChanged;
}

@freezed
sealed class LibraryState with _$LibraryState {
  const factory LibraryState.loading() = LibraryLoading;
  const factory LibraryState.loaded(List<RecipeBookEntity> books) =
      LibraryLoaded;
  const factory LibraryState.errorMessage(String error) = LibraryError;
}

class LibraryBloc extends Bloc<LibraryEvent, LibraryState> {
  StreamSubscription<void>? _contentChanges;
  StreamSubscription<List<RecipeBookEntity>>? _books;

  final GetBooksUseCase getBooksUseCase;
  final SaveBookUseCase saveBookUseCase;
  final DeleteBookUseCase deleteBookUseCase;

  /// The shelf as the box has it. Null in tests without a live box; the
  /// shelf then only changes through this bloc's own events.
  final WatchBooksUseCase? watchBooksUseCase;

  /// Carries a change to a shared book across accounts. Null in tests.
  final ContainerSharingService? sharing;
  static const _uuid = Uuid();

  LibraryBloc({
    required this.getBooksUseCase,
    required this.saveBookUseCase,
    required this.deleteBookUseCase,
    this.watchBooksUseCase,
    this.sharing,
  }) : super(const LibraryState.loading()) {
    on<_Init>(_init);
    // A language switch rewrites every record at once; show it.
    _contentChanges = ContentChanges.instance.stream.listen(
      (_) => add(const _Init()),
    );
    on<_CreateBook>(_createBook);
    on<_DeleteBook>(_deleteBook);
    on<_SetCoverImage>(_setCoverImage);
    on<_RenameBook>(_renameBook);
    on<_SetSpine>(_setSpine);
    on<_BooksChanged>(_booksChanged);
    add(const LibraryEvent.init());
    // A book accepted from an invite, or rewritten by a co-editor's change
    // pulled on resume, is written to the box by code that never touches
    // this bloc. The tab lives in an IndexedStack and would otherwise keep
    // showing the shelf as it was when the app started.
    _books = watchBooksUseCase?.call().listen(
      (books) => add(LibraryEvent.booksChanged(books)),
      onError: (Object e) => debugPrint('Books stream failed: $e'),
    );
  }

  factory LibraryBloc.fromContext(BuildContext context) {
    return LibraryBloc(
      getBooksUseCase: GetBooksUseCase(context.read()),
      saveBookUseCase: SaveBookUseCase(context.read()),
      deleteBookUseCase: DeleteBookUseCase(context.read()),
      watchBooksUseCase: WatchBooksUseCase(context.read()),
      sharing: context.read(),
    );
  }

  void _booksChanged(_BooksChanged event, Emitter<LibraryState> emit) {
    // The first read is still on its way: it will show the same list.
    if (state is LibraryLoading) return;
    emit(.loaded(event.books));
  }

  /// Saves, then — for a shared book — publishes. A read-only copy is left
  /// alone: the screen hides the actions, and this is the backstop.
  Future<void> _saveAndPublish(RecipeBookEntity book) async {
    if (!book.canEdit) return;
    await saveBookUseCase(book);
    final uid = UserScope().uid;
    if (book.isShared && uid != null) {
      await sharing?.books.publish(book, uid: uid);
    }
  }

  Future<void> _emitBooks(
    Emitter<LibraryState> emit, [
    Future<void> Function()? action,
  ]) async {
    try {
      await action?.call();
      emit(.loaded(await getBooksUseCase()));
    } catch (e) {
      debugPrint('Library error: $e');
      emit(.errorMessage(e.toString()));
    }
  }

  Future<void> _init(_Init event, Emitter<LibraryState> emit) =>
      _emitBooks(emit);

  Future<void> _createBook(_CreateBook event, Emitter<LibraryState> emit) {
    return _emitBooks(emit, () {
      return saveBookUseCase(
        RecipeBookEntity(
          id: event.id ?? _uuid.v4(),
          title: event.title,
          recipeRefs: const [],
          spine: event.spine,
          createdAt: DateTime.now(),
        ),
      );
    });
  }

  /// The owner takes the shared document down with it; a member only leaves.
  Future<void> _deleteBook(_DeleteBook event, Emitter<LibraryState> emit) {
    return _emitBooks(emit, () async {
      final current = state;
      final book = current is LibraryLoaded
          ? current.books.where((b) => b.id == event.id).firstOrNull
          : null;
      final uid = UserScope().uid;
      if (book != null && book.isShared && uid != null) {
        await sharing?.books.retire(book, uid: uid);
      }
      await deleteBookUseCase(event.id);
    });
  }

  Future<void> _renameBook(_RenameBook event, Emitter<LibraryState> emit) {
    return _emitBooks(emit, () async {
      final current = state;
      if (current is! LibraryLoaded) return;
      final book = current.books.where((b) => b.id == event.id).firstOrNull;
      if (book == null) return;
      await _saveAndPublish(book.copyWith(title: event.title));
    });
  }

  Future<void> _setSpine(_SetSpine event, Emitter<LibraryState> emit) {
    return _emitBooks(emit, () async {
      final current = state;
      if (current is! LibraryLoaded) return;
      final book = current.books.where((b) => b.id == event.id).firstOrNull;
      if (book == null) return;
      await _saveAndPublish(book.copyWith(spine: event.spine));
    });
  }

  /// Swapping or clearing a cover deletes the previous file so removed photos
  /// don't pile up in the app's image directory.
  Future<void> _setCoverImage(
    _SetCoverImage event,
    Emitter<LibraryState> emit,
  ) {
    return _emitBooks(emit, () async {
      final current = state;
      if (current is! LibraryLoaded) return;
      final book = current.books.where((b) => b.id == event.id).firstOrNull;
      if (book == null || !book.canEdit) return;

      final previous = book.coverImageFileName;
      if (previous != null && previous != event.fileName) {
        await ImageStorageService().delete(previous);
        // A shared book's members still point at the uploaded cover; it stays.
        if (!book.isShared) {
          unawaited(
            RecipeImageStore().remove(
              book.coverImageStoragePath,
              uid: UserScope().uid,
            ),
          );
        }
      }
      final updated = book.copyWith(
        coverImageFileName: event.fileName,
        removeCoverImage: event.fileName == null,
      );
      await saveBookUseCase(updated);
      final uid = UserScope().uid;
      if (book.isShared && uid != null) {
        // The cover has to travel before the document says where it is.
        final stored = await getBooksUseCase().then(
          (all) => all.where((b) => b.id == book.id).firstOrNull,
        );
        await sharing?.books.publish(stored ?? updated, uid: uid);
      }
    });
  }

  @override
  Future<void> close() async {
    await _contentChanges?.cancel();
    await _books?.cancel();
    return super.close();
  }
}
