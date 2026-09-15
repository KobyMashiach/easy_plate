import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'theme_controller.dart';

/// The Telegram-style theme switch: the new theme spreads out as a circle
/// from the point that was tapped, over a frozen picture of the old one.
///
/// How: the app is wrapped in a [RepaintBoundary]. On a switch, that boundary
/// is rasterised to an image, the palette is swapped and the app rebuilds in
/// its new colours *underneath*, and the image is laid on top with a hole in
/// it that grows from the tap point until nothing of the old frame is left.
/// The reveal is a clip, not a shader, so it costs one texture draw a frame.
///
/// Sits in `MaterialApp.builder`, above the navigator, so dialogs and sheets
/// are part of the frozen frame too.
class ThemeSwitcher extends StatefulWidget {
  final Widget child;

  const ThemeSwitcher({super.key, required this.child});

  static ThemeSwitcherState of(BuildContext context) {
    final state = context.findAncestorStateOfType<ThemeSwitcherState>();
    assert(state != null, 'ThemeSwitcher is missing above this context');
    return state!;
  }

  @override
  State<ThemeSwitcher> createState() => ThemeSwitcherState();
}

class ThemeSwitcherState extends State<ThemeSwitcher> with SingleTickerProviderStateMixin {
  static const duration = Duration(milliseconds: 650);

  final _boundary = GlobalKey();
  late final AnimationController _progress;
  ui.Image? _snapshot;
  Offset _origin = Offset.zero;

  /// True while the old frame is still on screen — the reveal is running.
  @visibleForTesting
  bool get isRevealing => _snapshot != null;

  @override
  void initState() {
    super.initState();
    _progress = AnimationController(vsync: this, duration: duration);
  }

  @override
  void dispose() {
    _progress.dispose();
    _snapshot?.dispose();
    super.dispose();
  }

  /// Switches to [mode], revealing it from [origin] (global coordinates —
  /// the tap's `globalPosition`). When the mode would not change the colours
  /// there is nothing to animate and the choice is just stored.
  Future<void> switchTo(AppThemeMode mode, {required Offset origin}) async {
    final controller = ThemeController();
    if (_progress.isAnimating || controller.resolvesDark(mode) == controller.isDark) {
      await controller.setMode(mode);
      return;
    }

    final image = await _capture();
    if (!mounted) return;
    if (image == null) {
      // Could not rasterise (headless, or mid-layout): switch without the show.
      await controller.setMode(mode);
      return;
    }

    setState(() {
      _snapshot?.dispose();
      _snapshot = image;
      _origin = origin;
    });
    await controller.setMode(mode);
    // Let the new colours paint under the snapshot before the hole opens,
    // otherwise the first frames of the reveal show the *old* colours again.
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    await _progress.forward(from: 0);
    if (!mounted) return;
    setState(() {
      _snapshot?.dispose();
      _snapshot = null;
    });
  }

  Future<ui.Image?> _capture() async {
    final boundary = _boundary.currentContext?.findRenderObject();
    if (boundary is! RenderRepaintBoundary) return null;
    try {
      return await boundary.toImage(pixelRatio: MediaQuery.devicePixelRatioOf(context));
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(key: _boundary, child: widget.child),
        if (_snapshot != null)
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _progress,
              builder: (context, _) => CustomPaint(
                painter: _RevealPainter(
                  image: _snapshot!,
                  origin: _origin,
                  progress: Curves.easeInOutCubic.transform(_progress.value),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Paints the old frame with a circular hole of growing radius at [origin].
class _RevealPainter extends CustomPainter {
  final ui.Image image;
  final Offset origin;
  final double progress;

  const _RevealPainter({required this.image, required this.origin, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // Far enough to clear the farthest corner, whichever corner that is.
    final reach = math.max(
      math.max(origin.distance, (Offset(size.width, 0) - origin).distance),
      math.max((Offset(0, size.height) - origin).distance, (Offset(size.width, size.height) - origin).distance),
    );
    final hole = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addOval(Rect.fromCircle(center: origin, radius: reach * progress));
    canvas.clipPath(hole);
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Offset.zero & size,
      Paint()..filterQuality = FilterQuality.low,
    );
  }

  @override
  bool shouldRepaint(_RevealPainter old) =>
      old.progress != progress || old.image != image || old.origin != origin;
}
