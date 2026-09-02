import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';

/// A single leaf of an open recipe book: the bright page stock plus the inner
/// shadow cast by the binding along the spine edge.
class BookPageSurface extends StatelessWidget {
  final Widget child;

  const BookPageSurface({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surfaceBright,
      child: Stack(
        children: [
          PositionedDirectional(
            start: 0,
            top: 0,
            bottom: 0,
            width: AppSpacing.md,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: AlignmentDirectional.centerStart,
                  end: AlignmentDirectional.centerEnd,
                  colors: [
                    AppColors.onSurface.withValues(alpha: 0.06),
                    AppColors.onSurface.withValues(alpha: 0),
                  ],
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
