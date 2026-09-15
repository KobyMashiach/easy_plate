import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_colors.dart';
import '../constants/app_shadows.dart';
import '../constants/app_spacing.dart';
import '../constants/app_text_styles.dart';
import '../navigation/main_tabs.dart';
import '../utils/i18n/strings.g.dart';
import '../widgets/clay/clay_button.dart';
import 'walkthrough_step.dart';
import 'walkthrough_targets.dart';

export 'walkthrough_step.dart';
export 'walkthrough_targets.dart';

/// The guided tour: dims the app, cuts a window around one control at a time
/// and explains it, and moves on when that control is tapped or "next" is.
///
/// Everything outside the window is blocked, so the only things that work
/// while a step is showing are the highlighted control and the tour's own
/// buttons. One tour runs at a time; starting another replaces it.
abstract class Walkthrough {
  static OverlayEntry? _entry;

  static bool get isActive => _entry != null;

  /// [onDone] gets true when the last step was passed, false when the tour
  /// was closed early.
  static void start(
    BuildContext context,
    List<WalkthroughStep> steps, {
    void Function(bool completed)? onDone,
  }) {
    if (steps.isEmpty) return;
    _dismiss();
    final overlay = Overlay.of(context, rootOverlay: true);
    final router = GoRouter.maybeOf(context);

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _WalkthroughOverlay(
        steps: steps,
        router: router,
        onDone: (completed) {
          if (_entry == entry) _dismiss();
          onDone?.call(completed);
        },
      ),
    );
    _entry = entry;
    overlay.insert(entry);
  }

  static void _dismiss() {
    _entry?.remove();
    _entry?.dispose();
    _entry = null;
  }
}

class _WalkthroughOverlay extends StatefulWidget {
  final List<WalkthroughStep> steps;
  final GoRouter? router;
  final void Function(bool completed) onDone;

  const _WalkthroughOverlay({
    required this.steps,
    required this.router,
    required this.onDone,
  });

  @override
  State<_WalkthroughOverlay> createState() => _WalkthroughOverlayState();
}

class _WalkthroughOverlayState extends State<_WalkthroughOverlay>
    with SingleTickerProviderStateMixin {
  int _index = 0;
  Rect? _target;
  Timer? _poll;
  bool _advancing = false;

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  WalkthroughStep get _step => widget.steps[_index];

  @override
  void initState() {
    super.initState();
    // Navigation cannot start from inside a build, and this overlay is
    // built the frame it is inserted — so the first placement waits a frame.
    WidgetsBinding.instance.addPostFrameCallback((_) => _enter(0));
    // The target moves — a route slides in, a list scrolls, the keyboard
    // opens — so its rectangle is re-read continuously rather than once.
    _poll = Timer.periodic(const Duration(milliseconds: 80), _track);
    // A global route rather than a widget over the window: anything placed
    // there would take the tap away from the control it is meant to reach.
    GestureBinding.instance.pointerRouter.addGlobalRoute(_onPointer);
  }

  @override
  void dispose() {
    _poll?.cancel();
    GestureBinding.instance.pointerRouter.removeGlobalRoute(_onPointer);
    _pulse.dispose();
    super.dispose();
  }

  void _enter(int index) {
    if (!mounted) return;
    setState(() {
      _index = index;
      _target = null;
      _advancing = false;
    });
    _ensurePlace(_step);
  }

  /// Brings the app to where the step's target lives: the right tab, and the
  /// right route on top of the shell.
  void _ensurePlace(WalkthroughStep step) {
    if (step.tab case final tab?) MainTabs.index.value = tab;
    final router = widget.router;
    if (router == null) return;

    final path = router.routerDelegate.currentConfiguration.uri.path;
    final want = step.route;
    if (want == null) {
      while (router.canPop()) {
        router.pop();
      }
    } else if (!path.endsWith('/$want')) {
      while (router.canPop()) {
        router.pop();
      }
      router.pushNamed(want);
    }
  }

  void _track(Timer _) {
    if (!mounted) return;
    final id = _step.targetId;
    final rect = id == null ? null : WalkthroughTargets.rectOf(id);
    if (rect != _target) setState(() => _target = rect);
  }

  void _onPointer(PointerEvent event) {
    if (event is! PointerUpEvent || _advancing || !_step.advanceOnTap) return;
    final target = _target;
    if (target == null || !target.contains(event.position)) return;
    _advancing = true;
    // The control's own handler runs on this same pointer-up; a beat later
    // the tour moves on, so the tap does what it always does first.
    Future.delayed(const Duration(milliseconds: 220), _advance);
  }

  void _advance() {
    if (!mounted) return;
    if (_index >= widget.steps.length - 1) {
      widget.onDone(true);
    } else {
      _enter(_index + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final hole = _step.targetId == null ? null : _target?.inflate(AppSpacing.base);
    final isLast = _index == widget.steps.length - 1;

    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (context, _) => CustomPaint(
                painter: _DimPainter(hole: hole, pulse: _pulse.value),
              ),
            ),
          ),
        ),
        // Everything but the window is blocked. Four slabs rather than one
        // sheet with a gap, so the window itself has nothing in it at all.
        for (final slab in _slabsAround(hole, size)) _Slab(rect: slab),
        _card(size, padding, hole, isLast),
      ],
    );
  }

  List<Rect> _slabsAround(Rect? hole, Size size) {
    if (hole == null) return [Offset.zero & size];
    final h = hole.intersect(Offset.zero & size);
    return [
      Rect.fromLTRB(0, 0, size.width, h.top),
      Rect.fromLTRB(0, h.bottom, size.width, size.height),
      Rect.fromLTRB(0, h.top, h.left, h.bottom),
      Rect.fromLTRB(h.right, h.top, size.width, h.bottom),
    ].where((r) => !r.isEmpty).toList();
  }

  Widget _card(Size size, EdgeInsets padding, Rect? hole, bool isLast) {
    const cardHeight = 250.0;
    final width = (size.width - 2 * AppSpacing.gutter).clamp(0.0, 420.0);
    final left = (size.width - width) / 2;

    double? top;
    double? bottom;
    if (hole == null) {
      top = (size.height - cardHeight) / 2;
    } else if (size.height - hole.bottom - padding.bottom >= cardHeight + AppSpacing.md) {
      top = hole.bottom + AppSpacing.md;
    } else {
      bottom = size.height - hole.top + AppSpacing.md;
    }

    final card = Material(
      type: MaterialType.transparency,
      child: Container(
        width: width,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.surfaceContainerHighest),
          boxShadow: AppShadows.dialog,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    t.walkthrough.stepOf(current: _index + 1, total: widget.steps.length),
                    style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant),
                  ),
                ),
                IconButton(
                  tooltip: t.walkthrough.close,
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.close_rounded, size: 20, color: AppColors.tertiary),
                  onPressed: () => widget.onDone(false),
                ),
              ],
            ),
            Text(_step.title, style: AppTextStyles.headlineMd),
            const SizedBox(height: AppSpacing.base),
            Text(
              _step.body,
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
            ),
            if (hole != null && _step.advanceOnTap) ...[
              const SizedBox(height: AppSpacing.base),
              Row(
                children: [
                  Icon(Icons.touch_app_rounded, size: 16, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      t.walkthrough.tapHint,
                      style: AppTextStyles.labelSm.copyWith(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                if (!isLast)
                  TextButton(
                    onPressed: () => _enter(_index + 1),
                    child: Text(
                      t.walkthrough.skipStep,
                      style: AppTextStyles.labelMd.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  ),
                const Spacer(),
                ClayButton(
                  label: isLast ? t.walkthrough.finish : t.walkthrough.next,
                  icon: isLast ? Icons.check_rounded : Icons.arrow_forward_rounded,
                  onPressed: _advance,
                ),
              ],
            ),
          ],
        ),
      ),
    );

    return Positioned(
      left: left,
      top: top == null ? null : (top < padding.top + AppSpacing.sm ? padding.top + AppSpacing.sm : top),
      bottom: bottom,
      child: card,
    );
  }
}

/// A blocking slab: swallows every tap so the app under it stays still.
class _Slab extends StatelessWidget {
  final Rect rect;

  const _Slab({required this.rect});

  @override
  Widget build(BuildContext context) {
    return Positioned.fromRect(
      rect: rect,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {},
        child: const SizedBox.expand(),
      ),
    );
  }
}

/// The dim over the page, with the window cut out of it and a mint ring
/// breathing around the window so the eye lands there.
class _DimPainter extends CustomPainter {
  final Rect? hole;
  final double pulse;

  const _DimPainter({required this.hole, required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final screen = Offset.zero & size;
    final dim = Paint()..color = AppColors.onSurface.withValues(alpha: 0.62);
    final window = hole;
    if (window == null) {
      canvas.drawRect(screen, dim);
      return;
    }
    final rounded = RRect.fromRectAndRadius(window, const Radius.circular(AppRadius.md));
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(screen),
        Path()..addRRect(rounded),
      ),
      dim,
    );
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = AppColors.secondaryContainer.withValues(alpha: 0.6 + 0.4 * pulse);
    canvas.drawRRect(rounded.inflate(2 + 4 * pulse), ring);
  }

  @override
  bool shouldRepaint(_DimPainter old) => old.hole != hole || old.pulse != pulse;
}
