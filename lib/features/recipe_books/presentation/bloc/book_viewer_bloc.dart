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
  const factory BookViewerEvent.reorderRecipes(int oldIndex, int newIndex) =
      _ReorderRecipes;
  const factory BookViewerEvent.setCoverImage(String? fileName) =
      _SetCoverImage;
}

@freezed
sealed class BookViewerState with _$BookViewerState {
  const factory BookViewerState.loading() = BookViewerLoading;
  const factory BookViewerState.loaded(
    RecipeBookEntity book,
    List<RecipeEntity> recipes,
  ) = BookViewerLoaded;
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
    // Each edit reads the book from state, writes it and emits; two taps in
    // the multi-select picker (or two quick drags) running concurrently
    // would both start from the same book and the second save would
    // overwrite the first. One at a time, in order — across all four
    // kinds, since an add and a remove race exactly like two adds.
    on<_AddRecipe>((e, emit) => _serial(() => _addRecipe(e, emit)));
    on<_RemoveRecipe>((e, emit) => _serial(() => _removeRecipe(e, emit)));
    on<_ReorderRecipes>((e, emit) => _serial(() => _reorderRecipes(e, emit)));
    on<_SetCoverImage>((e, emit) => _serial(() => _setCoverImage(e, emit)));
  }

  /// The one queue every edit waits in: a per-kind transformer only
  /// ordered events of the same kind.
  Future<void> _queue = Future.value();

  /// Completes once every edit queued so far has landed (or failed), so a
  /// caller can read the book in the order those edits leave it.
  Future<void> get settled => _queue;

  Future<void> _serial(Future<void> Function() edit) {
    final run = _queue.then((_) => edit());
    // A failed edit must not wedge the ones behind it.
    _queue = run.catchError((Object _) {});
    return run;
  }

  factory BookViewerBloc.fromContext(BuildContext context) {
    return BookViewerBloc(
      getBookByIdUseCase: GetBookByIdUseCase(
        context.read<RecipeBooksRepository>(),
      ),
      saveBookUseCase: SaveBookUseCase(context.read<RecipeBooksRepository>()),
      recipesRepository: context.read(),
      sharing: context.read(),
    );
  }

  Future<void> _saveAndPublish(RecipeBookEntity book) async {
    await saveBookUseCase(book);
    final uid = UserScope().uid;
    if (book.isShared && uid != null) {
      await _publish(await _readyForSharing(book), uid);
    }
  }

  /// Best effort, as the planner and the grocery list do: the local save
  /// stands. A refused write (this account demoted or removed meanwhile)
  /// used to escape the handler, emit nothing, and hold the busy card up
  /// for its whole 30 s timeout.
  Future<void> _publish(RecipeBookEntity book, String uid) async {
    try {
      await sharing?.books.publish(book, uid: uid);
    } catch (e) {
      debugPrint('Shared book publish failed: $e');
    }
  }

  /// The book with its cover uploaded: the save sends the cover in the
  /// background, and a document published before it lands would name no
  /// cover for good. Waits for that same upload.
  Future<RecipeBookEntity> _readyForSharing(RecipeBookEntity book) =>
      saveBookUseCase.repository.readyForSharing(book);

  /// The book as it is stored now. Every edit starts from it rather than
  /// from the copy on screen, which was read when the viewer opened: the
  /// website, a co-editor's sync or the library's rename may have written
  /// the book since, and the screen's copy written whole would put their
  /// changes back. Null — and the screen says so — when the book was
  /// deleted elsewhere; writing it would bring it back.
  Future<RecipeBookEntity?> _stored(
    BookViewerLoaded current,
    Emitter<BookViewerState> emit,
  ) async {
    final stored = await getBookByIdUseCase(current.book.id);
    if (stored == null) emit(const BookViewerState.notFound());
    return stored;
  }

  Future<void> _loadAndEmit(
    RecipeBookEntity book,
    Emitter<BookViewerState> emit,
  ) async {
    final recipes = <RecipeEntity>[];
    for (final ref in book.orderedRefs) {
      final recipe = await recipesRepository.getRecipeById(ref.recipeId);
      if (recipe != null) recipes.add(recipe);
    }
    emit(.loaded(book, recipes));
  }

  Future<void> _init(_Init event, Emitter<BookViewerState> emit) async {
    try {
      await _open(event, emit);
    } catch (e) {
      // A read that throws (a closed box after sign-out, a corrupt record)
      // used to leave the viewer on its spinner for good.
      debugPrint('Opening book ${event.bookId} failed: $e');
      emit(const BookViewerState.notFound());
    }
  }

  Future<void> _open(_Init event, Emitter<BookViewerState> emit) async {
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

  Future<void> _addRecipe(
    _AddRecipe event,
    Emitter<BookViewerState> emit,
  ) async {
    final current = state;
    if (current is! BookViewerLoaded) return;
    if (!current.book.canEdit) return;
    final book = await _stored(current, emit);
    if (book == null || !book.canEdit) return;
    if (book.recipeRefs.any((r) => r.recipeId == event.recipeId)) {
      return;
    }
    final nextOrder = book.recipeRefs.length;
    final updatedBook = book.copyWith(
      recipeRefs: [
        ...book.recipeRefs,
        BookRecipeRefEntity(recipeId: event.recipeId, order: nextOrder),
      ],
    );
    await _saveAndPublish(updatedBook);
    await _loadAndEmit(updatedBook, emit);
  }

  /// Moves the recipe at [_ReorderRecipes.oldIndex] to
  /// [_ReorderRecipes.newIndex] and renumbers the whole list, so `order` stays
  /// a dense 0..n-1 sequence rather than drifting into gaps.
  Future<void> _reorderRecipes(
    _ReorderRecipes event,
    Emitter<BookViewerState> emit,
  ) async {
    final current = state;
    if (current is! BookViewerLoaded) return;

    if (!current.book.canEdit) return;
    // The indices are positions on screen, which lists only the recipes
    // this device has: a ref to a deleted or not-yet-accepted recipe is not
    // shown, so the move is made on the shown ids and the hidden refs keep
    // their place at the end.
    final shown = [for (final r in current.recipes) r.id];
    if (event.oldIndex < 0 || event.oldIndex >= shown.length) return;
    final newIndex = event.newIndex.clamp(0, shown.length - 1);
    if (newIndex == event.oldIndex) return;

    shown.insert(newIndex, shown.removeAt(event.oldIndex));
    final book = await _stored(current, emit);
    if (book == null || !book.canEdit) return;
    // The move is made on the stored refs: a recipe removed elsewhere
    // meanwhile stays out, one added elsewhere keeps its place at the end.
    final inBook = {for (final ref in book.recipeRefs) ref.recipeId};
    final moved = [
      for (final id in shown)
        if (inBook.contains(id)) id,
    ];
    final visible = moved.toSet();
    final ids = [
      ...moved,
      for (final ref in book.orderedRefs)
        if (!visible.contains(ref.recipeId)) ref.recipeId,
    ];

    final updatedBook = book.copyWith(
      recipeRefs: [
        for (var i = 0; i < ids.length; i++)
          BookRecipeRefEntity(recipeId: ids[i], order: i),
      ],
    );
    await _saveAndPublish(updatedBook);
    await _loadAndEmit(updatedBook, emit);
  }

  /// Replacing or clearing the cover deletes the previous file so removed
  /// photos don't pile up in the app's image directory.
  Future<void> _setCoverImage(
    _SetCoverImage event,
    Emitter<BookViewerState> emit,
  ) async {
    final current = state;
    if (current is! BookViewerLoaded) return;

    if (!current.book.canEdit) return;
    final book = await _stored(current, emit);
    if (book == null || !book.canEdit) return;

    final previous = book.coverImageFileName;
    // Read before the copyWith clears it, so the replaced upload can go too.
    final previousRemote = book.coverImageStoragePath;
    var updatedBook = book.copyWith(
      coverImageFileName: event.fileName,
      removeCoverImage: event.fileName == null,
    );
    await saveBookUseCase(updatedBook);
    if (previous != null && previous != event.fileName) {
      await ImageStorageService().delete(previous);
      // A shared book's members still point at the uploaded cover; it stays.
      if (!book.isShared) {
        unawaited(
          RecipeImageStore().remove(previousRemote, uid: UserScope().uid),
        );
      }
    }
    final uid = UserScope().uid;
    if (updatedBook.isShared && uid != null) {
      // The cover has to travel before the document says where it is.
      updatedBook = await _readyForSharing(updatedBook);
      await _publish(updatedBook, uid);
    }
    await _loadAndEmit(updatedBook, emit);
  }

  Future<void> _removeRecipe(
    _RemoveRecipe event,
    Emitter<BookViewerState> emit,
  ) async {
    final current = state;
    if (current is! BookViewerLoaded || !current.book.canEdit) return;
    final book = await _stored(current, emit);
    if (book == null || !book.canEdit) return;
    final updatedBook = book.copyWith(
      recipeRefs: book.recipeRefs
          .where((r) => r.recipeId != event.recipeId)
          .toList(),
    );
    await _saveAndPublish(updatedBook);
    await _loadAndEmit(updatedBook, emit);
  }
}
