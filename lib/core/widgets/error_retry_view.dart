import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_text_styles.dart';
import '../utils/i18n/strings.g.dart';
import 'clay/clay.dart';

class ErrorRetryView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const ErrorRetryView({super.key, required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: ClayCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          radius: AppRadius.md,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppColors.errorContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  size: 32,
                  color: AppColors.onErrorContainer,
                ),
              ),
              const SizedBox(height: AppSpacing.gutter),
              Text(t.common.error, style: AppTextStyles.headlineMd),
              const SizedBox(height: AppSpacing.base),
              Text(
                error,
                style: AppTextStyles.labelMd.copyWith(color: AppColors.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.gutter),
              ClayButton(label: t.common.retry, icon: Icons.refresh_rounded, onPressed: onRetry),
            ],
          ),
        ),
      ),
    );
  }
}
