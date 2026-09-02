import 'dart:ui' show PointMode;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../../my_recipes/domain/entities/recipe_entity.dart';
import 'book_page_surface.dart';

/// The book's opening spread: title, then a contents list with dotted leaders
/// running to each recipe's page number.
class TableOfContentsPage extends StatelessWidget {
  final String bookTitle;
  final String? coverImageFileName;
  final List<RecipeEntity> recipes;
  final ValueChanged<int> onSelectRecipe;

  /// Opens the cover-photo picker. Null hides the edit affordance.
  final VoidCallback? onTapCover;

  const TableOfContentsPage({
    super.key,
    required this.bookTitle,
    required this.recipes,
    required this.onSelectRecipe,
    this.coverImageFileName,
    this.onTapCover,
  });

  @override
  Widget build(BuildContext context) {
    return BookPageSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onTapCover,
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: double.infinity,
              height: 140,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClayImage(
                      fileName: coverImageFileName,
                      radius: AppRadius.md,
                      fallbackIconSize: 56,
                    ),
                  ),
                  if (onTapCover != null)
                    PositionedDirectional(
                      end: AppSpacing.base,
                      bottom: AppSpacing.base,
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.base),
                        decoration: const BoxDecoration(
                          color: AppColors.surfaceContainerLowest,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          coverImageFileName == null
                              ? Icons.add_a_photo_rounded
                              : Icons.edit_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(bookTitle, style: AppTextStyles.headlineLg),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.primaryFixed, width: 2),
              ),
            ),
            child: Text(
              t.books.tableOfContents,
              style: AppTextStyles.headlineMd.copyWith(color: AppColors.primary),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: recipes.isEmpty
                ? Center(
                    child: Text(
                      t.books.emptyBook,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: recipes.length,
                    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) => _ContentsRow(
                      title: recipes[index].title,
                      pageNumber: index + 2,
                      onTap: () => onSelectRecipe(index),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ContentsRow extends StatelessWidget {
  final String title;
  final int pageNumber;
  final VoidCallback onTap;

  const _ContentsRow({
    required this.title,
    required this.pageNumber,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyMd,
              ),
            ),
            const Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: 6),
                child: CustomPaint(size: Size.fromHeight(2), painter: _LeaderPainter()),
              ),
            ),
            Text(
              '$pageNumber',
              style: AppTextStyles.labelMd.copyWith(color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dotted leader running between a contents entry and its page number.
class _LeaderPainter extends CustomPainter {
  const _LeaderPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.outlineVariant
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (var x = 0.0; x < size.width; x += 6) {
      canvas.drawPoints(PointMode.points, [Offset(x, size.height / 2)], paint);
    }
  }

  @override
  bool shouldRepaint(_LeaderPainter oldDelegate) => false;
}
