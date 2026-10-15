import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_motion.dart';
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

/// Two to five choices on one recessed track, with a white clay pill that
/// slides to the selected one. Replaces the row of separate outlined tabs,
/// which read as unrelated buttons rather than one switch.
///
/// Only the selected segment shows its label; the others show their icon
/// alone and share what is left of the width. Equal widths with every label
/// ellipsised ("משת…", "חסו…") on a phone with four segments, so the label
/// now goes only where it is read. The icon-only segments keep their label
/// for screen readers and as a long-press tooltip.
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

  static const _iconSize = 18.0;

  /// The label unfolds from the icon (and folds back) in half a second,
  /// in step with the pill and the widths, so the three read as one move.
  static const reveal = Duration(milliseconds: 500);
  static const _hPad = AppSpacing.sm;

  /// The narrowest an icon-only segment gets.
  static const _iconOnly = _iconSize + 2 * _hPad;

  /// Widths for each segment: the selected one as wide as its icon and label
  /// (capped so the others keep at least an icon's room), the rest equal.
  /// Pure, for tests.
  @visibleForTesting
  static List<double> widthsFor({
    required double available,
    required int count,
    required int selected,
    required double labelWidth,
  }) {
    final wanted = _iconSize + AppSpacing.xs + labelWidth + 2 * _hPad + 2;
    final cap = available - (count - 1) * _iconOnly;
    final chosen = wanted.clamp(available / count, cap > 0 ? cap : available);
    final rest = (available - chosen) / (count - 1);
    return [for (var i = 0; i < count; i++) i == selected ? chosen : rest];
  }

  @override
  Widget build(BuildContext context) {
    final count = segments.length;
    final selected = selectedIndex.clamp(0, count - 1);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: AppColors.surfaceContainerHighest),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final painter = TextPainter(
            text: TextSpan(
              text: segments[selected].label,
              style: AppTextStyles.labelMd,
            ),
            maxLines: 1,
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
          )..layout();
          final widths = widthsFor(
            available: constraints.maxWidth,
            count: count,
            selected: selected,
            labelWidth: painter.width,
          );
          painter.dispose();
          var start = 0.0;
          for (var i = 0; i < selected; i++) {
            start += widths[i];
          }
          final duration = AppMotion.move(context, reveal);
          return Stack(
            children: [
              AnimatedPositionedDirectional(
                duration: duration,
                curve: AppMotion.easeOut,
                start: start,
                top: 0,
                bottom: 0,
                width: widths[selected],
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
                    AnimatedContainer(
                      duration: duration,
                      curve: AppMotion.easeOut,
                      width: widths[i],
                      child: _SegmentLabel(
                        segment: segments[i],
                        selected: i == selected,
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

class _SegmentLabel extends StatefulWidget {
  final ClaySegment segment;
  final bool selected;
  final VoidCallback onTap;

  const _SegmentLabel({
    required this.segment,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_SegmentLabel> createState() => _SegmentLabelState();
}

/// The label lives beside the icon on the reading-start side (right in
/// Hebrew, left in English) and unfolds outward from the icon when the
/// segment is selected, folding back into it when another one is.
class _SegmentLabelState extends State<_SegmentLabel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: ClaySegmentedControl.reveal,
    value: widget.selected ? 1 : 0,
  );
  late final Animation<double> _size = CurvedAnimation(
    parent: _reveal,
    curve: AppMotion.easeOut,
    reverseCurve: AppMotion.easeOut.flipped,
  );

  @override
  void didUpdateWidget(_SegmentLabel old) {
    super.didUpdateWidget(old);
    if (old.selected == widget.selected) return;
    _reveal.duration = AppMotion.move(context, ClaySegmentedControl.reveal);
    widget.selected ? _reveal.forward() : _reveal.reverse();
  }

  @override
  void dispose() {
    _reveal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    final segment = widget.segment;
    final color = selected ? AppColors.primary : AppColors.onSurfaceVariant;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final icon = BadgedBox(
      count: segment.badge,
      top: -7,
      end: -9,
      ringColor: selected
          ? AppColors.surfaceContainerLowest
          : AppColors.surfaceContainer,
      child: Icon(
        segment.icon,
        size: ClaySegmentedControl._iconSize,
        color: color,
      ),
    );

    // Anchored on the edge that touches the icon, so the text grows away
    // from it: the label's left edge in Hebrew, its right edge in English.
    final label = Flexible(
      child: SizeTransition(
        sizeFactor: _size,
        axis: Axis.horizontal,
        axisAlignment: rtl ? -1 : 1,
        child: FadeTransition(
          opacity: _size,
          child: Padding(
            padding: const EdgeInsetsDirectional.only(end: AppSpacing.xs),
            child: Text(
              segment.label,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.fade,
              style: AppTextStyles.labelMd.copyWith(color: color),
            ),
          ),
        ),
      ),
    );

    final content = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ClaySegmentedControl._hPad,
        vertical: AppSpacing.sm + 2,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [label, icon],
      ),
    );

    return Semantics(
      button: true,
      selected: selected,
      label: segment.label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        // The hidden label is a long press away.
        child: selected
            ? content
            : Tooltip(message: segment.label, child: content),
      ),
    );
  }
}
