import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../constants/app_text_styles.dart';

/// The "Add" affordance from the Stitch meal grid: a dashed lavender outline
/// around a soft tinted panel, with a clay pill icon that rotates on press.
class ClayDashedCard extends StatelessWidget {
  final String label;
  final String? description;
  final IconData icon;
  final VoidCallback onTap;

  const ClayDashedCard({
    super.key,
    required this.label,
    required this.onTap,
    this.description,
    this.icon = Icons.add_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: AppColors.primary.withValues(alpha: 0.3),
          radius: AppRadius.std,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(AppRadius.std),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 28, color: AppColors.onPrimary),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                label,
                style: AppTextStyles.bodyLg.copyWith(color: AppColors.primary),
              ),
              if (description != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  description!,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.labelMd.copyWith(color: AppColors.outline),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;

  const _DashedBorderPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
      );

    const dash = 8.0;
    const gap = 6.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, math.min(distance + dash, metric.length)),
          paint,
        );
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
