import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/utils/routing/routing.dart';
import '../../../../core/walkthrough/app_walkthroughs.dart';
import '../../../../core/walkthrough/demo_content.dart';
import '../../../../core/walkthrough/walkthrough.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../../my_recipes/presentation/pages/recipe_details_page.dart';
import '../../../my_recipes/presentation/widgets/recipe_card.dart';
import '../../../recipe_books/presentation/widgets/book_cover_card.dart';
import '../../../recipe_books/presentation/widgets/book_page_surface.dart';
import '../../../recipe_books/presentation/widgets/open_book_shell.dart';
import '../../../recipe_books/presentation/widgets/quick_jump_capsule.dart';
import '../../../recipe_books/presentation/widgets/recipe_book_page.dart';
import '../../../recipe_books/presentation/widgets/table_of_contents_page.dart';
import 'demo_book_viewer_page.dart';

/// The guide, as a book from the library: the same open-book shell, page
/// stock, contents page with dotted leaders, page numbers and page turn as
/// any recipe book. A contents page, two pages of samples drawn with the
/// app's own widgets, then one page per chapter with its steps written out.
/// Reading only — nothing here writes a recipe or a book. Each chapter can
/// also be shown "live": the tour then runs over the real screens.
class TutorialBookPage extends StatelessWidget {
  const TutorialBookPage({super.key});

  /// Page 0 is the contents, 1 and 2 the samples, then the chapters — which
  /// is why a chapter's page is its index plus this.
  static const _firstChapterPage = 3;

  /// The tour's first step brings the app to where it belongs, popping this
  /// book and the support screen it was opened from on the way. When the
  /// tour is over — finished or closed — the reader is put back on the
  /// support screen they started from, rather than left on whichever tab
  /// the last step pointed at.
  void _run(BuildContext context, List<WalkthroughStep> steps) {
    final router = GoRouter.of(context);
    Walkthrough.start(
      context,
      steps,
      onDone: (_) => router.pushNamed(Routing.support),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topics = appWalkthroughTopics();
    final pageCount = _firstChapterPage + topics.length;

    return OpenBookShell(
      // The text follows the locale; a language change redraws the book.
      bookKey: ValueKey('tutorial-${LocaleSettings.currentLocale}'),
      pages: (bookNav) => [
        _ContentsPage(
          topics: topics,
          onOpen: bookNav.goTo,
          onStartFull: () => _run(context, firstRunWalkthrough()),
        ),
        const _DemoRecipesPage(pageNumber: 2),
        const _DemoBooksPage(pageNumber: 3),
        for (var i = 0; i < topics.length; i++)
          _ChapterPage(
            number: i + 1,
            total: topics.length,
            pageNumber: i + _firstChapterPage + 1,
            pageCount: pageCount,
            topic: topics[i],
            onFocused: () => _run(context, topics[i].steps),
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
          icon: Icons.play_arrow_rounded,
          label: t.walkthrough.start,
          onTap: () => _run(context, firstRunWalkthrough()),
        ),
      ],
    );
  }
}

/// The book's opening spread, set like a recipe book's: cover block, title,
/// then the contents with dotted leaders running to each page number.
class _ContentsPage extends StatelessWidget {
  final List<WalkthroughTopic> topics;
  final ValueChanged<int> onOpen;
  final VoidCallback onStartFull;

  const _ContentsPage({
    required this.topics,
    required this.onOpen,
    required this.onStartFull,
  });

  @override
  Widget build(BuildContext context) {
    // One scroll for the whole page, like a book's contents page: a short
    // leaf scrolls the cover away rather than running out of room.
    return BookPageSurface(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const SizedBox(
            width: double.infinity,
            height: 140,
            child: ClayImage(
              fileName: null,
              fallbackIcon: Icons.school_rounded,
              fallbackIconSize: 56,
              radius: AppRadius.md,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(t.walkthrough.bookTitle, style: AppTextStyles.headlineLg),
          const SizedBox(height: AppSpacing.base),
          Text(
            t.walkthrough.bookSubtitle,
            style: AppTextStyles.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.primaryFixed, width: 2),
              ),
            ),
            child: Text(
              t.walkthrough.contents,
              style: AppTextStyles.headlineMd.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          BookContentsRow(
            title: t.walkthrough.demoRecipes,
            pageNumber: 2,
            onTap: () => onOpen(1),
          ),
          const SizedBox(height: AppSpacing.sm),
          BookContentsRow(
            title: t.walkthrough.demoBooks,
            pageNumber: 3,
            onTap: () => onOpen(2),
          ),
          for (var i = 0; i < topics.length; i++) ...[
            const SizedBox(height: AppSpacing.sm),
            BookContentsRow(
              title: topics[i].title,
              pageNumber: i + TutorialBookPage._firstChapterPage + 1,
              onTap: () => onOpen(i + TutorialBookPage._firstChapterPage),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          ClayButton(
            label: t.walkthrough.startFull,
            icon: Icons.play_arrow_rounded,
            expanded: true,
            onPressed: onStartFull,
          ),
        ],
      ),
    );
  }
}

/// The page number a recipe page prints at its foot, here for every page.
class _PageFoot extends StatelessWidget {
  final int pageNumber;

  const _PageFoot({required this.pageNumber});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '$pageNumber',
        style: AppTextStyles.labelSm.copyWith(color: AppColors.outline),
      ),
    );
  }
}

class _ChapterPage extends StatelessWidget {
  final int number;
  final int total;
  final int pageNumber;
  final int pageCount;
  final WalkthroughTopic topic;
  final VoidCallback onFocused;

  const _ChapterPage({
    required this.number,
    required this.total,
    required this.pageNumber,
    required this.pageCount,
    required this.topic,
    required this.onFocused,
  });

  @override
  Widget build(BuildContext context) {
    // The head scrolls with the steps: a short leaf keeps the page number
    // printed at the foot and lets the rest scroll under it.
    return BookPageSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        t.walkthrough.chapter(number: number),
                        style: AppTextStyles.labelSm.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    // The live version of this chapter, kept small and out of the
                    // reading line: the page is the guide, this is the shortcut.
                    TextButton.icon(
                      onPressed: onFocused,
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: AppColors.primary,
                      ),
                      icon: const Icon(
                        Icons.center_focus_strong_rounded,
                        size: 16,
                      ),
                      label: Text(
                        t.walkthrough.focused,
                        style: AppTextStyles.labelSm,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(topic.title, style: AppTextStyles.headlineLgMobile),
                const SizedBox(height: AppSpacing.base),
                Text(
                  topic.summary,
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                BookPageHeading(title: t.walkthrough.stepsTitle),
                const SizedBox(height: AppSpacing.base),
                for (var i = 0; i < topic.steps.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.base,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.primaryFixed,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${i + 1}',
                            style: AppTextStyles.labelSm.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            topic.steps[i].body,
                            style: AppTextStyles.bodyMd,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          _PageFoot(pageNumber: pageNumber),
        ],
      ),
    );
  }
}

/// The sample recipes, on the same cards the recipes tab uses. Opening one
/// shows the real recipe page, read-only. The head scrolls with the cards,
/// so a short leaf never runs out of room for them.
class _DemoRecipesPage extends StatelessWidget {
  final int pageNumber;

  const _DemoRecipesPage({required this.pageNumber});

  @override
  Widget build(BuildContext context) {
    final recipes = DemoContent.recipes();

    return BookPageSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _SampleHeader(
                  title: t.walkthrough.demoRecipes,
                  hint: t.walkthrough.demoRecipesHint,
                ),
                for (final recipe in recipes)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: RecipeCard(
                      recipe: recipe,
                      onTap: () => context.pushNamed(
                        Routing.recipeDetails,
                        extra: RecipeDetailsArgs(
                          recipe: recipe,
                          readOnly: true,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          _PageFoot(pageNumber: pageNumber),
        ],
      ),
    );
  }
}

/// The sample books, on the library's own cover cards. Opening one shows a
/// book the way the library does — contents page, recipe pages, page turn.
class _DemoBooksPage extends StatelessWidget {
  final int pageNumber;

  const _DemoBooksPage({required this.pageNumber});

  @override
  Widget build(BuildContext context) {
    final books = DemoContent.books();

    return BookPageSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _SampleHeader(
                    title: t.walkthrough.demoBooks,
                    hint: t.walkthrough.demoBooksHint,
                  ),
                ),
                SliverGrid.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => DemoBookViewerPage(
                            book: book,
                            recipes: DemoContent.recipesOf(book),
                          ),
                        ),
                      ),
                      // A sample has no options; the press does nothing on
                      // purpose rather than opening a menu it cannot honour.
                      onLongPress: () {},
                    );
                  },
                ),
              ],
            ),
          ),
          _PageFoot(pageNumber: pageNumber),
        ],
      ),
    );
  }
}

class _SampleHeader extends StatelessWidget {
  final String title;
  final String hint;

  const _SampleHeader({required this.title, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(title, style: AppTextStyles.headlineLgMobile)),
            ClayTag(
              label: t.walkthrough.demoOnly,
              icon: Icons.visibility_rounded,
              background: AppColors.surfaceContainerLow,
              foreground: AppColors.tertiary,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.base),
        Text(
          hint,
          style: AppTextStyles.bodyMd.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.gutter),
      ],
    );
  }
}
