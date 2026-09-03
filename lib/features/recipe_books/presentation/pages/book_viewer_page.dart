import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:page_flip/page_flip.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../../../core/widgets/image_source_sheet.dart';
import '../../../my_recipes/presentation/widgets/recipe_picker_sheet.dart';
import '../../../user_profile/domain/usecases/get_user_preferences_usecase.dart';
import '../bloc/book_viewer_bloc.dart';
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

class _BookViewerBody extends StatefulWidget {
  const _BookViewerBody();

  @override
  State<_BookViewerBody> createState() => _BookViewerBodyState();
}

class _BookViewerBodyState extends State<_BookViewerBody> {
  /// How long a single page takes to turn. Every jump is played out as a
  /// sequence of real page turns at this cadence, so it reads as riffling
  /// through the book rather than teleporting.
  static const _pageFlipDuration = Duration(milliseconds: 300);

  /// Vertical room the floating quick-jump capsule occupies, so the book can
  /// be inset by this plus a gap and the two never touch.
  static const _capsuleHeight = 72.0;

  final _controller = PageFlipController();
  int _currentPage = 0;
  bool _soundEnabled = true;
  bool _fastPageTurnEnabled = true;

  /// Incremented on every jump so an in-flight fast-forward abandons itself
  /// when the reader picks a new destination mid-animation.
  int _navigationGeneration = 0;

  /// Resolved by [_onPageFlipped] when the page currently turning has landed.
  Completer<void>? _flipCompleter;

  @override
  void initState() {
    super.initState();
    GetUserPreferencesUseCase(context.read()).call().then((prefs) {
      if (!mounted) return;
      setState(() {
        _soundEnabled = prefs.soundEffectsEnabled;
        _fastPageTurnEnabled = prefs.fastPageTurnEnabled;
      });
    });
  }

  /// Turns a single page and resolves once its flip animation has landed.
  ///
  /// `PageFlipController` returns void rather than the state's future, so the
  /// `onPageFlipped` callback is what tells us the turn finished — that keeps
  /// the run paced by the real animation instead of a guessed delay. The
  /// timeout is a safety net: at either end of the book the flip is refused
  /// and the callback never fires.
  Future<void> _turnOnePage({required bool forward}) {
    final completer = Completer<void>();
    _flipCompleter = completer;
    forward ? _controller.nextPage() : _controller.previousPage();
    return completer.future.timeout(
      _pageFlipDuration * 3,
      // Detach the abandoned completer so a late landing can't resolve the
      // *next* turn early and cascade the run out of step.
      onTimeout: () {
        if (identical(_flipCompleter, completer)) _flipCompleter = null;
      },
    );
  }

  /// Moves to [targetPage].
  ///
  /// With the "fast page-through" preference on, every intervening page is
  /// turned in sequence — one per [_pageFlipDuration] — so a jump from page 2
  /// to page 12 reads as riffling through the book. With it off, the book cuts
  /// straight to the destination.
  Future<void> _navigateTo(int targetPage, {required int pageCount}) async {
    final target = targetPage.clamp(0, pageCount - 1);
    final distance = target - _currentPage;
    if (distance == 0) return;

    final generation = ++_navigationGeneration;

    if (!_fastPageTurnEnabled) {
      // goToPage skips the animation and, unlike a real turn, never reports
      // back through onPageFlipped — so the current page is tracked here.
      _controller.goToPage(target);
      setState(() => _currentPage = target);
      return;
    }

    final forward = distance > 0;
    for (var i = 0; i < distance.abs(); i++) {
      // A newer jump (or a disposed viewer) retires this run mid-flight.
      if (!mounted || generation != _navigationGeneration) return;
      await _turnOnePage(forward: forward);
    }
  }

  void _onPageFlipped(int page) {
    setState(() => _currentPage = page);
    if (_soundEnabled) SystemSound.play(SystemSoundType.click);
    // Releases the fast-forward loop to start the next turn.
    if (_flipCompleter?.isCompleted == false) _flipCompleter!.complete();
    _flipCompleter = null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookViewerBloc, BookViewerState>(
      builder: (context, state) {
        return switch (state) {
          BookViewerLoading() => const Scaffold(
            backgroundColor: AppColors.surfaceContainerLow,
            body: Center(child: CircularProgressIndicator()),
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
          BookViewerLoaded(book: final book, recipes: final recipes) => Scaffold(
            backgroundColor: AppColors.surfaceContainerLow,
            body: DecoratedBox(
              // Soft lavender environment so the book reads as an object
              // resting on a surface, per the Stitch index screen.
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.surfaceContainer, AppColors.surfaceDim],
                ),
              ),
              child: SafeArea(
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.gutter,
                        _capsuleHeight + AppSpacing.base,
                        AppSpacing.gutter,
                        AppSpacing.gutter,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.std),
                        child: PageFlipWidget(
                          // PageFlipWidget snapshots its children in initState
                          // and ignores later updates, so the key has to cover
                          // everything that can change on a page — including
                          // the cover photo, which leaves the count untouched.
                          key: ValueKey('${recipes.length}|${book.coverImageFileName}'),
                          controller: _controller,
                          duration: _pageFlipDuration,
                          backgroundColor: AppColors.surfaceBright,
                          isRightSwipe: true,
                          onPageFlipped: _onPageFlipped,
                          children: [
                            TableOfContentsPage(
                              bookTitle: book.title,
                              coverImageFileName: book.coverImageFileName,
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
                              onSelectRecipe: (index) => _navigateTo(
                                index + 1,
                                pageCount: recipes.length + 1,
                              ),
                            ),
                            ...recipes.asMap().entries.map(
                              (entry) => RecipeBookPage(
                                recipe: entry.value,
                                pageNumber: entry.key + 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.sm),
                        child: QuickJumpCapsule(
                          actions: [
                            QuickJumpAction(
                              icon: Icons.arrow_back_rounded,
                              label: t.common.back,
                              onTap: () => Navigator.of(context).maybePop(),
                            ),
                            QuickJumpAction(
                              icon: Icons.auto_stories_rounded,
                              label: t.books.tableOfContents,
                              onTap: () => _navigateTo(
                                0,
                                pageCount: recipes.length + 1,
                              ),
                            ),
                            QuickJumpAction(
                              icon: Icons.add_rounded,
                              label: t.recipe.addToBook,
                              onTap: () {
                                // Multi-select: the sheet stays open so several
                                // recipes can be added in one visit, and tapping
                                // an already-added recipe removes it again.
                                final bloc = context.read<BookViewerBloc>();
                                showRecipePickerSheet(
                                  context,
                                  selectedIds:
                                      book.recipeRefs.map((r) => r.recipeId).toSet(),
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
                                if (index != null) {
                                  await _navigateTo(
                                    index + 1,
                                    pageCount: recipes.length + 1,
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        };
      },
    );
  }
}
