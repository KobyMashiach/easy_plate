import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../constants/app_text_styles.dart';

/// Small uppercase pill used for dietary markers, meal slots and timings.
class ClayTag extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color background;
  final Color foreground;

  const ClayTag({
    super.key,
    required this.label,
    this.icon,
    this.background = AppColors.primaryFixed,
    this.foreground = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: AppSpacing.xs,
      ),
      decoration: ShapeDecoration(color: background, shape: const StadiumBorder()),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(label, style: AppTextStyles.labelSm.copyWith(color: foreground)),
        ],
      ),
    );
  }
}
