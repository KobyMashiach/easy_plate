import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_shadows.dart';
import '../../constants/app_spacing.dart';
import '../../constants/app_text_styles.dart';
import '../count_badge.dart';

class ClaySegment {
  final String label;
  final IconData icon;

  /// A count drawn on the icon's corner, for a tab with things waiting in
  /// it. Zero draws nothing.
  final int badge;

  const ClaySegment({required this.label, required this.icon, this.badge = 0});
}

/// Two or three choices on one recessed track, with a white clay pill that
/// slides to the selected one. Replaces the row of separate outlined tabs,
/// which read as unrelated buttons rather than one switch.
class ClaySegmentedControl extends StatelessWidget {
  final List<ClaySegment> segments;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const ClaySegmentedControl({
    super.key,
    required this.segments,
    required this.selectedIndex,
    required this.onSelected,
  }) : assert(segments.length >= 2, 'a switch needs at least two positions');

  @override
  Widget build(BuildContext context) {
    final count = segments.length;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: AppColors.surfaceContainerHighest),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth / count;
          return Stack(
            children: [
              AnimatedPositionedDirectional(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                start: width * selectedIndex,
                top: 0,
                bottom: 0,
                width: width,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    boxShadow: AppShadows.control,
                  ),
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < count; i++)
                    Expanded(
                      child: _SegmentLabel(
                        segment: segments[i],
                        selected: i == selectedIndex,
                        onTap: () => onSelected(i),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SegmentLabel extends StatelessWidget {
  final ClaySegment segment;
  final bool selected;
  final VoidCallback onTap;

  const _SegmentLabel({
    required this.segment,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.onSurfaceVariant;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm + 2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Flexible so the inner row is bounded and its label can
            // ellipsise: four segments on a narrow phone otherwise overflow.
            Flexible(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: AppTextStyles.labelMd.copyWith(color: color),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    BadgedBox(
                      count: segment.badge,
                      top: -7,
                      end: -9,
                      ringColor: selected
                          ? AppColors.surfaceContainerLowest
                          : AppColors.surfaceContainer,
                      child: Icon(segment.icon, size: 18, color: color),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Flexible(
                      child: Text(
                        segment.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
