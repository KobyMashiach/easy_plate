import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_motion.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/utils/routing/routing.dart';
import '../../../../core/widgets/press_scale.dart';

/// The door to the copilot, floating above the dock on every main tab: a
/// gradient pill with a sparkle and the assistant's name, lit by a soft
/// glow that breathes slowly so the eye finds it, and still under reduced
/// motion.
class AssistantFab extends StatefulWidget {
  const AssistantFab({super.key});

  @override
  State<AssistantFab> createState() => _AssistantFabState();
}

class _AssistantFabState extends State<AssistantFab>
    with SingleTickerProviderStateMixin {
  late final _breath = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.reduced(context)) {
      _breath.stop();
    } else if (!_breath.isAnimating) {
      _breath.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _breath,
      builder: (context, child) {
        final glow = 0.45 + 0.25 * _breath.value;
        return DecoratedBox(
          decoration: ShapeDecoration(
            shape: const StadiumBorder(),
            shadows: [
              BoxShadow(
                color: AppColors.lavenderGlow.withValues(alpha: glow),
                blurRadius: 24 + 8 * _breath.value,
                spreadRadius: 1,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        );
      },
      child: PressScale(
        scale: .95,
        onTap: () => context.pushNamed(Routing.assistant),
        child: Semantics(
          button: true,
          label: t.assistant.title,
          child: Container(
            height: 56,
            padding: const EdgeInsetsDirectional.only(
              start: AppSpacing.gutter,
              end: AppSpacing.md,
            ),
            decoration: ShapeDecoration(
              shape: const StadiumBorder(),
              gradient: LinearGradient(
                begin: AlignmentDirectional.topStart,
                end: AlignmentDirectional.bottomEnd,
                colors: [
                  AppColors.lavenderGlow,
                  AppColors.primary,
                  AppColors.onPrimaryFixedVariant,
                ],
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .22),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    size: 18,
                    color: AppColors.onPrimary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  t.assistant.title,
                  style: AppTextStyles.bodyLg.copyWith(
                    color: AppColors.onPrimary,
                    fontWeight: FontWeight.w700,
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
