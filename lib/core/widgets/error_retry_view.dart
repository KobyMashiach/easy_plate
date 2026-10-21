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

  /// Whether [text] is a raw exception rather than a sentence for the user:
  /// a `toString()` of an error, a stack trace, an object's default name.
  @visibleForTesting
  static bool looksUnlocalized(String text) =>
      text.contains('Exception') ||
      text.contains('Error:') ||
      text.contains('#0') ||
      text.contains('Instance of');

  /// What is shown under the title: [error] when it was written for the
  /// user, the generic line when it is a raw exception.
  static String messageFor(String error) =>
      looksUnlocalized(error) ? t.common.loadFailed : error;

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
                decoration: BoxDecoration(
                  color: AppColors.errorContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 32,
                  color: AppColors.onErrorContainer,
                ),
              ),
              const SizedBox(height: AppSpacing.gutter),
              Text(t.common.error, style: AppTextStyles.headlineMd),
              const SizedBox(height: AppSpacing.base),
              Text(
                messageFor(error),
                style: AppTextStyles.labelMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.gutter),
              ClayButton(
                label: t.common.retry,
                icon: Icons.refresh_rounded,
                onPressed: onRetry,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
