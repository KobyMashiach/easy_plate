import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';

/// Circular grocery checkbox that springs to 1.1x and fills with Mint Fresh
/// when checked, per the Stitch component spec.
class BouncyCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final double size;

  const BouncyCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: value ? 1.1 : 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.elasticOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: value ? AppColors.secondaryContainer : AppColors.surfaceContainerLowest,
            border: Border.all(
              color: value ? AppColors.secondaryContainer : AppColors.outlineVariant,
              width: 2,
            ),
          ),
          child: value
              ? Icon(
                  Icons.check_rounded,
                  size: size * 0.66,
                  color: AppColors.onSecondaryContainer,
                )
              : null,
        ),
      ),
    );
  }
}
