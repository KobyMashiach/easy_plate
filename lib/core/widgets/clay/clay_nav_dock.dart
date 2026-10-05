import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../constants/app_text_styles.dart';
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

  /// A floating action button's height plus the gap that keeps it off the
  /// last card, for pages that carry one above the dock.
  static const fabClearance = 56.0 + AppSpacing.gutter;

  /// Bottom padding for a page under the dock, so its last item scrolls all
  /// the way out from under it. On Android the dock floats above the gesture
  /// bar (see [MainNavBar]), so that inset is added; on iOS the dock's own
  /// margin already covers the home indicator. [withFab] adds room for a
  /// button floating above the dock, which would otherwise sit on the last
  /// card once the list is scrolled to its end.
  static double bottomPadding(BuildContext context, {bool withFab = false}) {
    final inset = defaultTargetPlatform == TargetPlatform.android
        ? MediaQuery.paddingOf(context).bottom
        : 0.0;
    return reservedHeight + inset + (withFab ? fabClearance : 0);
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
class _Items extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final slot = constraints.maxWidth / destinations.length;
        return Stack(
          children: [
            // Positioned by `start`, so the lozenge lands under the right
            // tab in Hebrew and Arabic, where the row runs the other way.
            AnimatedPositionedDirectional(
              duration: const Duration(milliseconds: 380),
              curve: Curves.easeOutBack,
              start: slot * selectedIndex,
              top: 0,
              bottom: 0,
              width: slot,
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
                    isActive: i == selectedIndex,
                    onTap: () => onSelected(i),
                    glass: glass,
                  ),
              ],
            ),
          ],
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
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              child: Padding(
                // Room above and below inside the lozenge, and between
                // neighbouring labels so they ellipsize into a gap.
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: AppSpacing.base,
                ),
                child: ExcludeSemantics(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          destination.icon,
                          key: ValueKey(isActive),
                          size: 22,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        destination.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.labelSm.copyWith(
                          color: color,
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
    );
  }
}
