import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../constants/app_text_styles.dart';
import 'clay_section.dart';

/// A page whose title block behaves like a floating app bar: it slides away
/// as the list scrolls down and comes straight back as soon as the list
/// scrolls up a little, not only at the top. The page's own action stays
/// put the whole time, drawn over the list at the header's corner.
///
/// [trailingWidth] is the width the action takes, so the title wraps short
/// of it — the action is not inside the header, since it must not scroll
/// away with it.
class ClayFloatingHeaderView extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final double trailingWidth;

  /// The space between the header and the first sliver.
  final double bottomGap;
  final List<Widget> slivers;
  final ScrollController? controller;
  final ScrollPhysics? physics;

  const ClayFloatingHeaderView({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.trailingWidth = 48,
    this.bottomGap = AppSpacing.md,
    required this.slivers,
    this.controller,
    this.physics,
  });

  /// The action sits where it would inside a [ClayPageHeader]: on the title
  /// line, a hair below the top edge.
  static const double actionTop = AppSpacing.md + AppSpacing.xs;

  double _endInset() => trailing == null ? 0 : trailingWidth + AppSpacing.sm;

  /// The header's extent has to be known before it lays out, so its text is
  /// measured for the width it will get.
  double _extent(BuildContext context, double width) {
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    double heightOf(String text, TextStyle style) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: direction,
        textScaler: scaler,
      )..layout(maxWidth: width);
      final height = painter.height;
      painter.dispose();
      return height;
    }

    var total = AppSpacing.md + heightOf(title, AppTextStyles.headlineLgMobile);
    if (subtitle case final subtitle?) {
      total += AppSpacing.base + heightOf(subtitle, AppTextStyles.bodyMd);
    }
    return total + bottomGap;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final endInset = _endInset();
        final textWidth =
            (constraints.maxWidth - 2 * AppSpacing.marginMobile - endInset)
                .clamp(0.0, double.infinity);
        final extent = _extent(context, textWidth);
        return Stack(
          children: [
            CustomScrollView(
              controller: controller,
              physics: physics,
              slivers: [
                SliverPersistentHeader(
                  floating: true,
                  delegate: _FloatingHeaderDelegate(
                    title: title,
                    subtitle: subtitle,
                    extent: extent,
                    endInset: endInset,
                    bottomGap: bottomGap,
                    background: AppColors.background,
                  ),
                ),
                ...slivers,
              ],
            ),
            if (trailing case final trailing?)
              PositionedDirectional(
                top: actionTop,
                end: AppSpacing.marginMobile,
                child: trailing,
              ),
          ],
        );
      },
    );
  }
}

class _FloatingHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String title;
  final String? subtitle;
  final double extent;
  final double endInset;
  final double bottomGap;
  final Color background;

  const _FloatingHeaderDelegate({
    required this.title,
    required this.subtitle,
    required this.extent,
    required this.endInset,
    required this.bottomGap,
    required this.background,
  });

  @override
  double get minExtent => extent;
  @override
  double get maxExtent => extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    // Opaque: when the header floats back over the list, the rows must not
    // show through it.
    return ColoredBox(
      color: background,
      child: Padding(
        padding: EdgeInsetsDirectional.only(
          start: AppSpacing.marginMobile,
          end: AppSpacing.marginMobile + endInset,
          top: AppSpacing.md,
          bottom: bottomGap,
        ),
        child: Align(
          alignment: AlignmentDirectional.topStart,
          child: ClayPageHeader(title: title, subtitle: subtitle),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_FloatingHeaderDelegate old) =>
      old.title != title ||
      old.subtitle != subtitle ||
      old.extent != extent ||
      old.endInset != endInset ||
      old.bottomGap != bottomGap ||
      old.background != background;
}
