import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Type scale synchronised from the Stitch design system. Sizes, weights,
/// line heights and tracking mirror the Stitch `typography` map exactly.
///
/// Plus Jakarta Sans ships as a variable font, so each style pins the `wght`
/// axis alongside [TextStyle.fontWeight] — without the axis the renderer would
/// draw every weight at the font's default instance.
abstract class AppTextStyles {
  static const fontFamily = 'Plus Jakarta Sans';

  /// Plus Jakarta Sans covers Latin only. Hebrew, Arabic and Cyrillic glyphs
  /// resolve through the platform families below instead of rendering as tofu.
  static const fontFamilyFallback = [
    'SF Hebrew',
    'Arial Hebrew',
    'Geeza Pro',
    'Noto Sans Arabic',
    'Noto Sans Hebrew',
    'Roboto',
  ];

  static TextStyle _style({
    required double size,
    required int weight,
    required double lineHeight,
    double? letterSpacing,
    Color color = AppColors.onSurface,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontFamilyFallback: fontFamilyFallback,
      fontSize: size,
      fontWeight: FontWeight.values[weight ~/ 100 - 1],
      fontVariations: [FontVariation('wght', weight.toDouble())],
      height: lineHeight / size,
      letterSpacing: letterSpacing == null ? null : letterSpacing * size,
      color: color,
    );
  }

  static final displayLg = _style(size: 40, weight: 800, lineHeight: 48, letterSpacing: -0.02);
  static final headlineLg = _style(size: 32, weight: 700, lineHeight: 40, letterSpacing: -0.01);
  static final headlineLgMobile = _style(size: 28, weight: 700, lineHeight: 36);
  static final headlineMd = _style(size: 24, weight: 700, lineHeight: 32);
  static final bodyLg = _style(size: 18, weight: 500, lineHeight: 28);
  static final bodyMd = _style(size: 16, weight: 500, lineHeight: 24);
  static final labelMd = _style(size: 14, weight: 600, lineHeight: 20, letterSpacing: 0.01);
  static final labelSm = _style(size: 12, weight: 700, lineHeight: 16, letterSpacing: 0.03);
}
