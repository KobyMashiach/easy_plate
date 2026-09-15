import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../constants/app_text_styles.dart';
import '../../utils/i18n/strings.g.dart';
import '../../../features/my_recipes/domain/entities/nutrition_entity.dart';

/// The three macros, each with the colour every nutrition view uses for it,
/// so a bar on the recipe page and a slice on the dashboard mean the same
/// thing at a glance.
enum Macro {
  protein,
  carbs,
  fat
  ;

  Color get color => switch (this) {
    Macro.protein => AppColors.secondary,
    Macro.carbs => AppColors.tertiary,
    Macro.fat => AppColors.warmAccent,
  };

  String get label => switch (this) {
    Macro.protein => t.nutrition.protein,
    Macro.carbs => t.nutrition.carbs,
    Macro.fat => t.nutrition.fat,
  };

  double gramsOf(NutritionEntity n) => switch (this) {
    Macro.protein => n.proteinGrams,
    Macro.carbs => n.carbsGrams,
    Macro.fat => n.fatGrams,
  };

  double shareOf(NutritionEntity n) => switch (this) {
    Macro.protein => n.macroShares.protein,
    Macro.carbs => n.macroShares.carbs,
    Macro.fat => n.macroShares.fat,
  };
}

/// Text that shrinks to the room it has instead of wrapping or clipping:
/// one line, scaled down only when needed. For the tight rows in the
/// nutrition views, where a narrow phone would otherwise break a label.
class FitText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;

  const FitText(this.text, {super.key, this.style, this.textAlign});

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: textAlign == TextAlign.end
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: Text(text, maxLines: 1, style: style, textAlign: textAlign),
    );
  }
}

/// "42 ג׳" — whole grams, since a decimal on an estimate is false precision.
String gramsLabel(double grams) => '${grams.round()} ${t.nutrition.gramsShort}';

/// "1,247" with the locale's grouping, for calorie figures.
String kcalNumber(int kcal) {
  final digits = kcal.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return kcal < 0 ? '-$buffer' : buffer.toString();
}

/// One figure in a soft tile: an icon medallion, the number, its unit and a
/// caption. Four of these in a row are the recipe's "at a glance" strip.
class StatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String? unit;
  final String caption;

  /// Null reads as the theme's primary.
  final Color? color;

  const StatTile({
    super.key,
    required this.icon,
    required this.value,
    required this.caption,
    this.unit,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final accent = color ?? AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.sm,
        horizontal: AppSpacing.base,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.std),
        border: Border.all(color: AppColors.surfaceContainerHighest),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: accent),
          ),
          const SizedBox(height: AppSpacing.base),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text.rich(
              TextSpan(
                text: value,
                style: AppTextStyles.bodyLg.copyWith(
                  fontWeight: FontWeight.w800,
                  fontVariations: const [FontVariation('wght', 800)],
                ),
                children: [
                  if (unit != null)
                    TextSpan(
                      text: ' $unit',
                      style: AppTextStyles.labelSm.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
              maxLines: 1,
            ),
          ),
          FitText(
            caption,
            style: AppTextStyles.labelSm.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// A labelled macro bar: name and grams on one line, the fill below as the
/// macro's share of the calories.
class MacroBar extends StatelessWidget {
  final Macro macro;
  final NutritionEntity nutrition;

  const MacroBar({super.key, required this.macro, required this.nutrition});

  @override
  Widget build(BuildContext context) {
    final share = macro.shareOf(nutrition);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: macro.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpacing.base),
            Expanded(
              flex: 3,
              child: FitText(macro.label, style: AppTextStyles.labelMd),
            ),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              flex: 2,
              child: FitText(
                gramsLabel(macro.gramsOf(nutrition)),
                textAlign: TextAlign.end,
                style: AppTextStyles.labelMd.copyWith(
                  fontWeight: FontWeight.w800,
                  fontVariations: const [FontVariation('wght', 800)],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.base),
            SizedBox(
              width: 34,
              child: FitText(
                '${(share * 100).round()}%',
                textAlign: TextAlign.end,
                style: AppTextStyles.labelSm.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.full),
          child: SizedBox(
            height: 10,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ColoredBox(color: AppColors.surfaceContainerHigh),
                ),
                AnimatedFractionallySizedBox(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutCubic,
                  alignment: AlignmentDirectional.centerStart,
                  widthFactor: share.clamp(0.0, 1.0),
                  heightFactor: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: macro.color,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// A donut of the three macro shares with the calorie figure in the middle.
/// With nothing to split it draws an empty track, never a broken arc.
class MacroRing extends StatelessWidget {
  final NutritionEntity nutrition;
  final double size;
  final double thickness;

  /// Replaces the calorie figure in the centre when given.
  final Widget? center;

  const MacroRing({
    super.key,
    required this.nutrition,
    this.size = 132,
    this.thickness = 14,
    this.center,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
        builder: (context, progress, child) => CustomPaint(
          painter: _RingPainter(
            shares: [
              for (final m in Macro.values) (m.color, m.shareOf(nutrition)),
            ],
            track: AppColors.surfaceContainerHigh,
            thickness: thickness,
            progress: progress,
          ),
          child: child,
        ),
        child: Center(
          child:
              center ??
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    kcalNumber(nutrition.calories),
                    style: AppTextStyles.headlineMd.copyWith(
                      fontWeight: FontWeight.w800,
                      fontVariations: const [FontVariation('wght', 800)],
                    ),
                  ),
                  Text(
                    t.nutrition.kcal,
                    style: AppTextStyles.labelSm.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final List<(Color, double)> shares;
  final Color track;
  final double thickness;
  final double progress;

  const _RingPainter({
    required this.shares,
    required this.track,
    required this.thickness,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(thickness / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(arcRect, 0, math.pi * 2, false, paint..color = track);

    // A small gap between slices reads as separate values rather than one
    // striped ring; slices too thin to fit the gap are drawn without it.
    const gap = 0.06;
    var start = -math.pi / 2;
    for (final (color, share) in shares) {
      final sweep = math.pi * 2 * share * progress;
      if (sweep <= 0) continue;
      final trimmed = sweep > gap * 2 ? sweep - gap : sweep;
      final offset = sweep > gap * 2 ? gap / 2 : 0.0;
      canvas.drawArc(
        arcRect,
        start + offset,
        trimmed,
        false,
        paint..color = color,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.shares != shares || old.track != track;
}

/// Dot + name + grams, the legend under a ring.
class MacroLegend extends StatelessWidget {
  final NutritionEntity nutrition;

  const MacroLegend({super.key, required this.nutrition});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final macro in Macro.values)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: macro.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.base),
                Flexible(
                  child: FitText(macro.label, style: AppTextStyles.labelMd),
                ),
                const SizedBox(width: AppSpacing.base),
                Flexible(
                  child: FitText(
                    gramsLabel(macro.gramsOf(nutrition)),
                    style: AppTextStyles.labelMd.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                      fontVariations: const [FontVariation('wght', 800)],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// A ring with the three macro bars, always side by side. On a narrow
/// card the ring gives up some size and the bars' text scales down, so the
/// layout is the same on every phone — only smaller where it has to be.
class MacroRingWithBars extends StatelessWidget {
  final NutritionEntity nutrition;
  final double ringSize;
  final double thickness;

  const MacroRingWithBars({
    super.key,
    required this.nutrition,
    this.ringSize = 120,
    this.thickness = 12,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // The ring takes at most a third of the row; below that the bars
        // would have no room for their figures.
        final ring = math.min(ringSize, constraints.maxWidth * 0.34);
        final stroke = thickness * (ring / ringSize);
        return Row(
          children: [
            MacroRing(nutrition: nutrition, size: ring, thickness: stroke),
            const SizedBox(width: AppSpacing.gutter),
            Expanded(
              child: Column(
                children: [
                  for (final macro in Macro.values) ...[
                    MacroBar(macro: macro, nutrition: nutrition),
                    if (macro != Macro.values.last)
                      const SizedBox(height: AppSpacing.sm),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
