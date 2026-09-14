import 'package:flutter/material.dart';

import '../../../../core/utils/i18n/strings.g.dart';
import '../../../my_recipes/domain/entities/recipe_entity.dart';
import '../../../recipe_books/domain/entities/recipe_book_entity.dart';
import '../../../recipe_books/presentation/widgets/open_book_shell.dart';
import '../../../recipe_books/presentation/widgets/quick_jump_capsule.dart';
import '../../../recipe_books/presentation/widgets/recipe_book_page.dart';
import '../../../recipe_books/presentation/widgets/table_of_contents_page.dart';

/// A sample book opened exactly the way a real one is — the same shell, page
/// stock, contents page, recipe pages and page turn — but fed from memory.
/// Nothing can be added, reordered or given a cover here: it is for looking
/// at.
class DemoBookViewerPage extends StatelessWidget {
  final RecipeBookEntity book;
  final List<RecipeEntity> recipes;

  const DemoBookViewerPage({super.key, required this.book, required this.recipes});

  @override
  Widget build(BuildContext context) {
    return OpenBookShell(
      pages: (bookNav) => [
        TableOfContentsPage(
          bookTitle: book.title,
          recipes: recipes,
          onSelectRecipe: (index) => bookNav.goTo(index + 1),
        ),
        for (var i = 0; i < recipes.length; i++)
          RecipeBookPage(recipe: recipes[i], pageNumber: i + 2),
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
      ],
    );
  }
}
