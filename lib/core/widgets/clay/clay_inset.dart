import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';

/// A recessed clay surface — the inverse of [ClayCard]. Used for search fields
/// and hollow tracks, where the element should look pressed into the page.
///
/// The inset shadow of the Stitch spec is approximated with a tinted fill plus
/// a darker top edge, since Flutter shadows only cast outward.
class ClayInset extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  const ClayInset({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.md),
    this.radius = AppRadius.full,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        // Darker at the top edge, lighter toward the bottom, so the surface
        // reads as pressed into the page. A rounded box requires a uniform
        // border, so the recess comes from the gradient rather than per-side
        // border colours.
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.surfaceContainerHighest,
            AppColors.surfaceContainerLow,
          ],
          stops: [0, 0.45],
        ),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.surfaceContainerHighest),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
