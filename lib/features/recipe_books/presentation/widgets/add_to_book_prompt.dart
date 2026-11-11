import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/features/feature_gate.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../my_recipes/data/datasources/recipes_ui_store.dart';
import '../../domain/entities/recipe_book_entity.dart';
import '../../domain/repositories/recipe_books_repository.dart';
import '../../domain/usecases/get_books_usecase.dart';
import '../../../../core/utils/undoable_removals.dart';
import '../bloc/book_viewer_bloc.dart';
import '../bloc/library_bloc.dart';

/// Right after a new recipe is saved: "add it to a book?", with the books
/// it can go into. A tap on one adds it there; "not now" (or a swipe down)
/// leaves it in My Recipes only. Says nothing when there is no book to
/// offer, or when the console switched the prompt or the books off.
///
/// Returns once the sheet is closed and a chosen add has landed, so the
/// caller can close its own screen afterwards.
Future<void> offerAddToBook(BuildContext context, String recipeId) async {
  if (!FeaturesFlags.saveToBookPrompt.isEnabled ||
      !FeaturesFlags.books.isEnabled) {
    return;
  }
  await _pickBookAndAdd(context, recipeId, sayWhenNone: false);
}

/// The same book picker on demand — the recipe card's quick menu — without
/// the post-save prompt's own console switch. The books flag still decides:
/// a gated or hidden books feature is explained, as any gated tap is. Unlike
/// the prompt, says so when there is no book to offer.
Future<void> showAddToBookPicker(BuildContext context, String recipeId) async {
  if (!guardFeature(context, FeaturesFlags.books)) return;
  await _pickBookAndAdd(context, recipeId, sayWhenNone: true);
}

Future<void> _pickBookAndAdd(
  BuildContext context,
  String recipeId, {
  required bool sayWhenNone,
}) async {
  final remember = FeaturesFlags.rememberLastChoices.isEnabled;
  List<RecipeBookEntity> books;
  try {
    // Every book the library shows — one deleted a moment ago and still in
    // its undo window is not. The ones the recipe can't go into stay on the
    // list too, marked: a book missing from the picker read as a bug.
    books = [
      for (final book in await GetBooksUseCase(
        context.read<RecipeBooksRepository>(),
      )())
        if (!UndoableRemovals.instance.isPending(
          LibraryBloc.removalKey(book.id),
        ))
          book,
    ];
  } catch (e) {
    debugPrint('Books for the add-to-book prompt failed: $e');
    return;
  }
  bool addable(RecipeBookEntity b) =>
      b.canEdit && !b.recipeRefs.any((r) => r.recipeId == recipeId);
  // The book used last time goes first, marked: adding several recipes to
  // the same book in a row is the common case. Then the others it can go
  // into, then the ones it is already in, then the read-only ones.
  final lastId = remember ? await RecipesUiStore.instance.lastBookId() : null;
  final last = books.where((b) => b.id == lastId && addable(b)).firstOrNull;
  int rank(RecipeBookEntity b) => b.id == last?.id
      ? 0
      : addable(b)
      ? 1
      : b.canEdit
      ? 2
      : 3;
  books = [...books]..sort((a, b) => rank(a).compareTo(rank(b)));
  if (!context.mounted) return;
  // No book at all is worth saying on demand. When every book already has
  // the recipe or is read-only, the list itself says which; after a save,
  // nothing to offer is simply no prompt.
  if (books.isEmpty) {
    if (sayWhenNone) {
      AppDialog.info(message: t.recipe.noBookToAdd).notify(context);
    }
    return;
  }
  if (!sayWhenNone && !books.any(addable)) return;
  final picked = await showModalBottomSheet<RecipeBookEntity>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _AddToBookSheet(
      books: books,
      highlightedId: last?.id,
      recipeId: recipeId,
    ),
  );
  if (picked == null || !context.mounted) return;
  if (remember) unawaited(RecipesUiStore.instance.setLastBookId(picked.id));
  // The book viewer's own edit path: it reads the stored book, appends the
  // recipe at the end and publishes a shared book to its members.
  final bloc = BookViewerBloc.fromContext(context);
  try {
    bloc.add(BookViewerEvent.init(picked.id));
    final opened = await bloc.stream
        .firstWhere((s) => s is! BookViewerLoading)
        .timeout(const Duration(seconds: 15));
    if (opened is! BookViewerLoaded) return;
    bloc.add(BookViewerEvent.addRecipe(recipeId));
    await bloc.stream
        .firstWhere(
          (s) =>
              s is BookViewerLoaded &&
              s.book.recipeRefs.any((r) => r.recipeId == recipeId),
        )
        .timeout(const Duration(seconds: 15));
    if (context.mounted) {
      AppDialog.success(
        message: t.ingestion.addedToBook(book: picked.title),
      ).notify(context);
    }
  } catch (e) {
    debugPrint('Adding the new recipe to a book failed: $e');
  } finally {
    unawaited(bloc.close());
  }
}

class _AddToBookSheet extends StatelessWidget {
  final List<RecipeBookEntity> books;

  /// The book picked last time, drawn first and marked.
  final String? highlightedId;
  final String recipeId;

  const _AddToBookSheet({
    required this.books,
    required this.recipeId,
    this.highlightedId,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.marginMobile,
            AppSpacing.md,
            AppSpacing.marginMobile,
            AppSpacing.sm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(t.ingestion.addToBookTitle, style: AppTextStyles.headlineMd),
              const SizedBox(height: AppSpacing.sm),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final book in books)
                      if (!book.canEdit ||
                          book.recipeRefs.any((r) => r.recipeId == recipeId))
                        ListTile(
                          enabled: false,
                          contentPadding: const EdgeInsetsDirectional.symmetric(
                            horizontal: AppSpacing.sm,
                          ),
                          leading: Icon(
                            book.canEdit
                                ? Icons.check_circle_rounded
                                : Icons.lock_outline_rounded,
                            color: AppColors.onSurfaceVariant,
                          ),
                          title: Text(
                            book.title,
                            style: AppTextStyles.bodyMd,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            book.canEdit
                                ? t.recipe.alreadyInBook
                                : t.recipe.viewOnlyBook,
                            style: AppTextStyles.labelSm.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        )
                      else
                        ListTile(
                          contentPadding: const EdgeInsetsDirectional.symmetric(
                            horizontal: AppSpacing.sm,
                          ),
                          tileColor: book.id == highlightedId
                              ? AppColors.primaryContainer.withValues(
                                  alpha: 0.35,
                                )
                              : null,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.std),
                          ),
                          leading: Icon(
                            book.id == highlightedId
                                ? Icons.history_rounded
                                : Icons.menu_book_rounded,
                            color: AppColors.primary,
                          ),
                          title: Text(
                            book.title,
                            style: AppTextStyles.bodyMd,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: book.id == highlightedId
                              ? Text(
                                  t.recipe.lastUsedBook,
                                  style: AppTextStyles.labelSm.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                )
                              : null,
                          trailing: Icon(
                            Icons.add_rounded,
                            color: AppColors.onSurfaceVariant,
                          ),
                          onTap: () => Navigator.of(context).pop(book),
                        ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(t.ingestion.addToBookSkip),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
