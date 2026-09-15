import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_spacing.dart';
import 'clay/clay.dart';

/// The picture on its own: full screen, uncropped, pinch to zoom, tap or
/// swipe down to leave. Opened by a tap on any photo the app shows large;
/// a long press on the same photo is what changes it.
Future<void> showImageViewer(
  BuildContext context, {
  required String? fileName,
  String? remotePath,
}) {
  return Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.black,
      transitionDuration: const Duration(milliseconds: 220),
      reverseTransitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (_, _, _) => _ImageViewerPage(fileName: fileName, remotePath: remotePath),
      transitionsBuilder: (_, animation, _, child) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween(begin: 0.96, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: child,
        ),
      ),
    ),
  );
}

class _ImageViewerPage extends StatefulWidget {
  final String? fileName;
  final String? remotePath;

  const _ImageViewerPage({required this.fileName, required this.remotePath});

  @override
  State<_ImageViewerPage> createState() => _ImageViewerPageState();
}

class _ImageViewerPageState extends State<_ImageViewerPage> {
  final _zoom = TransformationController();

  @override
  void dispose() {
    _zoom.dispose();
    super.dispose();
  }

  bool get _zoomed => _zoom.value.getMaxScaleOnAxis() > 1.02;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                // A tap leaves; a double tap toggles 2.5x around the spot.
                onTap: () => Navigator.of(context).maybePop(),
                onDoubleTapDown: (d) => setState(() {
                  if (_zoomed) {
                    _zoom.value = Matrix4.identity();
                  } else {
                    final p = d.localPosition;
                    _zoom.value = Matrix4.identity()
                      ..translateByDouble(-p.dx * 1.5, -p.dy * 1.5, 0, 1)
                      ..scaleByDouble(2.5, 2.5, 1, 1);
                  }
                }),
                onVerticalDragEnd: (d) {
                  // Swipe down to dismiss, only when not zoomed in — zoomed,
                  // a vertical drag is panning the picture.
                  if (!_zoomed && (d.primaryVelocity ?? 0) > 500) Navigator.of(context).maybePop();
                },
                child: InteractiveViewer(
                  transformationController: _zoom,
                  minScale: 1,
                  maxScale: 5,
                  clipBehavior: Clip.none,
                  child: Center(
                    child: ClayImage(
                      fileName: widget.fileName,
                      remotePath: widget.remotePath,
                      fit: BoxFit.contain,
                      radius: 0,
                      tint: Colors.transparent,
                      fallbackIconSize: 96,
                    ),
                  ),
                ),
              ),
            ),
            PositionedDirectional(
              top: MediaQuery.paddingOf(context).top + AppSpacing.base,
              end: AppSpacing.gutter,
              child: IconButton(
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
