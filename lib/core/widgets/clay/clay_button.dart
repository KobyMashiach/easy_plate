import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_shadows.dart';
import '../../constants/app_spacing.dart';
import '../../constants/app_text_styles.dart';

/// Pill-shaped primary action with the design system's 3D extrusion: a darker
/// slab sits under the face, and pressing sinks the face onto it.
class ClayButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool expanded;

  const ClayButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.expanded = false,
  });

  @override
  State<ClayButton> createState() => _ClayButtonState();
}

class _ClayButtonState extends State<ClayButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final sunk = _pressed || !enabled;

    return GestureDetector(
      onTap: widget.onPressed,
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppShadows.buttonThickness),
        child: Stack(
          children: [
            // The extrusion slab, revealed under the face at rest.
            const Positioned.fill(
              top: AppShadows.buttonThickness,
              child: DecoratedBox(
                decoration: ShapeDecoration(
                  color: AppColors.onPrimaryFixedVariant,
                  shape: StadiumBorder(),
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOut,
              margin: EdgeInsets.only(top: sunk ? AppShadows.buttonThickness : 0),
              width: widget.expanded ? double.infinity : null,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.gutter,
              ),
              decoration: ShapeDecoration(
                color: enabled ? AppColors.primary : AppColors.outlineVariant,
                shape: const StadiumBorder(),
                shadows: sunk ? null : AppShadows.button,
              ),
              child: Row(
                mainAxisSize: widget.expanded ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, size: 20, color: AppColors.onPrimary),
                    const SizedBox(width: AppSpacing.base),
                  ],
                  Text(
                    widget.label,
                    style: AppTextStyles.labelMd.copyWith(color: AppColors.onPrimary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
