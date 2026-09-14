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

  /// Error colours for an action that removes something — the confirm of a
  /// delete dialog — so the button itself says what it is about to do.
  final bool destructive;

  const ClayButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.expanded = false,
    this.destructive = false,
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
    final face = widget.destructive ? AppColors.error : AppColors.primary;
    final slab = widget.destructive ? AppColors.onErrorContainer : AppColors.onPrimaryFixedVariant;

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
            Positioned.fill(
              top: AppShadows.buttonThickness,
              child: DecoratedBox(
                decoration: ShapeDecoration(color: slab, shape: const StadiumBorder()),
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
                color: enabled ? face : AppColors.outlineVariant,
                shape: const StadiumBorder(),
                shadows: sunk
                    ? null
                    : [
                        BoxShadow(
                          color: face.withValues(alpha: 0.25),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
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
