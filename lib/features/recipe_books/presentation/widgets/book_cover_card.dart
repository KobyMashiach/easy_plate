import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../domain/entities/recipe_book_entity.dart';

class BookCoverCard extends StatelessWidget {
  final RecipeBookEntity book;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const BookCoverCard({super.key, required this.book, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      onLongPress: onDelete,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.leather,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: AppColors.leatherDark.withValues(alpha: 0.4), blurRadius: 6, offset: const Offset(0, 3)),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Icon(Icons.menu_book, color: Colors.white70, size: 28),
            const SizedBox(height: 8),
            Text(
              book.title,
              style: AppTextStyles.pageHeading.copyWith(color: Colors.white),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${book.recipeRefs.length}',
              style: AppTextStyles.caption.copyWith(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
