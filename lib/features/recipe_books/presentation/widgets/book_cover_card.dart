import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../domain/entities/recipe_book_entity.dart';

/// Spine colours cycle so a shelf of books reads as distinct objects, the way
/// the Stitch library carousel alternates primary / secondary / tertiary.
const _spineColors = [AppColors.primary, AppColors.secondary, AppColors.tertiary];

class BookCoverCard extends StatelessWidget {
  final RecipeBookEntity book;
  final VoidCallback onTap;

  /// Opens the book's options (cover photo, delete).
  final VoidCallback onLongPress;

  const BookCoverCard({
    super.key,
    required this.book,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return ClayBookCover(
      title: book.title,
      eyebrow: t.books.collection,
      meta: t.books.recipesCount(count: book.recipeRefs.length),
      spineColor: _spineColors[book.id.hashCode.abs() % _spineColors.length],
      imageFileName: book.coverImageFileName,
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}
