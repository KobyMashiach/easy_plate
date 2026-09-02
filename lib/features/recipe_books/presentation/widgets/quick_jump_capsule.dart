import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_shadows.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';

class QuickJumpAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const QuickJumpAction({required this.icon, required this.label, required this.onTap});
}

/// Frosted capsule floating over the open book, holding the reader's jump
/// actions with hairline dividers between them.
class QuickJumpCapsule extends StatelessWidget {
  final List<QuickJumpAction> actions;

  const QuickJumpCapsule({super.key, required this.actions});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.gutter,
            vertical: AppSpacing.base,
          ),
          decoration: ShapeDecoration(
            color: AppColors.surface.withValues(alpha: 0.8),
            shape: StadiumBorder(
              side: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
            ),
            shadows: AppShadows.card,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < actions.length; i++) ...[
                if (i > 0)
                  Container(
                    width: 1,
                    height: AppSpacing.md,
                    margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                    color: AppColors.outlineVariant.withValues(alpha: 0.5),
                  ),
                _CapsuleButton(action: actions[i]),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CapsuleButton extends StatelessWidget {
  final QuickJumpAction action;

  const _CapsuleButton({required this.action});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: action.onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(action.icon, size: 20, color: AppColors.onSurfaceVariant),
          const SizedBox(height: AppSpacing.xs),
          Text(
            action.label,
            style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
