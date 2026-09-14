import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';

/// Which edge of a page the binding is on.
///
/// A page shown on its own is bound on its start edge. On an open spread the
/// page on the start side is bound on its *end* edge — the spine runs down
/// the middle — so the spread tells its start page through this, and the
/// page draws its binding shadow on the right side without being rebuilt any
/// differently.
class BookPageSide extends InheritedWidget {
  final bool spineAtEnd;

  const BookPageSide({super.key, required this.spineAtEnd, required super.child});

  static bool spineAtEndOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<BookPageSide>()?.spineAtEnd ?? false;

  @override
  bool updateShouldNotify(BookPageSide oldWidget) => oldWidget.spineAtEnd != spineAtEnd;
}

/// A single leaf of an open recipe book: the bright page stock plus the inner
/// shadow cast by the binding along the spine edge.
class BookPageSurface extends StatelessWidget {
  final Widget child;

  const BookPageSurface({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final spineAtEnd = BookPageSide.spineAtEndOf(context);
    final shade = [
      AppColors.onSurface.withValues(alpha: 0.06),
      AppColors.onSurface.withValues(alpha: 0),
    ];

    return ColoredBox(
      color: AppColors.surfaceBright,
      child: Stack(
        children: [
          PositionedDirectional(
            start: spineAtEnd ? null : 0,
            end: spineAtEnd ? 0 : null,
            top: 0,
            bottom: 0,
            width: AppSpacing.md,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: AlignmentDirectional.centerStart,
                  end: AlignmentDirectional.centerEnd,
                  colors: spineAtEnd ? shade.reversed.toList() : shade,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.xl,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}
