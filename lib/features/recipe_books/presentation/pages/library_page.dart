import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/account_avatar_button.dart';
import '../../../../core/widgets/notification_bell_button.dart';
import '../../../../core/utils/routing/routing.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../../../core/widgets/error_retry_view.dart';
import '../../../../core/widgets/image_source_sheet.dart';
import '../../../../core/widgets/ai_cover_prompt_sheet.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../collab_containers/presentation/widgets/container_share_sheets.dart';
import '../../domain/entities/recipe_book_entity.dart';
import '../widgets/spine_color_picker.dart';
import '../../domain/entities/book_spine.dart';
import '../bloc/library_bloc.dart';
import '../widgets/book_cover_card.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/walkthrough/walkthrough.dart';
import '../../../../core/walkthrough/app_walkthroughs.dart';

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
            actions: const [NotificationBellButton()],
          ),
          body: BlocBuilder<LibraryBloc, LibraryState>(
            builder: (context, state) {
              return switch (state) {
                LibraryLoading() => const Center(
                  child: CircularProgressIndicator(),
                ),
                LibraryLoaded(books: final books) =>
                  books.isEmpty
                      ? ClayEmptyState(
                          icon: Icons.auto_stories_rounded,
                          message: t.books.emptyLibrary,
                          action: ClayButton(
                            label: t.books.newBook,
                            icon: Icons.add_rounded,
                            onPressed: () => _showCreateBookDialog(context),
                          ),
                        )
                      : ClayFloatingHeaderView(
                          title: t.books.myLibrary,
                          subtitle: t.books.librarySubtitle,
                          bottomGap: AppSpacing.lg,
                          trailing: WalkthroughTarget(
                            id: WalkthroughIds.libraryAdd,
                            child: ClayIconButton(
                              icon: Icons.add_rounded,
                              filled: true,
                              size: 48,
                              tooltip: t.books.newBook,
                              onTap: () => _showCreateBookDialog(context),
                            ),
                          ),
                          slivers: [
                            SliverPadding(
                              padding: EdgeInsets.fromLTRB(
                                AppSpacing.marginMobile,
                                0,
                                AppSpacing.marginMobile,
                                ClayNavDock.bottomPadding(context),
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
                                    onLongPress: () =>
                                        _showBookOptions(context, book),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                LibraryError(error: final error) => ErrorRetryView(
                  error: error,
                  onRetry: () => context.read<LibraryBloc>().add(
                    const LibraryEvent.init(),
                  ),
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
        child: SingleChildScrollView(
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
                if (book.isShared) ...[
                  const SizedBox(height: AppSpacing.xs),
                  ClayTag(
                    label: switch (book.collabRole) {
                      CollabRole.owner => t.sharing.ownerTag,
                      CollabRole.editor => t.sharing.editorTag,
                      _ => t.sharing.viewerTag,
                    },
                    icon: Icons.group_rounded,
                    background: AppColors.secondaryContainer,
                    foreground: AppColors.onSecondaryContainer,
                  ),
                ],
                const SizedBox(height: AppSpacing.gutter),
                // Only the owner hands a book on; a member cannot share it further.
                if (book.isMine) ...[
                  ClayCard(
                    radius: AppRadius.md,
                    padding: const EdgeInsets.all(AppSpacing.gutter),
                    onTap: () async {
                      Navigator.of(sheetContext).pop();
                      final sent = await showBookShareSheet(context, book);
                      if (sent == true && context.mounted) {
                        AppDialog.success(
                          message: t.sharing.sent,
                        ).notify(context);
                        // The share tags the book with its collab id.
                        bloc.add(const LibraryEvent.init());
                      }
                    },
                    child: Row(
                      children: [
                        Icon(
                          Icons.person_add_alt_1_rounded,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(t.books.share, style: AppTextStyles.bodyMd),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.base),
                ],
                // A read-only copy: nothing below changes it.
                if (book.canEdit) ...[
                  ClayCard(
                    radius: AppRadius.md,
                    padding: const EdgeInsets.all(AppSpacing.gutter),
                    onTap: () async {
                      Navigator.of(sheetContext).pop();
                      final result = await showImageSourceSheet(
                        context,
                        hasImage: book.coverImageFileName != null,
                        aiPromptPicker: (ctx) =>
                            showCoverPromptSheet(ctx, bookTitle: book.title),
                      );
                      if (result == null) return;
                      bloc.add(.setCoverImage(book.id, result.fileName));
                    },
                    child: Row(
                      children: [
                        Icon(Icons.image_rounded, color: AppColors.primary),
                        const SizedBox(width: AppSpacing.sm),
                        Text(t.books.coverImage, style: AppTextStyles.bodyMd),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.base),
                  ClayCard(
                    radius: AppRadius.md,
                    padding: const EdgeInsets.all(AppSpacing.gutter),
                    onTap: () async {
                      Navigator.of(sheetContext).pop();
                      final spine = await _pickSpine(
                        context,
                        current: book.spine,
                      );
                      if (spine != null) bloc.add(.setSpine(book.id, spine));
                    },
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: book.spine == null
                                ? AppColors.primary
                                : bookSpineColor(book.spine!),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(t.books.spineColor, style: AppTextStyles.bodyMd),
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
                        Icon(
                          Icons.drive_file_rename_outline_rounded,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(t.books.renameBook, style: AppTextStyles.bodyMd),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.base),
                ],
                ClayCard(
                  radius: AppRadius.md,
                  padding: const EdgeInsets.all(AppSpacing.gutter),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    bloc.add(.deleteBook(book.id));
                  },
                  child: Row(
                    children: [
                      Icon(
                        book.isShared && !book.isMine
                            ? Icons.logout_rounded
                            : Icons.delete_outline_rounded,
                        color: AppColors.error,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        // A member does not delete a shared book; they leave it.
                        book.isShared && !book.isMine
                            ? t.sharing.leave
                            : t.common.delete,
                        style: AppTextStyles.bodyMd.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The ten swatches in a dialog. Null when dismissed without confirming;
  /// confirming with nothing new picked returns [current].
  Future<BookSpine?> _pickSpine(
    BuildContext context, {
    required BookSpine? current,
  }) async {
    var picked = current;
    final confirmed = await AppDialog.general(
      title: t.books.spineColor,
      icon: Icons.palette_rounded,
      content: StatefulBuilder(
        builder: (context, setState) => SpineColorPicker(
          selected: picked,
          onSelect: (spine) => setState(() => picked = spine),
        ),
      ),
      confirmLabel: t.common.save,
      cancelLabel: t.common.cancel,
    ).show(context);
    return confirmed == true ? picked : null;
  }

  Future<void> _showRenameBookDialog(
    BuildContext context,
    LibraryBloc bloc,
    RecipeBookEntity book,
  ) async {
    final title = await AppDialog.prompt(
      context,
      title: t.books.renameBook,
      icon: Icons.drive_file_rename_outline_rounded,
      hint: t.books.newBookTitle,
      initial: book.title,
    );
    if (title != null) bloc.add(.renameBook(book.id, title));
  }

  /// A new book opens straight away: naming it is the first step of filling
  /// it, and the shelf is not where that happens. The push waits for the
  /// shelf to carry the book, so the viewer never asks for one not yet saved.
  Future<void> _showCreateBookDialog(BuildContext context) async {
    final bloc = context.read<LibraryBloc>();
    final title = await AppDialog.prompt(
      context,
      title: t.books.newBook,
      icon: Icons.auto_stories_rounded,
      hint: t.books.newBookTitle,
    );
    if (title == null || !context.mounted) return;
    // The spine is chosen right after the name: it is what tells the books
    // apart on the shelf before any cover exists.
    final spine = await _pickSpine(context, current: null);
    if (!context.mounted) return;

    final id = const Uuid().v4();
    bloc.add(.createBook(title, id: id, spine: spine));
    await bloc.stream.firstWhere(
      (state) => state is LibraryLoaded && state.books.any((b) => b.id == id),
    );
    if (!context.mounted) return;
    await context.pushNamed(Routing.bookDetails, extra: id);
    // Same reload as opening from the shelf: the cover may have changed inside.
    bloc.add(const LibraryEvent.init());
  }
}
