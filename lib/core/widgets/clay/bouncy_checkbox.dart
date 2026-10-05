import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_motion.dart';

/// Circular grocery checkbox that springs to 1.1x and fills with Mint Fresh
/// when checked, per the Stitch component spec.
///
/// The spring is a gentle one — a single soft overshoot, not a wobble — and
/// checking something off taps back: the one moment on the list that is a
/// commit, so the one that earns a haptic.
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

  void _toggle() {
    if (!value) HapticFeedback.lightImpact();
    onChanged(!value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggle,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: value ? 1.1 : 1,
        duration: AppMotion.move(context, AppMotion.standard),
        curve: AppMotion.settle,
        child: AnimatedContainer(
          duration: AppMotion.fade(context, AppMotion.quick),
          curve: AppMotion.easeOut,
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: value
                ? AppColors.secondaryContainer
                : AppColors.surfaceContainerLowest,
            border: Border.all(
              color: value
                  ? AppColors.secondaryContainer
                  : AppColors.outlineVariant,
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
