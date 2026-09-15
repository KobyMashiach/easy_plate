import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../../../core/widgets/image_source_sheet.dart';
import '../../../my_recipes/presentation/widgets/recipe_picker_sheet.dart';
import '../bloc/book_viewer_bloc.dart';
import '../widgets/open_book_shell.dart';
import '../widgets/quick_jump_capsule.dart';
import '../widgets/quick_nav_sheet.dart';
import '../widgets/recipe_book_page.dart';
import '../widgets/table_of_contents_page.dart';

class BookViewerPage extends StatelessWidget {
  final String bookId;

  const BookViewerPage({super.key, required this.bookId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => BookViewerBloc.fromContext(context)..add(.init(bookId)),
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
          BookViewerLoaded(book: final book, recipes: final recipes) => OpenBookShell(
            // Everything that can change on a page — including the cover
            // photo, which leaves the count untouched.
            bookKey: ValueKey('${recipes.length}|${book.coverImageFileName}'),
            pages: (bookNav) => [
              TableOfContentsPage(
                bookTitle: book.title,
                coverImageFileName: book.coverImageFileName,
                coverImageRemotePath: book.coverImageStoragePath,
                onTapCover: () async {
                  final bloc = context.read<BookViewerBloc>();
                  final result = await showImageSourceSheet(
                    context,
                    hasImage: book.coverImageFileName != null,
                  );
                  if (result == null) return;
                  bloc.add(.setCoverImage(result.fileName));
                },
                recipes: recipes,
                onSelectRecipe: (index) => bookNav.goTo(index + 1),
              ),
              ...recipes.asMap().entries.map(
                (entry) => RecipeBookPage(recipe: entry.value, pageNumber: entry.key + 2),
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
              QuickJumpAction(
                icon: Icons.add_rounded,
                label: t.recipe.addToBook,
                onTap: () {
                  // Multi-select: the sheet stays open so several recipes can
                  // be added in one visit, and tapping an already-added
                  // recipe removes it again.
                  final bloc = context.read<BookViewerBloc>();
                  showRecipePickerSheet(
                    context,
                    selectedIds: book.recipeRefs.map((r) => r.recipeId).toSet(),
                    onToggle: (recipe, selected) => bloc.add(
                      selected
                          ? BookViewerEvent.addRecipe(recipe.id)
                          : BookViewerEvent.removeRecipe(recipe.id),
                    ),
                  );
                },
              ),
              QuickJumpAction(
                icon: Icons.grid_view_rounded,
                label: t.books.quickNav,
                onTap: () async {
                  final bloc = context.read<BookViewerBloc>();
                  final index = await showQuickNavSheet(
                    context,
                    recipes,
                    onReorder: (oldIndex, newIndex) =>
                        bloc.add(.reorderRecipes(oldIndex, newIndex)),
                  );
                  if (index != null) await bookNav.goTo(index + 1);
                },
              ),
            ],
          ),
        };
      },
    );
  }
}
