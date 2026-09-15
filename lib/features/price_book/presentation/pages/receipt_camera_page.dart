import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../paper_detector.dart';

/// A viewfinder with one job: a tall frame across the screen, and the shot
/// is taken by itself the moment a receipt sits still inside it. No button
/// — the frame turns green, fills a thin progress ring, clicks, and the
/// page pops with the JPEG bytes. Null when the camera is unavailable or
/// the user backed out; the caller falls back to the system camera.
///
/// Detection is [PaperDetector] over the live preview stream, sampled on a
/// coarse grid, so it costs a few hundred pixel reads per frame.
class ReceiptCameraPage extends StatefulWidget {
  const ReceiptCameraPage({super.key});

  /// False after the camera failed to start (permission refused, no
  /// camera), so the caller can fall back to the system picker.
  static bool lastOpenSucceeded = true;

  static Future<Uint8List?> open(BuildContext context) {
    return Navigator.of(context, rootNavigator: true).push<Uint8List>(
      MaterialPageRoute(
        builder: (_) => const ReceiptCameraPage(),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  State<ReceiptCameraPage> createState() => _ReceiptCameraPageState();
}

class _ReceiptCameraPageState extends State<ReceiptCameraPage>
    with WidgetsBindingObserver {
  CameraController? _controller;
  final _detector = PaperDetector();
  PaperVerdict _verdict = const PaperVerdict(PaperState.searching, progress: 0);
  bool _capturing = false;
  bool _failed = false;
  // Analysing every frame would burn the battery for nothing; every third
  // is still ten a second.
  int _frame = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _start();
  }

  Future<void> _start() async {
    try {
      final cameras = await availableCameras();
      final back =
          cameras
              .where((c) => c.lensDirection == CameraLensDirection.back)
              .firstOrNull ??
          cameras.firstOrNull;
      if (back == null) throw StateError('no camera');
      final controller = CameraController(
        back,
        ResolutionPreset.veryHigh,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.yuv420
            : ImageFormatGroup.bgra8888,
      );
      await controller.initialize();
      await controller.setFlashMode(FlashMode.off);
      await controller.lockCaptureOrientation(DeviceOrientation.portraitUp);
      if (!mounted) {
        await controller.dispose();
        return;
      }
      ReceiptCameraPage.lastOpenSucceeded = true;
      setState(() => _controller = controller);
      await controller.startImageStream(_onFrame);
    } catch (e) {
      debugPrint('Receipt camera unavailable: $e');
      ReceiptCameraPage.lastOpenSucceeded = false;
      if (!mounted) return;
      setState(() => _failed = true);
      // Nothing to look through: hand back to the sheet, which falls back
      // to the system camera.
      Navigator.of(context).maybePop();
    }
  }

  void _onFrame(CameraImage image) {
    if (_capturing) return;
    if (_frame++ % 3 != 0) return;
    final plane = image.planes.first;
    final bytes = plane.bytes;
    final rowStride = plane.bytesPerRow;
    // YUV420: plane 0 is luma, one byte per pixel. BGRA: four bytes per
    // pixel, green is close enough to luma for "is this paper".
    final pixelStride = plane.bytesPerPixel ?? 1;
    final green = pixelStride == 4 ? 1 : 0;
    int luma(int x, int y) {
      final index = y * rowStride + x * pixelStride + green;
      return index < bytes.length ? bytes[index] : 0;
    }

    final verdict = _detector.feed(
      width: image.width,
      height: image.height,
      luma: luma,
    );
    if (!mounted) return;
    if (verdict.state != _verdict.state ||
        verdict.progress != _verdict.progress) {
      setState(() => _verdict = verdict);
    }
    if (verdict.state == PaperState.ready) _capture();
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || _capturing) return;
    _capturing = true;
    try {
      await controller.stopImageStream();
      HapticFeedback.mediumImpact();
      final file = await controller.takePicture();
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      Navigator.of(context).pop(bytes);
    } catch (e) {
      debugPrint('Receipt capture failed: $e');
      _capturing = false;
      _detector.reset();
      if (mounted && _controller != null) {
        await _controller!.startImageStream(_onFrame);
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      controller.dispose();
      _controller = null;
    } else if (state == AppLifecycleState.resumed) {
      _start();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final ready = controller != null && controller.value.isInitialized;
    final state = _verdict.state;
    final frameColor = switch (state) {
      PaperState.searching => Colors.white,
      PaperState.moving => Colors.amber,
      PaperState.holding || PaperState.ready => const Color(0xFF2ECC71),
    };
    final hint = switch (state) {
      PaperState.searching => t.receipt.cameraGuide,
      PaperState.moving || PaperState.holding => t.receipt.cameraHold,
      PaperState.ready => t.receipt.cameraCaptured,
    };

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            if (ready)
              // Cover the screen with the preview, cropping the edges rather
              // than letterboxing: the guide is drawn over the screen, and
              // the detector samples the same central band of the sensor.
              FittedBox(
                fit: BoxFit.cover,
                clipBehavior: Clip.hardEdge,
                child: SizedBox(
                  width: controller.value.previewSize!.height,
                  height: controller.value.previewSize!.width,
                  child: CameraPreview(controller),
                ),
              )
            else if (_failed)
              Center(
                child: Text(
                  t.receipt.cameraUnavailable,
                  style: AppTextStyles.bodyMd.copyWith(color: Colors.white),
                ),
              )
            else
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            // The guide: a tall rounded frame with the outside dimmed.
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _GuidePainter(
                    color: frameColor,
                    progress: _verdict.progress,
                    longStart: _detector.guideStart,
                    longEnd: _detector.guideEnd,
                    sideStart: _detector.guideSideStart,
                    sideEnd: _detector.guideSideEnd,
                  ),
                ),
              ),
            ),
            PositionedDirectional(
              top: MediaQuery.paddingOf(context).top + AppSpacing.base,
              start: AppSpacing.gutter,
              child: IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.lg,
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    key: ValueKey(hint),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.gutter,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: ShapeDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      shape: const StadiumBorder(),
                    ),
                    child: Text(
                      hint,
                      style: AppTextStyles.bodyMd.copyWith(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dims everything outside the guide and draws the frame; the progress
/// runs along the frame as the hold counts down to the shot.
class _GuidePainter extends CustomPainter {
  final Color color;
  final double progress;
  final double longStart;
  final double longEnd;
  final double sideStart;
  final double sideEnd;

  const _GuidePainter({
    required this.color,
    required this.progress,
    required this.longStart,
    required this.longEnd,
    required this.sideStart,
    required this.sideEnd,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Portrait: the long axis is vertical.
    final rect = Rect.fromLTRB(
      size.width * sideStart,
      size.height * longStart,
      size.width * sideEnd,
      size.height * longEnd,
    );
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(18));
    final dim = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRRect(rrect);
    canvas.drawPath(dim, Paint()..color = Colors.black.withValues(alpha: 0.45));
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = color,
    );
    if (progress > 0) {
      final path = Path()..addRRect(rrect);
      for (final metric in path.computeMetrics()) {
        canvas.drawPath(
          metric.extractPath(0, metric.length * progress),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 7
            ..strokeCap = StrokeCap.round
            ..color = color,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_GuidePainter old) =>
      old.color != color || old.progress != progress;
}
