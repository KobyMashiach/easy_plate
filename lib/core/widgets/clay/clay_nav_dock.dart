import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_shadows.dart';
import '../../constants/app_spacing.dart';
import '../../constants/app_text_styles.dart';

class ClayNavDestination {
  final IconData icon;
  final String label;

  const ClayNavDestination({required this.icon, required this.label});
}

/// Capsule-shaped dark glass bar floating above the content, with a 20px
/// backdrop blur. The active destination scales up and switches to mint.
class ClayNavDock extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final List<ClayNavDestination> destinations;

  /// The dock's own height (its padding, an icon and a label) plus its bottom
  /// margin and a little air: what a page has to keep clear at the bottom
  /// before the system's own inset is counted.
  static const reservedHeight = 96.0;

  /// A floating action button's height plus the gap that keeps it off the
  /// last card, for pages that carry one above the dock.
  static const fabClearance = 56.0 + AppSpacing.gutter;

  /// Bottom padding for a page under the dock, so its last item scrolls all
  /// the way out from under it. On Android the dock floats above the gesture
  /// bar (see [MainNavBar]), so that inset is added; on iOS the dock's own
  /// margin already covers the home indicator. [withFab] adds room for a
  /// button floating above the dock, which would otherwise sit on the last
  /// card once the list is scrolled to its end.
  static double bottomPadding(BuildContext context, {bool withFab = false}) {
    final inset = defaultTargetPlatform == TargetPlatform.android
        ? MediaQuery.paddingOf(context).bottom
        : 0.0;
    return reservedHeight + inset + (withFab ? fabClearance : 0);
  }

  const ClayNavDock({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    required this.destinations,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.marginMobile,
        0,
        AppSpacing.marginMobile,
        AppSpacing.md,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: DecoratedBox(
            decoration: ShapeDecoration(
              color: AppColors.navDock.withValues(alpha: 0.9),
              shape: const StadiumBorder(),
              shadows: AppShadows.dock,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  for (var i = 0; i < destinations.length; i++)
                    _DockItem(
                      destination: destinations[i],
                      isActive: i == selectedIndex,
                      onTap: () => onSelected(i),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DockItem extends StatelessWidget {
  final ClayNavDestination destination;
  final bool isActive;
  final VoidCallback onTap;

  const _DockItem({
    required this.destination,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive
        ? AppColors.secondaryFixed
        : AppColors.surfaceVariant.withValues(alpha: 0.6);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          scale: isActive ? 1.1 : 1,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          child: Padding(
            // Horizontal breathing room so neighbouring labels ellipsize into
            // a gap instead of running together.
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(destination.icon, size: 22, color: color),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  destination.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.labelSm.copyWith(color: color, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
