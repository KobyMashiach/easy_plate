/// Spacing scale synchronised from the Stitch design system. All internal
/// padding is a multiple of the 8px [base] rhythm.
abstract class AppSpacing {
  /// xs = 4.0
  static const xs = 4.0;

  /// base = 8.0
  static const base = 8.0;

  /// sm = 12.0
  static const sm = 12.0;

  /// gutter = 16.0
  static const gutter = 16.0;

  /// marginMobile = 20.0
  static const marginMobile = 20.0;

  /// md = 24.0
  static const md = 24.0;

  /// lg = 32.0
  static const lg = 32.0;

  /// marginDesktop = 40.0
  static const marginDesktop = 40.0;

  /// xl = 48.0
  static const xl = 48.0;
}

/// Corner radii from the Stitch `rounded` scale. The shape language is
/// "Super-Rounded" — interactive elements use [full], never a sharp corner.
abstract class AppRadius {
  /// sm = 8.0
  static const sm = 8.0;

  /// std = 16.0
  static const std = 16.0;

  /// md = 24.0
  static const md = 24.0;

  /// lg = 32.0
  static const lg = 32.0;

  /// xl = 48.0
  static const xl = 48.0;

  /// full = 9999.0
  static const full = 9999.0;
}
