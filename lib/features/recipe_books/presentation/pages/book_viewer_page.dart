import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:page_flip/page_flip.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../user_profile/domain/usecases/get_user_preferences_usecase.dart';
import '../../../my_recipes/presentation/widgets/recipe_picker_sheet.dart';
import '../bloc/book_viewer_bloc.dart';
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
  final _controller = PageFlipController();
  int _currentPage = 0;
  bool _soundEnabled = true;

  @override
  void initState() {
    super.initState();
    GetUserPreferencesUseCase(context.read()).call().then((prefs) {
      if (mounted) setState(() => _soundEnabled = prefs.soundEffectsEnabled);
    });
  }

  Future<void> _navigateTo(int targetPage) async {
    final distance = (targetPage - _currentPage).abs();
    if (distance == 0) return;
    if (distance <= 5) {
      // Flip through each intervening page so the jump reads as motion,
      // per spec's "fast-forward flip animation across intervening pages".
      for (var i = 0; i < distance; i++) {
        targetPage > _currentPage ? _controller.nextPage() : _controller.previousPage();
        await Future.delayed(const Duration(milliseconds: 220));
      }
    } else {
      _controller.goToPage(targetPage);
      setState(() => _currentPage = targetPage);
    }
  }

  void _onPageFlipped(int page) {
    setState(() => _currentPage = page);
    if (_soundEnabled) SystemSound.play(SystemSoundType.click);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookViewerBloc, BookViewerState>(
      builder: (context, state) {
        return switch (state) {
          BookViewerLoading() => const Scaffold(body: Center(child: CircularProgressIndicator())),
          BookViewerNotFound() => Scaffold(appBar: AppBar(), body: Center(child: Text(t.common.error))),
          BookViewerLoaded(book: final book, recipes: final recipes) => Scaffold(
              backgroundColor: AppColors.leatherDark,
              body: SafeArea(
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: PageFlipWidget(
                          key: ValueKey(recipes.length),
                          controller: _controller,
                          backgroundColor: AppColors.parchment,
                          isRightSwipe: true,
                          onPageFlipped: _onPageFlipped,
                          children: [
                            TableOfContentsPage(
                              bookTitle: book.title,
                              recipes: recipes,
                              onSelectRecipe: (index) => _navigateTo(index + 1),
                            ),
                            ...recipes.asMap().entries.map(
                                  (entry) => RecipeBookPage(recipe: entry.value, pageNumber: entry.key + 2),
                                ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () => Navigator.of(context).maybePop(),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.add, color: Colors.white),
                            tooltip: t.recipe.addToBook,
                            onPressed: () async {
                              final picked = await showRecipePickerSheet(
                                context,
                                excludeIds: book.recipeRefs.map((r) => r.recipeId).toSet(),
                              );
                              if (picked != null && context.mounted) {
                                context.read<BookViewerBloc>().add(.addRecipe(picked.id));
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.grid_view, color: Colors.white),
                            tooltip: t.books.quickNav,
                            onPressed: () async {
                              final index = await showQuickNavSheet(context, recipes);
                              if (index != null) _navigateTo(index + 1);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        };
      },
    );
  }
}
