import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_text_styles.dart';
import '../services/app_update_service.dart';
import '../utils/i18n/strings.g.dart';
import 'clay/clay.dart';

/// Puts the update prompt above the whole app.
///
/// It wraps the router's output rather than living on a screen, for two
/// reasons: the verdict can change at any moment (Remote Config is re-fetched
/// on every resume), and a forced update has to survive whatever route the user
/// happens to be on — including one pushed by a notification tap.
///
/// The forced prompt has no dismissal at all. Its barrier swallows every
/// pointer, so the app underneath stays reachable only in the sense that it is
/// still mounted.
class UpdateGate extends StatelessWidget {
  final Widget child;

  const UpdateGate({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<UpdateRequirement>(
      valueListenable: AppUpdateService().requirement,
      builder: (context, requirement, _) => Stack(
        children: [
          child,
          if (requirement != UpdateRequirement.none)
            _UpdatePrompt(forced: requirement == UpdateRequirement.forced),
        ],
      ),
    );
  }
}

/// Distinguishes this barrier from the one every MaterialApp route already
/// carries, for the widget test.
@visibleForTesting
const barrierKey = ValueKey('updateBarrier');

class _UpdatePrompt extends StatelessWidget {
  final bool forced;

  const _UpdatePrompt({required this.forced});

  @override
  Widget build(BuildContext context) {
    final service = AppUpdateService();
    final version = service.latestVersion;

    return Positioned.fill(
      child: Semantics(
        // Named so the whole prompt is announced as one thing, and so a
        // forced barrier does not read as an unlabelled blocker.
        container: true,
        label: forced ? t.update.forcedTitle : t.update.optionalTitle,
        child: Stack(
          children: [
            // Non-dismissible in both cases: the optional prompt is left
            // through its own Skip button, so a stray tap outside cannot be
            // mistaken for having taken the update.
            ModalBarrier(
              key: barrierKey,
              color: AppColors.onSurface.withValues(alpha: forced ? 0.92 : 0.62),
              dismissible: false,
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.marginMobile),
                child: ClayCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        forced ? Icons.system_update_rounded : Icons.auto_awesome_rounded,
                        size: AppSpacing.xl,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: AppSpacing.gutter),
                      Text(
                        forced ? t.update.forcedTitle : t.update.optionalTitle,
                        style: AppTextStyles.headlineMd,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.base),
                      Text(
                        forced
                            ? t.update.forcedBody(version: version)
                            : t.update.optionalBody(version: version),
                        style: AppTextStyles.bodyMd.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      ClayButton(
                        label: t.update.updateNow,
                        icon: Icons.download_rounded,
                        expanded: true,
                        onPressed: service.openStore,
                      ),
                      if (!forced) ...[
                        const SizedBox(height: AppSpacing.base),
                        TextButton(
                          onPressed: service.skip,
                          child: Text(
                            t.update.later,
                            style: AppTextStyles.labelMd.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ],
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
