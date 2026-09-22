import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

/// The red counter that sits on the bell: a number in a ringed circle, gone
/// when there is nothing to count. Shared by every control that carries one
/// so they all read the same.
class CountBadge extends StatelessWidget {
  final int count;

  /// Draws the ring in the colour of what the badge overlaps.
  final Color? ringColor;

  const CountBadge({super.key, required this.count, this.ringColor});

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: ringColor ?? AppColors.surfaceContainerLowest,
          width: 2,
        ),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        style: AppTextStyles.labelSm.copyWith(
          color: AppColors.onError,
          fontSize: 10,
          height: 1.2,
        ),
      ),
    );
  }
}

/// [child] with a [CountBadge] pinned to its top trailing corner.
class BadgedBox extends StatelessWidget {
  final Widget child;
  final int count;
  final double top;
  final double end;
  final Color? ringColor;

  const BadgedBox({
    super.key,
    required this.child,
    required this.count,
    this.top = -6,
    this.end = -8,
    this.ringColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (count > 0)
          PositionedDirectional(
            top: top,
            end: end,
            child: CountBadge(count: count, ringColor: ringColor),
          ),
      ],
    );
  }
}
