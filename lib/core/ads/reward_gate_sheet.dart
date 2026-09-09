import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_text_styles.dart';
import '../monetization/monetization_config.dart';
import '../utils/i18n/strings.g.dart';
import '../widgets/clay/clay.dart';
import 'rewarded_ad_service.dart';

/// Asks the user to watch a rewarded video, plays it, and says whether the
/// unlock was earned.
///
/// True means "open it". That is the case after a completed video, and also
/// when no video could be served while `ads_fail_open` is on — see
/// [MonetizationConfig.failOpen] for why the user is not the one to refuse
/// in that case. A video closed early is a plain false, with a snackbar.
Future<bool> showRewardGateSheet(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  final outcome = await showModalBottomSheet<RewardOutcome>(
    context: context,
    isDismissible: true,
    backgroundColor: AppColors.surfaceContainerLowest,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.md)),
    ),
    builder: (_) => _RewardGateSheet(title: title, message: message),
  );

  if (!context.mounted) return false;
  switch (outcome) {
    case RewardOutcome.earned:
      return true;
    case RewardOutcome.dismissed:
      _notify(context, t.ads.videoNotCompleted);
      return false;
    case RewardOutcome.unavailable:
      if (MonetizationConfig.failOpen) return true;
      _notify(context, t.ads.videoUnavailable);
      return false;
    case null:
      return false;
  }
}

void _notify(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message, style: AppTextStyles.bodyMd)),
  );
}

class _RewardGateSheet extends StatefulWidget {
  final String title;
  final String message;

  const _RewardGateSheet({required this.title, required this.message});

  @override
  State<_RewardGateSheet> createState() => _RewardGateSheetState();
}

class _RewardGateSheetState extends State<_RewardGateSheet> {
  bool _playing = false;

  Future<void> _watch() async {
    setState(() => _playing = true);
    final outcome = await RewardedAdService().show();
    if (!mounted) return;
    Navigator.of(context).pop(outcome);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.primaryFixed,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_circle_rounded,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.gutter),
            Text(widget.title, textAlign: TextAlign.center, style: AppTextStyles.headlineMd),
            const SizedBox(height: AppSpacing.base),
            Text(
              widget.message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.md),
            if (_playing)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      t.ads.loadingVideo,
                      style: AppTextStyles.labelMd.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              )
            else ...[
              ClayButton(
                label: t.ads.watchVideo,
                icon: Icons.play_arrow_rounded,
                expanded: true,
                onPressed: _watch,
              ),
              const SizedBox(height: AppSpacing.xs),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  t.common.cancel,
                  style: AppTextStyles.labelMd.copyWith(color: AppColors.tertiary),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
