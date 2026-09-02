import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';

/// Hollow, fully-rounded track with a gradient fill — the "recessed groove"
/// from the Stitch elevation spec.
class ClayProgressBar extends StatelessWidget {
  final double value;
  final double height;

  const ClayProgressBar({super.key, required this.value, this.height = AppSpacing.md});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          // Hollow groove: shaded at the top lip, opening up toward the bottom.
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.surfaceContainerHighest, AppColors.surfaceContainer],
            stops: [0, 0.5],
          ),
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.full),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: FractionallySizedBox(
              widthFactor: value.clamp(0.0, 1.0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryContainer, AppColors.primary],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
