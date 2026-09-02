import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../constants/app_text_styles.dart';

/// Screen-level title with an optional supporting line, matching the
/// "Smart Grocery List / Your weekly essentials..." block in the Stitch screens.
class ClayPageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const ClayPageHeader({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.headlineLgMobile),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.base),
          Text(
            subtitle!,
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}

/// Section heading with the hairline rule used to separate grocery categories.
class ClaySectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final bool underline;

  const ClaySectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.underline = false,
  });

  @override
  Widget build(BuildContext context) {
    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: Text(title, style: AppTextStyles.headlineMd)),
        ?trailing,
      ],
    );

    if (!underline) return row;

    return Container(
      padding: const EdgeInsets.only(bottom: AppSpacing.base),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.surfaceVariant)),
      ),
      child: row,
    );
  }
}

/// Friendly empty state: a soft lavender medallion above the message.
class ClayEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final Widget? action;

  const ClayEmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: AppColors.primaryFixed,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 44, color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
            ),
            if (action != null) ...[
              const SizedBox(height: AppSpacing.md),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
