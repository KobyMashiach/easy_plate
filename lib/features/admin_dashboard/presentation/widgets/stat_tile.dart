import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/clay/clay.dart';

/// A headline number with its name above and one line of context below.
/// The number wears text ink; the icon carries the tint.
class StatTile extends StatelessWidget {
  final String label;
  final String value;
  final String? hint;
  final IconData icon;
  final Color? tint;
  final VoidCallback? onTap;

  const StatTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.hint,
    this.tint,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tint = this.tint ?? AppColors.primary;
    return ClayCard(
      radius: AppRadius.md,
      padding: const EdgeInsets.all(AppSpacing.sm),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: tint),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              value,
              textDirection: TextDirection.ltr,
              style: AppTextStyles.headlineMd.copyWith(
                color: AppColors.onSurface,
              ),
            ),
          ),
          if (hint case final hint?) ...[
            const SizedBox(height: 2),
            Text(
              hint,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelSm.copyWith(
                color: AppColors.onSurfaceVariant,
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A titled card for a chart or a table, with the same frame everywhere.
class DashboardSection extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const DashboardSection({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ClayCard(
      radius: AppRadius.md,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: AppTextStyles.bodyLg)),
              ?trailing,
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}

/// A label / value line inside a section.
class StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? dot;

  const StatRow({
    super.key,
    required this.label,
    required this.value,
    this.dot,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          if (dot case final dot?) ...[
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
            const SizedBox(width: AppSpacing.base),
          ],
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelMd,
            ),
          ),
          const SizedBox(width: AppSpacing.base),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
