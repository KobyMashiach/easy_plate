import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../../../core/widgets/image_source_sheet.dart';
import '../../../../core/widgets/ai_cover_prompt_sheet.dart';
import '../../../my_recipes/presentation/widgets/recipe_picker_sheet.dart';
import '../bloc/book_viewer_bloc.dart';
import '../../../../core/features/features_flags.dart';
import '../widgets/open_book_shell.dart';
import '../widgets/quick_jump_capsule.dart';
import '../widgets/quick_nav_sheet.dart';
import '../widgets/recipe_book_page.dart';
import '../widgets/table_of_contents_page.dart';
import '../../../../core/walkthrough/app_walkthroughs.dart';

class BookViewerPage extends StatelessWidget {
  final String bookId;

  const BookViewerPage({super.key, required this.bookId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          BookViewerBloc.fromContext(context)..add(.init(bookId)),
      child: const _BookViewerBody(),
    );
  }
}

class _BookViewerBody extends StatelessWidget {
  const _BookViewerBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookViewerBloc, BookViewerState>(
      builder: (context, state) {
        return switch (state) {
          BookViewerLoading() => Scaffold(
            backgroundColor: AppColors.surfaceContainerLow,
            body: const Center(child: CircularProgressIndicator()),
          ),
          BookViewerNotFound() => ClayScaffold(
            appBar: ClayTopAppBar(
              title: t.appName,
              leadingIcon: Icons.arrow_back_rounded,
              onLeadingTap: () => Navigator.of(context).maybePop(),
            ),
            body: ClayEmptyState(
              icon: Icons.search_off_rounded,
              message: t.common.error,
            ),
          ),
          BookViewerLoaded(book: final book, recipes: final recipes) =>
            OpenBookShell(
              // Everything that can change on a page: the recipes in their
              // order, their wording (the version moves on an edit) and the
              // cover photo. The flip widget snapshots its pages once, so a
              // reorder with the same count would otherwise show stale pages.
              bookKey: ValueKey(
                '${recipes.map((r) => '${r.id}:${r.contentVersion}').join(',')}'
                '|${book.coverImageFileName}',
              ),
              pages: (bookNav) => [
                TableOfContentsPage(
                  bookTitle: book.title,
                  coverImageFileName: book.coverImageFileName,
                  coverImageRemotePath: book.coverImageStoragePath,
                  onTapCover: !book.canEdit
                      ? null
                      : () async {
                          final bloc = context.read<BookViewerBloc>();
                          final result = await showImageSourceSheet(
                            context,
                            hasImage: book.coverImageFileName != null,
                            aiPromptPicker: (ctx) => showCoverPromptSheet(
                              ctx,
                              bookTitle: book.title,
                            ),
                          );
                          if (result == null || !context.mounted) return;
                          await AppDialog.busyEvent(
                            context,
                            bloc,
                            BookViewerEvent.setCoverImage(result.fileName),
                          );
                        },
                  recipes: recipes,
                  onSelectRecipe: (index) => bookNav.goTo(index + 1),
                ),
                ...recipes.asMap().entries.map(
                  (entry) => RecipeBookPage(
                    recipe: entry.value,
                    pageNumber: entry.key + 2,
                  ),
                ),
              ],
              actions: (bookNav) => [
                QuickJumpAction(
                  icon: Icons.arrow_back_rounded,
                  label: t.common.back,
                  onTap: () => Navigator.of(context).maybePop(),
                ),
                QuickJumpAction(
                  icon: Icons.auto_stories_rounded,
                  label: t.books.tableOfContents,
                  onTap: () => bookNav.goTo(0),
                ),
                if (book.canEdit)
                  QuickJumpAction(
                    icon: Icons.add_rounded,
                    label: t.recipe.addToBook,
                    walkthroughId: WalkthroughIds.bookAddRecipe,
                    onTap: () async {
                      // Multi-select: the sheet stays open so several recipes can
                      // be added in one visit, and tapping an already-added
                      // recipe removes it again.
                      final bloc = context.read<BookViewerBloc>();
                      final before = [
                        for (final ref in book.orderedRefs) ref.recipeId,
                      ];
                      await showRecipePickerSheet(
                        context,
                        selectedIds: before.toSet(),
                        onToggle: (recipe, selected) => bloc.add(
                          selected
                              ? BookViewerEvent.addRecipe(recipe.id)
                              : BookViewerEvent.removeRecipe(recipe.id),
                        ),
                      );
                      if (!FeaturesFlags.undoInsteadOfConfirm.isEnabled) return;
                      // Offered once the sheet is closed, for all that left
                      // in the visit together: inside the sheet a second tap
                      // is already the undo, and a notice there would leave
                      // its ticks out of date.
                      await bloc.settled;
                      final now = bloc.state;
                      if (!context.mounted || now is! BookViewerLoaded) return;
                      final kept = {
                        for (final ref in now.book.recipeRefs) ref.recipeId,
                      };
                      final removed = {
                        for (final id in before)
                          if (!kept.contains(id)) id,
                      };
                      if (removed.isEmpty) return;
                      AppDialog.undo(
                        context,
                        message: t.recipe.removedFromBook,
                        icon: Icons.bookmark_remove_rounded,
                        onUndo: () => bloc.restoreRemoved(
                          before: before,
                          removed: removed,
                        ),
                      );
                    },
                  ),
                QuickJumpAction(
                  icon: Icons.grid_view_rounded,
                  label: t.books.quickNav,
                  onTap: () async {
                    final bloc = context.read<BookViewerBloc>();
                    final recipeId = await showQuickNavSheet(
                      context,
                      recipes,
                      // A read-only copy has no drag handles; the bloc
                      // refuses a reorder too.
                      onReorder: book.canEdit
                          ? (oldIndex, newIndex) =>
                                bloc.add(.reorderRecipes(oldIndex, newIndex))
                          : null,
                    );
                    if (recipeId == null) return;
                    // The page by id in the book as it is once the sheet's
                    // reorders have landed: they moved the indices.
                    await bloc.settled;
                    if (!context.mounted) return;
                    final now = bloc.state;
                    if (now is! BookViewerLoaded) return;
                    final index = now.recipes.indexWhere(
                      (r) => r.id == recipeId,
                    );
                    if (index >= 0) await bookNav.goTo(index + 1);
                  },
                ),
              ],
            ),
        };
      },
    );
  }
}
