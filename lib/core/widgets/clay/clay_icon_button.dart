import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_shadows.dart';

/// A round clay control for a single icon: the bar buttons, the actions on a
/// page header. Ghost by default — faint lavender face, hairline edge, a light lift —
/// and [filled] in primary for the one action a screen leads with.
class ClayIconButton extends StatefulWidget {
  final IconData? icon;
  final VoidCallback? onTap;
  final String? tooltip;
  final bool filled;
  final double size;

  /// Replaces the icon — for the bell that draws its own badge.
  final Widget? child;

  const ClayIconButton({
    super.key,
    this.icon,
    this.onTap,
    this.tooltip,
    this.filled = false,
    this.size = 40,
    this.child,
  }) : assert(icon != null || child != null, 'an icon or a child');

  @override
  State<ClayIconButton> createState() => _ClayIconButtonState();
}

class _ClayIconButtonState extends State<ClayIconButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final foreground = widget.filled
        ? AppColors.onPrimary
        : enabled
        ? AppColors.primary
        : AppColors.outlineVariant;

    Widget button = AnimatedScale(
      scale: _pressed ? 0.92 : 1,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      child: Container(
        width: widget.size,
        height: widget.size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: widget.filled
              ? AppColors.primary
              : AppColors.surfaceContainerLow,
          shape: BoxShape.circle,
          border: widget.filled
              ? null
              : Border.all(color: AppColors.surfaceContainerHighest),
          boxShadow: widget.filled ? AppShadows.button : AppShadows.control,
        ),
        child:
            widget.child ??
            Icon(widget.icon, size: widget.size * 0.55, color: foreground),
      ),
    );

    if (widget.tooltip case final tooltip?) {
      button = Tooltip(message: tooltip, child: button);
    }

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      behavior: HitTestBehavior.opaque,
      child: button,
    );
  }
}
