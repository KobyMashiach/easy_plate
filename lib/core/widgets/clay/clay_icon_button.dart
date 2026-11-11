import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_motion.dart';
import '../../constants/app_shadows.dart';
import 'min_tap_target.dart';

/// A round clay control for a single icon: the bar buttons, the actions on a
/// page header. Ghost by default — faint lavender face, hairline edge, a light lift —
/// and [filled] in primary for the one action a screen leads with.
class ClayIconButton extends StatefulWidget {
  final IconData? icon;
  final VoidCallback? onTap;
  final String? tooltip;

  /// What a screen reader says for the button when it should differ from
  /// [tooltip], or when a long-press tooltip is not wanted. Every button
  /// that does something needs one of the two: the icon alone is silent.
  final String? semanticLabel;
  final bool filled;
  final double size;

  /// Replaces the icon — for the bell that draws its own badge.
  final Widget? child;

  const ClayIconButton({
    super.key,
    this.icon,
    this.onTap,
    this.tooltip,
    this.semanticLabel,
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
      duration: AppMotion.press,
      curve: AppMotion.easeOut,
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
      // The label below already says it; the tooltip is for sighted
      // long-pressers only, so it is not read twice.
      button = Tooltip(
        message: tooltip,
        excludeFromSemantics: true,
        child: button,
      );
    }

    final label = widget.semanticLabel ?? widget.tooltip;
    final detector = GestureDetector(
      onTap: widget.onTap,
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      behavior: HitTestBehavior.opaque,
      child: button,
    );
    // A decorative medallion (no tap, no label) stays out of the way of a
    // screen reader and of touches meant for what is around it.
    if (!enabled && label == null) return detector;
    // Drawn at [size] (40 by default), touched at 48: see MinTapTarget.
    return MinTapTarget(
      child: Semantics(
        button: true,
        enabled: enabled,
        label: label,
        child: detector,
      ),
    );
  }
}
