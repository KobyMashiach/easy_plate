import 'package:flutter/material.dart';

/// One complete set of colour tokens. [light] mirrors the Stitch "EasyPlate
/// Claymorphic Design System" `namedColors` map one-to-one — do not hand-tune
/// it. [dark] is derived from the same key colours with Material 3's dark
/// tone mapping (primary 80, containers 30, surfaces on neutral 4–24), so the
/// hue family and the brand accents carry over unchanged. The one deliberate
/// departure from Material: the *Fixed* roles are not fixed here. The app
/// uses `primaryFixed` & co. as tinted backgrounds under `primary` ink, which
/// only reads while primary is dark — so in [dark] they take the container
/// tones (30/20) and their inks the light tones (90/80), and every such
/// surface keeps its contrast without a per-site edit.
///
/// Nothing reads a palette directly: `AppColors` exposes whichever one is
/// current, and `ThemeController` decides which that is.
class AppPalette {
  final Brightness brightness;
  final Color background;
  final Color onBackground;
  final Color surface;
  final Color surfaceDim;
  final Color surfaceBright;
  final Color surfaceContainerLowest;
  final Color surfaceContainerLow;
  final Color surfaceContainer;
  final Color surfaceContainerHigh;
  final Color surfaceContainerHighest;
  final Color surfaceVariant;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color inverseSurface;
  final Color inverseOnSurface;
  final Color surfaceTint;
  final Color outline;
  final Color outlineVariant;
  final Color primary;
  final Color onPrimary;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color inversePrimary;
  final Color primaryFixed;
  final Color primaryFixedDim;
  final Color onPrimaryFixed;
  final Color onPrimaryFixedVariant;
  final Color secondary;
  final Color onSecondary;
  final Color secondaryContainer;
  final Color onSecondaryContainer;
  final Color secondaryFixed;
  final Color secondaryFixedDim;
  final Color onSecondaryFixed;
  final Color onSecondaryFixedVariant;
  final Color tertiary;
  final Color onTertiary;
  final Color tertiaryContainer;
  final Color onTertiaryContainer;
  final Color tertiaryFixed;
  final Color tertiaryFixedDim;
  final Color onTertiaryFixed;
  final Color onTertiaryFixedVariant;
  final Color error;
  final Color onError;
  final Color errorContainer;
  final Color onErrorContainer;
  final Color lavenderGlow;
  final Color mintFresh;
  final Color mutedIndigo;
  final Color navDock;
  final Color infoContainer;
  final Color onInfoContainer;

  const AppPalette({
    required this.brightness,
    required this.background,
    required this.onBackground,
    required this.surface,
    required this.surfaceDim,
    required this.surfaceBright,
    required this.surfaceContainerLowest,
    required this.surfaceContainerLow,
    required this.surfaceContainer,
    required this.surfaceContainerHigh,
    required this.surfaceContainerHighest,
    required this.surfaceVariant,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.inverseSurface,
    required this.inverseOnSurface,
    required this.surfaceTint,
    required this.outline,
    required this.outlineVariant,
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.inversePrimary,
    required this.primaryFixed,
    required this.primaryFixedDim,
    required this.onPrimaryFixed,
    required this.onPrimaryFixedVariant,
    required this.secondary,
    required this.onSecondary,
    required this.secondaryContainer,
    required this.onSecondaryContainer,
    required this.secondaryFixed,
    required this.secondaryFixedDim,
    required this.onSecondaryFixed,
    required this.onSecondaryFixedVariant,
    required this.tertiary,
    required this.onTertiary,
    required this.tertiaryContainer,
    required this.onTertiaryContainer,
    required this.tertiaryFixed,
    required this.tertiaryFixedDim,
    required this.onTertiaryFixed,
    required this.onTertiaryFixedVariant,
    required this.error,
    required this.onError,
    required this.errorContainer,
    required this.onErrorContainer,
    required this.lavenderGlow,
    required this.mintFresh,
    required this.mutedIndigo,
    required this.navDock,
    required this.infoContainer,
    required this.onInfoContainer,
  });

  static const light = AppPalette(
    brightness: Brightness.light,
    background: Color(0xFFFCF8FF),
    onBackground: Color(0xFF181445),
    surface: Color(0xFFFCF8FF),
    surfaceDim: Color(0xFFDAD6FF),
    surfaceBright: Color(0xFFFCF8FF),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF6F2FF),
    surfaceContainer: Color(0xFFEFEBFF),
    surfaceContainerHigh: Color(0xFFE9E5FF),
    surfaceContainerHighest: Color(0xFFE3DFFF),
    surfaceVariant: Color(0xFFE3DFFF),
    onSurface: Color(0xFF181445),
    onSurfaceVariant: Color(0xFF484555),
    inverseSurface: Color(0xFF2D2A5B),
    inverseOnSurface: Color(0xFFF3EEFF),
    surfaceTint: Color(0xFF5D3FE0),
    outline: Color(0xFF797587),
    outlineVariant: Color(0xFFC9C4D8),
    primary: Color(0xFF5B3CDD),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFF7459F7),
    onPrimaryContainer: Color(0xFFFFFBFF),
    inversePrimary: Color(0xFFC9BFFF),
    primaryFixed: Color(0xFFE5DEFF),
    primaryFixedDim: Color(0xFFC9BFFF),
    onPrimaryFixed: Color(0xFF1A0063),
    onPrimaryFixedVariant: Color(0xFF441CC8),
    secondary: Color(0xFF006B5F),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFF62FAE3),
    onSecondaryContainer: Color(0xFF007165),
    secondaryFixed: Color(0xFF62FAE3),
    secondaryFixedDim: Color(0xFF3CDDC7),
    onSecondaryFixed: Color(0xFF00201C),
    onSecondaryFixedVariant: Color(0xFF005047),
    tertiary: Color(0xFF4651B9),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFF606AD4),
    onTertiaryContainer: Color(0xFFFFFBFF),
    tertiaryFixed: Color(0xFFE0E0FF),
    tertiaryFixedDim: Color(0xFFBDC2FF),
    onTertiaryFixed: Color(0xFF000767),
    onTertiaryFixedVariant: Color(0xFF2F3AA3),
    error: Color(0xFFBA1A1A),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF93000A),
    lavenderGlow: Color(0xFF7B61FF),
    mintFresh: Color(0xFF2DD4BF),
    mutedIndigo: Color(0xFF818CF8),
    navDock: Color(0xFF1E1E24),
    infoContainer: Color(0xFFD0E4FF),
    onInfoContainer: Color(0xFF001D36),
  );

  static const dark = AppPalette(
    brightness: Brightness.dark,
    background: Color(0xFF141318),
    onBackground: Color(0xFFE5E1E9),
    surface: Color(0xFF141318),
    surfaceDim: Color(0xFF141318),
    surfaceBright: Color(0xFF3A383E),
    surfaceContainerLowest: Color(0xFF0E0D13),
    surfaceContainerLow: Color(0xFF1C1B20),
    surfaceContainer: Color(0xFF201F25),
    surfaceContainerHigh: Color(0xFF2B292F),
    surfaceContainerHighest: Color(0xFF35343A),
    surfaceVariant: Color(0xFF484551),
    onSurface: Color(0xFFE5E1E9),
    onSurfaceVariant: Color(0xFFC9C4D3),
    inverseSurface: Color(0xFFE5E1E9),
    inverseOnSurface: Color(0xFF312F36),
    surfaceTint: Color(0xFFC9BFFF),
    outline: Color(0xFF938F9C),
    outlineVariant: Color(0xFF484551),
    primary: Color(0xFFC9BFFF),
    onPrimary: Color(0xFF2E009C),
    primaryContainer: Color(0xFF451CC8),
    onPrimaryContainer: Color(0xFFE5DEFF),
    inversePrimary: Color(0xFF5D3FDF),
    primaryFixed: Color(0xFF451CC8),
    primaryFixedDim: Color(0xFF2E009C),
    onPrimaryFixed: Color(0xFFE5DEFF),
    onPrimaryFixedVariant: Color(0xFFC9BFFF),
    secondary: Color(0xFF83D5C6),
    onSecondary: Color(0xFF003731),
    secondaryContainer: Color(0xFF005047),
    onSecondaryContainer: Color(0xFF9FF2E2),
    secondaryFixed: Color(0xFF005047),
    secondaryFixedDim: Color(0xFF003731),
    onSecondaryFixed: Color(0xFF9FF2E2),
    onSecondaryFixedVariant: Color(0xFF83D5C6),
    tertiary: Color(0xFFBDC2FF),
    onTertiary: Color(0xFF131F8C),
    tertiaryContainer: Color(0xFF2F3AA2),
    onTertiaryContainer: Color(0xFFDFE0FF),
    tertiaryFixed: Color(0xFF2F3AA2),
    tertiaryFixedDim: Color(0xFF131F8C),
    onTertiaryFixed: Color(0xFFDFE0FF),
    onTertiaryFixedVariant: Color(0xFFBDC2FF),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690004),
    errorContainer: Color(0xFF930009),
    onErrorContainer: Color(0xFFFFDAD5),
    lavenderGlow: Color(0xFF7B61FF),
    mintFresh: Color(0xFF2DD4BF),
    mutedIndigo: Color(0xFF818CF8),
    navDock: Color(0xFF3E3C44),
    infoContainer: Color(0xFF00497D),
    onInfoContainer: Color(0xFFD1E4FF),
  );
}
