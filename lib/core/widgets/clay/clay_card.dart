import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
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
  final Color spineColor;
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
    this.spineColor = AppColors.primaryFixed,
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
    final background = widget.color ??
        (widget.isActive ? AppColors.primaryContainer : AppColors.surfaceContainerLowest);

    final card = AnimatedScale(
      scale: _pressed ? 0.98 : 1,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: radius,
          border: widget.isActive
              ? null
              : Border.all(color: AppColors.surfaceContainerHighest),
          boxShadow: widget.isActive ? AppShadows.active : AppShadows.card,
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Stack(
            children: [
              // Top-left highlight standing in for the inset bevel glow, which
              // Flutter's BoxShadow cannot express.
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.center,
                      colors: [
                        AppShadows.bevelHighlight.withValues(alpha: widget.isActive ? 0.2 : 0.5),
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
                  child: _ClaySpine(color: widget.spineColor),
                ),
              Padding(
                padding: widget.padding.add(
                  widget.showSpine
                      ? const EdgeInsetsDirectional.only(start: AppSpacing.gutter)
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
