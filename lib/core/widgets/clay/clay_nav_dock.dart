import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_motion.dart';
import '../../constants/app_spacing.dart';
import '../../constants/app_text_styles.dart';
import '../../features/features_flags.dart';
import '../../walkthrough/walkthrough_targets.dart';

class ClayNavDestination {
  final IconData icon;
  final String label;

  const ClayNavDestination({required this.icon, required this.label});
}

/// The tab bar, in the manner of iOS 26's Liquid Glass: a translucent
/// capsule floating over the content, the page blurred and a touch more
/// saturated through it, a specular rim catching the light along its edge,
/// and a lozenge of brighter glass that slides under the active tab.
///
/// It follows the theme, as the system bar does: clear light glass with
/// dark ink on the light theme, smoked glass with light ink on the dark one.
class ClayNavDock extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final List<ClayNavDestination> destinations;

  /// The dock's own height (its padding, an icon and a label) plus its bottom
  /// margin and a little air: what a page has to keep clear at the bottom
  /// before the system's own inset is counted.
  static const reservedHeight = 96.0;

  /// A floating button's height plus the gap that keeps it off the last
  /// card, for pages that carry one above the dock.
  static const fabClearance = 56.0 + AppSpacing.md;

  /// Where a button floating above the dock sits: the copilot's pill in the
  /// end corner and a page's own button in the start corner share this
  /// baseline, so the two never stack on each other.
  static double fabBottom(BuildContext context) => _dockPadding(context);

  /// Bottom padding for a page under the dock, so its last item scrolls all
  /// the way out from under it. On Android the dock floats above the gesture
  /// bar (see [MainNavBar]), so that inset is added; on iOS the dock's own
  /// margin already covers the home indicator. Room for a floating button
  /// is added when the page carries one ([withFab]) and whenever the
  /// copilot's pill is on, since that one floats over every main tab and
  /// would otherwise sit on the last card, or on an empty state's button,
  /// once the list is scrolled to its end.
  static double bottomPadding(BuildContext context, {bool withFab = false}) {
    final fab = withFab || FeaturesFlags.assistant.isEnabled;
    return _dockPadding(context) + (fab ? fabClearance : 0);
  }

  static double _dockPadding(BuildContext context) {
    final inset = defaultTargetPlatform == TargetPlatform.android
        ? MediaQuery.paddingOf(context).bottom
        : 0.0;
    return reservedHeight + inset;
  }

  const ClayNavDock({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    required this.destinations,
  });

  @override
  Widget build(BuildContext context) {
    final glass = _GlassTone.of(AppColors.isDark);
    const shape = StadiumBorder();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.marginMobile,
        0,
        AppSpacing.marginMobile,
        AppSpacing.md,
      ),
      // Its own layer: the blur is redrawn as the page scrolls under it,
      // and nothing else on screen needs to repaint with it.
      child: RepaintBoundary(
        child: DecoratedBox(
          // The shadow sits outside the clip, so the glass seems to float.
          decoration: ShapeDecoration(shape: shape, shadows: glass.shadows),
          child: ClipPath(
            clipper: const ShapeBorderClipper(shape: shape),
            child: BackdropFilter(
              // Blur first, then lift the colour a little: the glass reads
              // as glass because what is behind it stays vivid, not grey.
              filter: ImageFilter.compose(
                outer: ColorFilter.matrix(_saturation(1.6)),
                inner: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              ),
              child: CustomPaint(
                // The rim and the sheen go over the fill and under the ink.
                foregroundPainter: _RimPainter(glass),
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    shape: shape,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [glass.fillTop, glass.fillBottom],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xs + 2),
                    child: _Items(
                      destinations: destinations,
                      selectedIndex: selectedIndex,
                      onSelected: onSelected,
                      glass: glass,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// A colour matrix that scales saturation by [s] (1 leaves it as is).
  static List<double> _saturation(double s) {
    const r = 0.2126, g = 0.7152, b = 0.0722;
    final i = 1 - s;
    return [
      i * r + s,
      i * g,
      i * b,
      0,
      0,
      i * r,
      i * g + s,
      i * b,
      0,
      0,
      i * r,
      i * g,
      i * b + s,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ];
  }
}

/// The colours of the glass for one theme.
class _GlassTone {
  final Color fillTop;
  final Color fillBottom;
  final Color rimBright;
  final Color rimFaint;
  final Color sheen;
  final Color pill;
  final Color pillRim;
  final Color activeInk;
  final Color inactiveInk;
  final List<BoxShadow> shadows;

  const _GlassTone({
    required this.fillTop,
    required this.fillBottom,
    required this.rimBright,
    required this.rimFaint,
    required this.sheen,
    required this.pill,
    required this.pillRim,
    required this.activeInk,
    required this.inactiveInk,
    required this.shadows,
  });

  factory _GlassTone.of(bool dark) {
    if (dark) {
      return _GlassTone(
        fillTop: const Color(0xFF2C2C2E).withValues(alpha: 0.58),
        fillBottom: const Color(0xFF1C1C1E).withValues(alpha: 0.46),
        rimBright: Colors.white.withValues(alpha: 0.32),
        rimFaint: Colors.white.withValues(alpha: 0.06),
        sheen: Colors.white.withValues(alpha: 0.07),
        pill: Colors.white.withValues(alpha: 0.13),
        pillRim: Colors.white.withValues(alpha: 0.18),
        activeInk: AppColors.primary,
        inactiveInk: Colors.white.withValues(alpha: 0.78),
        shadows: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      );
    }
    return _GlassTone(
      fillTop: Colors.white.withValues(alpha: 0.66),
      fillBottom: Colors.white.withValues(alpha: 0.46),
      rimBright: Colors.white.withValues(alpha: 0.95),
      rimFaint: Colors.white.withValues(alpha: 0.25),
      sheen: Colors.white.withValues(alpha: 0.35),
      pill: Colors.white.withValues(alpha: 0.72),
      pillRim: Colors.white,
      activeInk: AppColors.primary,
      inactiveInk: const Color(0xFF1C1C1E).withValues(alpha: 0.72),
      shadows: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.12),
          blurRadius: 30,
          offset: const Offset(0, 10),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ],
    );
  }
}

/// The light the glass catches: a rim brightest along the top edge and
/// fading round the sides, and a soft sheen over the upper half.
class _RimPainter extends CustomPainter {
  final _GlassTone glass;

  const _RimPainter(this.glass);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final radius = Radius.circular(size.height / 2);

    final sheenRect = Rect.fromLTWH(0, 0, size.width, size.height * 0.55);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, radius),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [glass.sheen, glass.sheen.withValues(alpha: 0)],
        ).createShader(sheenRect),
    );

    const stroke = 1.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(stroke / 2), radius),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [glass.rimBright, glass.rimFaint, glass.rimBright],
          stops: const [0, 0.55, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_RimPainter old) => old.glass != glass;
}

/// The tabs, with the active one's glass lozenge sliding beneath them.
///
/// Tapped, the lozenge glides to the tab with no overshoot: a tab bar is
/// touched tens of times a day, and the motion only has to say where the
/// selection went. Dragged, it stays under the finger the whole way, the
/// ink under it lighting up as it passes, and on release it is thrown on
/// by the finger's own momentum and settles on the nearest tab with the
/// small overshoot that momentum earns.
class _Items extends StatefulWidget {
  final List<ClayNavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final _GlassTone glass;

  const _Items({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    required this.glass,
  });

  @override
  State<_Items> createState() => _ItemsState();
}

class _ItemsState extends State<_Items> {
  /// The lozenge's start edge while a finger is dragging it, in the row's
  /// own directional coordinates. Null when it is resting on a tab.
  double? _dragStart;

  /// The tab the lozenge is over mid-drag — what the ink follows.
  int? _hovered;

  /// True from a drag's release until the lozenge lands, so that one glide
  /// gets the momentum curve and a plain tap does not.
  bool _fromDrag = false;

  double _slot = 1;
  double _width = 1;

  bool get _rtl => Directionality.of(context) == TextDirection.rtl;

  int _indexAt(double start) =>
      ((start + _slot / 2) ~/ _slot).clamp(0, widget.destinations.length - 1);

  void _onDragStart(DragStartDetails _) {
    setState(() {
      _dragStart = _slot * widget.selectedIndex;
      _hovered = widget.selectedIndex;
      _fromDrag = false;
    });
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final start = _dragStart;
    if (start == null) return;
    // In Hebrew and Arabic the row runs the other way, so a finger moving
    // right moves the lozenge toward a smaller `start`.
    final delta = _rtl ? -details.delta.dx : details.delta.dx;
    final next = (start + delta).clamp(0.0, _width - _slot);
    final over = _indexAt(next);
    // The tick of a picker wheel: one per tab the lozenge crosses.
    if (over != _hovered) HapticFeedback.selectionClick();
    setState(() {
      _dragStart = next;
      _hovered = over;
    });
  }

  void _onDragEnd(DragEndDetails details) {
    final start = _dragStart;
    if (start == null) return;
    // Land where the throw was going, not where the finger let go.
    final velocity = _rtl
        ? -details.velocity.pixelsPerSecond.dx
        : details.velocity.pixelsPerSecond.dx;
    final projected = start + AppMotion.project(velocity);
    final target = _indexAt(projected.clamp(0.0, _width - _slot));
    setState(() {
      _dragStart = null;
      _hovered = null;
      _fromDrag = true;
    });
    if (target != widget.selectedIndex) widget.onSelected(target);
  }

  void _onDragCancel() {
    if (_dragStart == null) return;
    setState(() {
      _dragStart = null;
      _hovered = null;
      _fromDrag = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final destinations = widget.destinations;
    final glass = widget.glass;
    final dragging = _dragStart != null;
    final active = _hovered ?? widget.selectedIndex;

    return LayoutBuilder(
      builder: (context, constraints) {
        _width = constraints.maxWidth;
        _slot = _width / destinations.length;
        return GestureDetector(
          onHorizontalDragStart: _onDragStart,
          onHorizontalDragUpdate: _onDragUpdate,
          onHorizontalDragEnd: _onDragEnd,
          onHorizontalDragCancel: _onDragCancel,
          behavior: HitTestBehavior.translucent,
          child: Stack(
            children: [
              // Positioned by `start`, so the lozenge lands under the right
              // tab in Hebrew and Arabic, where the row runs the other way.
              AnimatedPositionedDirectional(
                // Glued to the finger while dragging; otherwise a glide.
                duration: dragging
                    ? Duration.zero
                    : AppMotion.move(context, AppMotion.standard),
                curve: _fromDrag ? AppMotion.settle : AppMotion.easeOut,
                onEnd: () {
                  if (_fromDrag && mounted) setState(() => _fromDrag = false);
                },
                start: _dragStart ?? _slot * widget.selectedIndex,
                top: 0,
                bottom: 0,
                width: _slot,
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    color: glass.pill,
                    shape: StadiumBorder(
                      side: BorderSide(color: glass.pillRim, width: 0.6),
                    ),
                    shadows: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < destinations.length; i++)
                    _DockItem(
                      // Registered by position, which is what a tour step
                      // names — the labels change with the locale.
                      targetId: 'nav.$i',
                      destination: destinations[i],
                      isActive: i == active,
                      onTap: () => widget.onSelected(i),
                      glass: glass,
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DockItem extends StatelessWidget {
  final String targetId;
  final ClayNavDestination destination;
  final bool isActive;
  final VoidCallback onTap;
  final _GlassTone glass;

  const _DockItem({
    required this.targetId,
    required this.destination,
    required this.isActive,
    required this.onTap,
    required this.glass,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? glass.activeInk : glass.inactiveInk;

    return Expanded(
      child: WalkthroughTarget(
        id: targetId,
        child: Semantics(
          selected: isActive,
          button: true,
          label: destination.label,
          child: GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: AnimatedScale(
              scale: isActive ? 1.04 : 1,
              duration: AppMotion.move(context, AppMotion.standard),
              curve: AppMotion.easeOut,
              child: Padding(
                // Room above and below inside the lozenge, and between
                // neighbouring labels so they ellipsize into a gap.
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: AppSpacing.base,
                ),
                child: ExcludeSemantics(
                  // One tween over both the icon and the label: the ink
                  // changes colour in place rather than cross-fading two
                  // copies of the same glyph over each other.
                  child: TweenAnimationBuilder<Color?>(
                    tween: ColorTween(end: color),
                    duration: AppMotion.fade(context, AppMotion.quick),
                    curve: AppMotion.easeOut,
                    builder: (context, ink, _) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(destination.icon, size: 22, color: ink),
                        const SizedBox(height: 2),
                        Text(
                          destination.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.labelSm.copyWith(
                            color: ink,
                            fontSize: 10.5,
                            fontWeight: isActive
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
