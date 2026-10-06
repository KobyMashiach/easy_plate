import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';
import '../constants/app_motion.dart';
import '../constants/app_shadows.dart';
import '../constants/app_spacing.dart';
import '../constants/app_text_styles.dart';
import '../services/cook_session_service.dart';
import '../utils/i18n/strings.g.dart';
import 'press_scale.dart';

/// A stack of pills under the app bar of every screen, while
/// cook-mode timers are counting down or have just rung: one pill per
/// timer, across every recipe being cooked. The front pill is live; the
/// ones behind peek out below it, translucent, so it is clear there are
/// more. A swipe up flips the stack (the next card comes to the front, the
/// way the Galaxy Now Bar does), a swipe down flips it back; a tap opens
/// the step the timer belongs to. The body underneath moves down to make room. Hidden
/// for the recipe whose cook screen is on top, which has its own strip.
class CookTimerBanner extends StatelessWidget {
  final Widget child;

  /// True when the strip sits at the very top of the window and must clear
  /// the status bar; false under an app bar, which already did.
  final bool insetTop;

  const CookTimerBanner({
    super.key,
    required this.child,
    this.insetTop = false,
  });

  @override
  Widget build(BuildContext context) {
    final service = CookSessionService();
    // Rebuilt when a timer starts, stops, rings or a cook screen comes and
    // goes; the once-a-second clock is the front card's own concern, so a
    // screen with no banner costs nothing per tick.
    return ValueListenableBuilder<int>(
      valueListenable: service.structure,
      builder: (context, _, _) {
        final timers = service.activeTimers
            .where((a) => a.session.id != service.visibleRecipeId)
            .toList();
        final showing = timers.isNotEmpty;
        // The stack sits above the app, not over it: the screen below moves
        // down by its height and keeps its own bar in view. The stack takes
        // the status-bar inset, so the screen must not add it again.
        return Column(
          // Stretch: the body below must keep the tight full-width
          // constraints a Scaffold body normally gets.
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AnimatedSize(
              duration: AppMotion.move(context, AppMotion.standard),
              curve: AppMotion.easeOut,
              alignment: Alignment.topCenter,
              child: showing
                  ? _PillStack(
                      key: const ValueKey('cook-timer-banner'),
                      timers: timers,
                      insetTop: insetTop,
                      onOpen: service.reopenAt,
                    )
                  : const SizedBox(width: double.infinity),
            ),
            Expanded(
              child: MediaQuery.removePadding(
                context: context,
                removeTop: showing && insetTop,
                child: child,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PillStack extends StatefulWidget {
  final List<ActiveCookTimer> timers;
  final bool insetTop;
  final ValueChanged<ActiveCookTimer> onOpen;

  const _PillStack({
    super.key,
    required this.timers,
    required this.insetTop,
    required this.onOpen,
  });

  @override
  State<_PillStack> createState() => _PillStackState();
}

class _PillStackState extends State<_PillStack> {
  /// The card in front is the service's choice (shared by every screen's
  /// banner), found by timer key: the list reorders as timers start and
  /// stop, and the front card must not change under the user.
  double _drag = 0;

  int get _page {
    final key = CookSessionService().selectedTimerKey;
    final i = widget.timers.indexWhere((a) => a.key == key);
    return i < 0 ? 0 : i;
  }

  static const _peek = 7.0;
  static const _flipDistance = 24.0;

  /// Height of one pill (the ghosts behind it are drawn at the same size):
  /// two text lines and the bar, scaled with the system font, plus padding.
  double _pillHeight(BuildContext context) =>
      AppSpacing.sm * 2 + MediaQuery.textScalerOf(context).scale(52);

  /// Flipping the stack: a swipe up brings the next card to the front, a
  /// swipe down brings the previous one back; both wrap around.
  void _flip(int by) {
    final count = widget.timers.length;
    if (count < 2) return;
    HapticFeedback.selectionClick();
    setState(() {
      CookSessionService().selectedTimerKey =
          widget.timers[(_page + by) % count].key;
    });
  }

  void _onDragUpdate(DragUpdateDetails d) =>
      setState(() => _drag += d.delta.dy);

  void _onDragEnd(DragEndDetails d) {
    final velocity = d.primaryVelocity ?? 0;
    if (_drag < -_flipDistance || velocity < -300) {
      _flip(1);
    } else if (_drag > _flipDistance || velocity > 300) {
      _flip(-1);
    }
    setState(() => _drag = 0);
  }

  /// The front card follows the finger a little, resisting more the further
  /// it goes, so the flip reads as something lifted rather than a tap.
  double get _lift {
    const limit = 14.0;
    final d = _drag.clamp(-60.0, 60.0);
    return (d * limit) / (limit + d.abs()) * 0.9;
  }

  @override
  Widget build(BuildContext context) {
    final timers = widget.timers;
    final count = timers.length;
    final behind = (count - 1).clamp(0, 2);
    final pillHeight = _pillHeight(context);
    final active = timers[_page.clamp(0, count - 1)];
    return SafeArea(
      top: widget.insetTop,
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.marginMobile,
          AppSpacing.base,
          AppSpacing.marginMobile,
          AppSpacing.base,
        ),
        child: GestureDetector(
          onVerticalDragUpdate: count > 1 ? _onDragUpdate : null,
          onVerticalDragEnd: count > 1 ? _onDragEnd : null,
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            height: pillHeight + behind * _peek,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // The ones underneath: each a little lower, narrower,
                // fainter. They are what a swipe brings to the front.
                for (var i = behind; i >= 1; i--)
                  Positioned(
                    top: i * _peek,
                    left: i * 10.0,
                    right: i * 10.0,
                    height: pillHeight,
                    child: Opacity(
                      opacity: i == 1 ? .55 : .3,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.navDock,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: pillHeight,
                  child: AnimatedSwitcher(
                    duration: AppMotion.fade(context, AppMotion.emphasized),
                    switchInCurve: AppMotion.easeOut,
                    switchOutCurve: AppMotion.easeOut,
                    // The old card lifts away; the new one rises from the
                    // stack behind, growing to full size as it arrives.
                    transitionBuilder: (child, animation) {
                      // Reduced motion: a plain cross-fade, no travel.
                      if (AppMotion.reduced(context)) {
                        return FadeTransition(opacity: animation, child: child);
                      }
                      final incoming = child.key == ValueKey(active.key);
                      final slide = Tween<Offset>(
                        begin: incoming
                            ? const Offset(0, .18)
                            : const Offset(0, -.35),
                        end: Offset.zero,
                      ).animate(animation);
                      final scale = Tween<double>(
                        begin: incoming ? .94 : 1,
                        end: 1,
                      ).animate(animation);
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: slide,
                          child: ScaleTransition(scale: scale, child: child),
                        ),
                      );
                    },
                    layoutBuilder: (current, previous) => Stack(
                      alignment: Alignment.topCenter,
                      children: [...previous, ?current],
                    ),
                    child: Transform.translate(
                      key: ValueKey(active.key),
                      offset: Offset(0, _lift),
                      child: _Pill(
                        active: active,
                        index: _page.clamp(0, count - 1),
                        count: count,
                        onTap: () => widget.onOpen(active),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final ActiveCookTimer active;
  final int index;
  final int count;
  final VoidCallback onTap;

  const _Pill({
    required this.active,
    required this.index,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // The clock and the bar move every second: this card alone listens.
    return AnimatedBuilder(
      animation: CookSessionService(),
      builder: (context, _) => _build(context),
    );
  }

  Widget _build(BuildContext context) {
    final timer = active.timer;
    final finished = timer.finished;
    final face = finished ? AppColors.secondaryContainer : AppColors.navDock;
    final ink = finished ? AppColors.onSecondaryContainer : Colors.white;
    final accent = finished ? ink : AppColors.secondaryFixedDim;
    final step = t.cookMode.stepLabel(n: '${active.step + 1}');

    return PressScale(
      onTap: onTap,
      scale: .98,
      child: Material(
        color: Colors.transparent,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: face,
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: AppShadows.dock,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.gutter,
              AppSpacing.sm,
              AppSpacing.gutter,
              AppSpacing.sm,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Icon(
                      finished
                          ? Icons.notifications_active_rounded
                          : Icons.timer_rounded,
                      size: 18,
                      color: accent,
                    ),
                    const SizedBox(width: AppSpacing.base),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            active.session.recipe.title,
                            style: AppTextStyles.labelMd.copyWith(color: ink),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            finished ? '$step · ${t.cookMode.timeUp}' : step,
                            style: AppTextStyles.labelSm.copyWith(
                              color: ink.withValues(alpha: .7),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.base),
                    Text(
                      timer.display,
                      style: AppTextStyles.bodyLg.copyWith(
                        color: ink,
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    if (count > 1) ...[
                      const SizedBox(width: AppSpacing.base),
                      // Which of the stack this is.
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var i = 0; i < count && i < 5; i++)
                            Container(
                              width: i == index ? 10 : 4,
                              height: 4,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: i == index
                                    ? accent
                                    : ink.withValues(alpha: .35),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.base),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  child: LinearProgressIndicator(
                    value: timer.progress,
                    minHeight: 4,
                    backgroundColor: ink.withValues(alpha: .18),
                    valueColor: AlwaysStoppedAnimation(accent),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
