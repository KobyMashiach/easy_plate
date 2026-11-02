import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_text_styles.dart';
import '../utils/i18n/strings.g.dart';

/// A one-line nudge on screens full of inputs — "works better sideways" —
/// with the rotate button that actually turns the screen. The app is
/// portrait everywhere else, so whatever this unlocks is locked again when
/// the last screen carrying a hint goes away.
///
/// Screens with a hint stack (the review after adding a recipe opens the
/// editor), so the button reads the orientation on screen rather than its
/// own memory, and only the last hint to leave locks portrait again.
class LandscapeHint extends StatefulWidget {
  const LandscapeHint({super.key});

  @override
  State<LandscapeHint> createState() => _LandscapeHintState();
}

// Kept alive while scrolled out of view: the hint lives inside the screen's
// list, and a disposed item would re-lock portrait the moment the user
// scrolled past it — which is exactly when they are working sideways.
class _LandscapeHintState extends State<LandscapeHint>
    with AutomaticKeepAliveClientMixin {
  /// Hints alive right now, across stacked screens.
  static int _alive = 0;

  /// Whether a hint turned the screen sideways and it is still unlocked.
  static bool _unlocked = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _alive++;
  }

  Future<void> _toggle(bool landscape) async {
    _unlocked = !landscape;
    await SystemChrome.setPreferredOrientations(
      _unlocked
          ? const [
              DeviceOrientation.landscapeLeft,
              DeviceOrientation.landscapeRight,
            ]
          : const [DeviceOrientation.portraitUp],
    );
  }

  @override
  void dispose() {
    _alive--;
    if (_alive == 0 && _unlocked) {
      _unlocked = false;
      SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.portraitUp,
      ]);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final landscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryFixed,
        borderRadius: BorderRadius.circular(AppRadius.std),
      ),
      child: Row(
        children: [
          Icon(
            Icons.screen_rotation_rounded,
            size: 18,
            color: AppColors.onPrimaryFixedVariant,
          ),
          const SizedBox(width: AppSpacing.base),
          Expanded(
            child: Text(
              t.common.landscapeHint,
              style: AppTextStyles.labelMd.copyWith(
                color: AppColors.onPrimaryFixed,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: () => _toggle(landscape),
            icon: Icon(
              landscape
                  ? Icons.stay_current_portrait_rounded
                  : Icons.stay_current_landscape_rounded,
              size: 18,
            ),
            label: Text(
              landscape ? t.common.rotatePortrait : t.common.rotateLandscape,
            ),
          ),
        ],
      ),
    );
  }
}
