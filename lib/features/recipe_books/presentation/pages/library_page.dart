import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/account_avatar_button.dart';
import '../../../../core/utils/routing/routing.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../../../core/widgets/error_retry_view.dart';
import '../../../../core/widgets/image_source_sheet.dart';
import '../../domain/entities/recipe_book_entity.dart';
import '../bloc/library_bloc.dart';
import '../widgets/book_cover_card.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LibraryBloc.fromContext(context),
      child: Builder(
        builder: (context) => ClayScaffold(
          appBar: ClayTopAppBar(
            title: t.appName,
            leading: const AccountAvatarButton(),
            trailingIcon: Icons.add_rounded,
            onTrailingTap: () => _showCreateBookDialog(context),
          ),
          body: BlocBuilder<LibraryBloc, LibraryState>(
            builder: (context, state) {
              return switch (state) {
                LibraryLoading() => const Center(child: CircularProgressIndicator()),
                LibraryLoaded(books: final books) => books.isEmpty
                    ? ClayEmptyState(
                        icon: Icons.auto_stories_rounded,
                        message: t.books.emptyLibrary,
                        action: ClayButton(
                          label: t.books.newBook,
                          icon: Icons.add_rounded,
                          onPressed: () => _showCreateBookDialog(context),
                        ),
                      )
                    : CustomScrollView(
                        slivers: [
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.marginMobile,
                              AppSpacing.md,
                              AppSpacing.marginMobile,
                              AppSpacing.lg,
                            ),
                            sliver: SliverToBoxAdapter(
                              child: ClayPageHeader(
                                title: t.books.myLibrary,
                                subtitle: t.books.librarySubtitle,
                              ),
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.marginMobile,
                              0,
                              AppSpacing.marginMobile,
                              ClayNavDock.reservedHeight,
                            ),
                            sliver: SliverGrid.builder(
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: AppSpacing.lg,
                                crossAxisSpacing: AppSpacing.gutter,
                                childAspectRatio: 0.72,
                              ),
                              itemCount: books.length,
                              itemBuilder: (context, index) {
                                final book = books[index];
                                return BookCoverCard(
                                  book: book,
                                  // Reload on return: the cover can be changed
                                  // inside the book, and this page is kept
                                  // alive by the IndexedStack so it would
                                  // otherwise keep showing the old shelf.
                                  onTap: () async {
                                    final bloc = context.read<LibraryBloc>();
                                    await context.pushNamed(
                                      Routing.bookDetails,
                                      extra: book.id,
                                    );
                                    bloc.add(const LibraryEvent.init());
                                  },
                                  onLongPress: () => _showBookOptions(context, book),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                LibraryError(error: final error) => ErrorRetryView(
                    error: error,
                    onRetry: () => context.read<LibraryBloc>().add(const LibraryEvent.init()),
                  ),
              };
            },
          ),
        ),
      ),
    );
  }

  /// Long-pressing a book used to delete it outright, with no label and no
  /// confirmation. It now opens this menu, which is also where the cover photo
  /// is set.
  void _showBookOptions(BuildContext context, RecipeBookEntity book) {
    final bloc = context.read<LibraryBloc>();

    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.marginMobile,
            0,
            AppSpacing.marginMobile,
            AppSpacing.marginMobile,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(book.title, style: AppTextStyles.headlineMd),
              const SizedBox(height: AppSpacing.gutter),
              ClayCard(
                radius: AppRadius.md,
                padding: const EdgeInsets.all(AppSpacing.gutter),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  final result = await showImageSourceSheet(
                    context,
                    hasImage: book.coverImageFileName != null,
                  );
                  if (result == null) return;
                  bloc.add(.setCoverImage(book.id, result.fileName));
                },
                child: Row(
                  children: [
                    const Icon(Icons.image_rounded, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.sm),
                    Text(t.books.coverImage, style: AppTextStyles.bodyMd),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.base),
              ClayCard(
                radius: AppRadius.md,
                padding: const EdgeInsets.all(AppSpacing.gutter),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _showRenameBookDialog(context, bloc, book);
                },
                child: Row(
                  children: [
                    const Icon(Icons.drive_file_rename_outline_rounded,
                        color: AppColors.primary),
                    const SizedBox(width: AppSpacing.sm),
                    Text(t.books.renameBook, style: AppTextStyles.bodyMd),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.base),
              ClayCard(
                radius: AppRadius.md,
                padding: const EdgeInsets.all(AppSpacing.gutter),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  bloc.add(.deleteBook(book.id));
                },
                child: Row(
                  children: [
                    const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      t.common.delete,
                      style: AppTextStyles.bodyMd.copyWith(color: AppColors.error),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRenameBookDialog(
    BuildContext context,
    LibraryBloc bloc,
    RecipeBookEntity book,
  ) {
    final controller = TextEditingController(text: book.title);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.books.renameBook),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: t.books.newBookTitle),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(t.common.cancel),
          ),
          FilledButton(
            onPressed: () {
              final title = controller.text.trim();
              if (title.isNotEmpty) bloc.add(.renameBook(book.id, title));
              Navigator.of(dialogContext).pop();
            },
            child: Text(t.common.save),
          ),
        ],
      ),
    );
  }

  void _showCreateBookDialog(BuildContext context) {
    final bloc = context.read<LibraryBloc>();
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.books.newBook),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: t.books.newBookTitle),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(t.common.cancel),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                bloc.add(.createBook(controller.text.trim()));
              }
              Navigator.of(dialogContext).pop();
            },
            child: Text(t.common.save),
          ),
        ],
      ),
    );
  }
}
