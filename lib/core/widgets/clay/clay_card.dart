import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_motion.dart';
import '../../constants/app_shadows.dart';
import '../../constants/app_spacing.dart';

/// The core surface of the design system: a white, inflated "clay" panel that
/// floats on the lavender background.
///
/// [showSpine] draws the vertical gradient edge that makes recipe and grocery
/// cards read as physical books. [onTap] adds the tactile 1.02x press scale.
class ClayCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool showSpine;

  /// Null reads as the theme's primaryFixed.
  final Color? spineColor;
  final bool isActive;
  final Color? color;

  const ClayCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.gutter),
    this.radius = AppRadius.std,
    this.onTap,
    this.onLongPress,
    this.showSpine = false,
    this.spineColor,
    this.isActive = false,
    this.color,
  });

  @override
  State<ClayCard> createState() => _ClayCardState();
}

class _ClayCardState extends State<ClayCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(widget.radius);
    final background =
        widget.color ??
        (widget.isActive
            ? AppColors.primaryContainer
            : AppColors.surfaceContainerLowest);

    // Continuous corners — the curvature eases into the straight edge the
    // way an iOS card's does, with no visible point where the arc begins —
    // and a hairline edge rather than a full pixel.
    final shape = RoundedSuperellipseBorder(
      borderRadius: radius,
      side: widget.isActive
          ? BorderSide.none
          : BorderSide(color: AppColors.surfaceContainerHighest, width: 0.5),
    );

    final card = AnimatedScale(
      scale: _pressed ? 0.98 : 1,
      duration: AppMotion.press,
      curve: AppMotion.easeOut,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: background,
          shape: shape,
          shadows: widget.isActive ? AppShadows.active : AppShadows.card,
        ),
        child: ClipRSuperellipse(
          borderRadius: radius,
          child: Stack(
            children: [
              // Top-left highlight standing in for the inset bevel glow, which
              // Flutter's BoxShadow cannot express.
              Positioned.fill(
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    shape: RoundedSuperellipseBorder(borderRadius: radius),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.center,
                      colors: [
                        AppShadows.bevelHighlight.withValues(
                          alpha:
                              (widget.isActive ? 0.2 : 0.5) *
                              AppShadows.bevelStrength,
                        ),
                        // Fade to transparent *white*: fading to
                        // Colors.transparent (transparent black) would tint
                        // the midpoint grey.
                        AppShadows.bevelHighlight.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
              if (widget.showSpine)
                PositionedDirectional(
                  start: 0,
                  top: 0,
                  bottom: 0,
                  child: _ClaySpine(
                    color: widget.spineColor ?? AppColors.primaryFixed,
                  ),
                ),
              Padding(
                padding: widget.padding.add(
                  widget.showSpine
                      ? const EdgeInsetsDirectional.only(
                          start: AppSpacing.gutter,
                        )
                      : EdgeInsets.zero,
                ),
                child: widget.child,
              ),
            ],
          ),
        ),
      ),
    );

    if (widget.onTap == null) return card;

    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      behavior: HitTestBehavior.opaque,
      child: card,
    );
  }
}

class _ClaySpine extends StatelessWidget {
  final Color color;

  const _ClaySpine({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppSpacing.base,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: AlignmentDirectional.centerStart,
            end: AlignmentDirectional.centerEnd,
            colors: [color.withValues(alpha: 0.7), color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}
