import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Elevation tokens from the Stitch design system. Depth is the defining
/// characteristic of this system: a lavender-tinted outer shadow lifts a
/// surface off the background, and a light inner bevel makes it read as
/// inflated clay rather than a flat rectangle.
///
/// Flutter has no inset [BoxShadow], so the "inner glow" layers from the Stitch
/// CSS are approximated with a hairline top-left highlight border on clay
/// surfaces (see `ClayCard`) rather than a shadow.
abstract class AppShadows {
  /// `0px 12px 32px rgba(123, 97, 255, 0.08)` — the standard card lift.
  static final card = [
    BoxShadow(
      color: AppColors.lavenderGlow.withValues(alpha: 0.08),
      blurRadius: 32,
      offset: const Offset(0, 12),
    ),
  ];

  /// `8px 16px 32px rgba(123, 97, 255, 0.12)` — heavier, for book covers.
  static final book = [
    BoxShadow(
      color: AppColors.lavenderGlow.withValues(alpha: 0.12),
      blurRadius: 32,
      offset: const Offset(8, 16),
    ),
  ];

  /// `0px 8px 24px rgba(91, 60, 221, 0.25)` — primary button glow. The 3D
  /// extrusion beneath it is drawn as a solid border, not a shadow.
  static final button = [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.25),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  /// `0px 8px 24px rgba(116, 89, 247, 0.3)` — selected/active clay surface.
  static final active = [
    BoxShadow(
      color: AppColors.primaryContainer.withValues(alpha: 0.3),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  /// `0px 12px 32px rgba(123, 97, 255, 0.2)` — the floating navigation dock.
  static final dock = [
    BoxShadow(
      color: AppColors.lavenderGlow.withValues(alpha: 0.2),
      blurRadius: 32,
      offset: const Offset(0, 12),
    ),
  ];

  /// The top-left highlight that fakes the beveled "inflated" clay edge.
  static const bevelHighlight = Color(0x99FFFFFF);

  /// Depth of the 3D extrusion under pressable clay buttons.
  static const buttonThickness = 4.0;
}
