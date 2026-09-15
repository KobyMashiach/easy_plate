import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_shadows.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/clay/clay.dart';

/// Held while the first auth state resolves, so the app never flashes the
/// login screen at a user who is already signed in.
///
/// The icon lands on a clay tile — scaling in with a small overshoot while a
/// soft lavender halo breathes behind it — and the name rises under it. Two
/// controllers: one for the entrance, run once, and one for the halo, which
/// keeps going for as long as the wait does.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();

  late final AnimationController _halo = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);

  late final Animation<double> _tileScale = CurvedAnimation(
    parent: _entrance,
    curve: const Interval(0, 0.55, curve: Curves.easeOutBack),
  );
  late final Animation<double> _tileFade = CurvedAnimation(
    parent: _entrance,
    curve: const Interval(0, 0.35, curve: Curves.easeOut),
  );
  late final Animation<double> _titleFade = CurvedAnimation(
    parent: _entrance,
    curve: const Interval(0.45, 0.85, curve: Curves.easeOut),
  );
  late final Animation<Offset> _titleRise =
      Tween(
        begin: const Offset(0, 0.6),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _entrance,
          curve: const Interval(0.45, 0.9, curve: Curves.easeOutCubic),
        ),
      );
  late final Animation<double> _dotsFade = CurvedAnimation(
    parent: _entrance,
    curve: const Interval(0.75, 1, curve: Curves.easeOut),
  );

  @override
  void dispose() {
    _entrance.dispose();
    _halo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClayScaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 220,
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // The halo: a lavender disc that swells and fades with the
                  // repeating controller, behind the tile.
                  AnimatedBuilder(
                    animation: _halo,
                    builder: (context, _) {
                      final t = Curves.easeInOut.transform(_halo.value);
                      return Opacity(
                        opacity: _tileFade.value * (0.55 - 0.3 * t),
                        child: Transform.scale(
                          scale: 0.8 + 0.25 * t,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primaryFixed,
                            ),
                            child: const SizedBox.expand(),
                          ),
                        ),
                      );
                    },
                  ),
                  FadeTransition(
                    opacity: _tileFade,
                    child: ScaleTransition(
                      scale: Tween(begin: 0.6, end: 1.0).animate(_tileScale),
                      child: Container(
                        width: 128,
                        height: 128,
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(
                            color: AppColors.surfaceContainerHighest,
                          ),
                          boxShadow: AppShadows.dialog,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          child: Image.asset(
                            'assets/app_icon.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            FadeTransition(
              opacity: _titleFade,
              child: SlideTransition(
                position: _titleRise,
                child: Text(
                  t.appName,
                  style: AppTextStyles.headlineLgMobile.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FadeTransition(
              opacity: _dotsFade,
              child: _LoadingDots(controller: _halo),
            ),
          ],
        ),
      ),
    );
  }
}

/// Three dots that swell one after another off the halo's clock, in place of
/// the stock spinner.
class _LoadingDots extends StatelessWidget {
  final AnimationController controller;

  const _LoadingDots({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.base),
            _dot(((controller.value * 3) - i).clamp(0.0, 1.0)),
          ],
        ],
      ),
    );
  }

  Widget _dot(double t) {
    final lift = Curves.easeInOut.transform(t);
    return Container(
      width: 8 + 4 * lift,
      height: 8 + 4 * lift,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Color.lerp(AppColors.primaryFixedDim, AppColors.primary, lift),
      ),
    );
  }
}
