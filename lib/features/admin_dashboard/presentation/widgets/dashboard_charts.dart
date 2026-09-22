import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';

/// One bar: its value and the label under it (blank for a day that gets no
/// tick — only a few days are labelled or the axis becomes a smear).
class BarDatum {
  final double value;
  final String label;
  final String tooltip;

  const BarDatum({
    required this.value,
    required this.label,
    required this.tooltip,
  });
}

/// A single-series bar chart in the design system's one hue. Thin marks
/// with rounded ends anchored to the baseline, two faint grid lines, and a
/// tap that shows the bar's value — the whole point of a chart on a phone.
/// The last bar is inked darker when [highlightLast] is set: it is today.
class ClayBarChart extends StatefulWidget {
  final List<BarDatum> data;
  final bool highlightLast;
  final double height;

  const ClayBarChart({
    super.key,
    required this.data,
    this.highlightLast = true,
    this.height = 150,
  });

  @override
  State<ClayBarChart> createState() => _ClayBarChartState();
}

class _ClayBarChartState extends State<ClayBarChart> {
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    if (data.isEmpty) return SizedBox(height: widget.height);
    final max = data.fold(0.0, (m, d) => math.max(m, d.value));
    final selected = _selected;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 22,
          child: selected == null
              ? null
              : Align(
                  alignment: Alignment.center,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.base,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.inverseSurface,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      data[selected].tooltip,
                      style: AppTextStyles.labelSm.copyWith(
                        color: AppColors.inverseOnSurface,
                      ),
                    ),
                  ),
                ),
        ),
        SizedBox(
          height: widget.height,
          child: LayoutBuilder(
            builder: (context, constraints) => GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) {
                final slot = constraints.maxWidth / data.length;
                final index = (details.localPosition.dx / slot).floor().clamp(
                  0,
                  data.length - 1,
                );
                // Reading order follows the text direction: the painter
                // mirrors the bars in RTL, so the tap is mirrored back.
                final rtl = Directionality.of(context) == TextDirection.rtl;
                setState(() {
                  final i = rtl ? data.length - 1 - index : index;
                  _selected = _selected == i ? null : i;
                });
              },
              child: CustomPaint(
                painter: _BarPainter(
                  data: data,
                  max: max,
                  selected: selected,
                  highlightLast: widget.highlightLast,
                  rtl: Directionality.of(context) == TextDirection.rtl,
                  bar: AppColors.primary,
                  barMuted: AppColors.primaryFixedDim,
                  grid: AppColors.outlineVariant,
                  labelStyle: AppTextStyles.labelSm.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
                size: Size.infinite,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BarPainter extends CustomPainter {
  final List<BarDatum> data;
  final double max;
  final int? selected;
  final bool highlightLast;
  final bool rtl;
  final Color bar;
  final Color barMuted;
  final Color grid;
  final TextStyle labelStyle;

  _BarPainter({
    required this.data,
    required this.max,
    required this.selected,
    required this.highlightLast,
    required this.rtl,
    required this.bar,
    required this.barMuted,
    required this.grid,
    required this.labelStyle,
  });

  static const _labelBand = 18.0;

  @override
  void paint(Canvas canvas, Size size) {
    final plotHeight = size.height - _labelBand;
    final baseline = plotHeight;
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    // Two recessive grid lines and the baseline.
    for (final f in [0.5, 1.0]) {
      final y = baseline - plotHeight * f * 0.92;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint..color = grid.withValues(alpha: 0.6),
      );
    }
    canvas.drawLine(
      Offset(0, baseline),
      Offset(size.width, baseline),
      gridPaint..color = grid,
    );

    final slot = size.width / data.length;
    final barWidth = (slot * 0.62).clamp(2.0, 22.0);
    final scale = max <= 0 ? 0.0 : (plotHeight * 0.92) / max;

    for (var i = 0; i < data.length; i++) {
      final d = data[i];
      final visual = rtl ? data.length - 1 - i : i;
      final left = visual * slot + (slot - barWidth) / 2;
      final h = d.value * scale;
      final isLast = i == data.length - 1;
      final paint = Paint()
        ..color = selected == i
            ? bar
            : (highlightLast && !isLast)
            ? barMuted
            : bar;
      if (h > 0) {
        final rect = RRect.fromRectAndCorners(
          Rect.fromLTWH(left, baseline - h, barWidth, h),
          topLeft: const Radius.circular(4),
          topRight: const Radius.circular(4),
        );
        canvas.drawRRect(rect, paint);
      } else {
        // A visible zero: a hairline stub so the day still reads as present.
        canvas.drawRect(
          Rect.fromLTWH(left, baseline - 1, barWidth, 1),
          paint..color = barMuted,
        );
      }
      if (d.label.isNotEmpty) {
        final tp = TextPainter(
          text: TextSpan(text: d.label, style: labelStyle),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(
          canvas,
          Offset(left + barWidth / 2 - tp.width / 2, baseline + 4),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_BarPainter old) =>
      old.data != data ||
      old.selected != selected ||
      old.max != max ||
      old.bar != bar ||
      old.rtl != rtl;
}

/// One slice of a donut: label, value, and the colour it was assigned in
/// fixed order.
class DonutSlice {
  final String label;
  final double value;

  const DonutSlice({required this.label, required this.value});
}

/// A donut with its legend beside it: the legend carries label, value and
/// share, so identity is never colour alone. Hues come in a fixed order
/// from the palette, never generated.
class ClayDonutChart extends StatelessWidget {
  final List<DonutSlice> slices;
  final String Function(double value) format;
  final double size;

  const ClayDonutChart({
    super.key,
    required this.slices,
    required this.format,
    this.size = 112,
  });

  static List<Color> palette() => [
    AppColors.primary,
    AppColors.secondary,
    AppColors.tertiary,
    AppColors.warmAccent,
    AppColors.mutedIndigo,
    AppColors.primaryFixedDim,
    AppColors.secondaryFixedDim,
    AppColors.tertiaryFixedDim,
  ];

  @override
  Widget build(BuildContext context) {
    final colors = palette();
    final total = slices.fold(0.0, (s, x) => s + x.value);
    final shown = slices.where((s) => s.value > 0).toList();
    return Row(
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _DonutPainter(
              values: [for (final s in shown) s.value],
              colors: [
                for (var i = 0; i < shown.length; i++)
                  colors[slices.indexOf(shown[i]) % colors.length],
              ],
              ring: AppColors.surfaceContainerLowest,
              empty: AppColors.surfaceContainerHighest,
            ),
            child: Center(
              child: Text(
                format(total),
                style: AppTextStyles.labelMd.copyWith(
                  color: AppColors.onSurface,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.gutter),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < slices.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: colors[i % colors.length],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.base),
                      Expanded(
                        child: Text(
                          slices[i].label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.labelMd,
                        ),
                      ),
                      Text(
                        total == 0
                            ? format(slices[i].value)
                            : '${format(slices[i].value)} · ${(slices[i].value / total * 100).round()}%',
                        textDirection: TextDirection.ltr,
                        style: AppTextStyles.labelSm.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;
  final Color ring;
  final Color empty;

  _DonutPainter({
    required this.values,
    required this.colors,
    required this.ring,
    required this.empty,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final stroke = size.width * 0.2;
    final total = values.fold(0.0, (a, b) => a + b);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    final inner = rect.deflate(stroke / 2);
    if (total <= 0) {
      canvas.drawArc(inner, 0, math.pi * 2, false, paint..color = empty);
      return;
    }
    var start = -math.pi / 2;
    // A 2px surface gap between fills, drawn as a slightly wider ring
    // underneath each slice's end.
    for (var i = 0; i < values.length; i++) {
      final sweep = values[i] / total * math.pi * 2;
      canvas.drawArc(inner, start, sweep, false, paint..color = colors[i]);
      start += sweep;
    }
    if (values.length > 1) {
      start = -math.pi / 2;
      final gap = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke + 2
        ..color = ring;
      for (final v in values) {
        final sweep = v / total * math.pi * 2;
        final angle = start;
        final c = rect.center;
        final r = inner.width / 2;
        canvas.drawLine(
          c + Offset(math.cos(angle), math.sin(angle)) * (r - stroke / 2 - 1),
          c + Offset(math.cos(angle), math.sin(angle)) * (r + stroke / 2 + 1),
          gap..strokeWidth = 2,
        );
        start += sweep;
      }
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.values != values || old.colors != colors;
}
