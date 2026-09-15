import 'package:flutter/material.dart';

import 'app_palette.dart';

export 'app_palette.dart';

/// Colour tokens, read from whichever [AppPalette] is current.
///
/// Every widget names its colours through here (`AppColors.primary`), and the
/// values are resolved at read time rather than compiled in — that is what
/// lets the whole app change between light and dark without each of the 80+
/// files that use these tokens knowing. The one rule that follows: nothing
/// that reads an `AppColors` value may be `const`, since a const would freeze
/// the colour of whichever theme was up when it was first built.
///
/// `ThemeController` is the only writer of [palette].
abstract class AppColors {
  /// Written only by `ThemeController`.
  static AppPalette palette = AppPalette.light;
  static AppPalette get _palette => palette;

  static bool get isDark => _palette.brightness == Brightness.dark;

  static Color get background => _palette.background;
  static Color get onBackground => _palette.onBackground;
  static Color get surface => _palette.surface;
  static Color get surfaceDim => _palette.surfaceDim;
  static Color get surfaceBright => _palette.surfaceBright;
  static Color get surfaceContainerLowest => _palette.surfaceContainerLowest;
  static Color get surfaceContainerLow => _palette.surfaceContainerLow;
  static Color get surfaceContainer => _palette.surfaceContainer;
  static Color get surfaceContainerHigh => _palette.surfaceContainerHigh;
  static Color get surfaceContainerHighest => _palette.surfaceContainerHighest;
  static Color get surfaceVariant => _palette.surfaceVariant;
  static Color get onSurface => _palette.onSurface;
  static Color get onSurfaceVariant => _palette.onSurfaceVariant;
  static Color get inverseSurface => _palette.inverseSurface;
  static Color get inverseOnSurface => _palette.inverseOnSurface;
  static Color get surfaceTint => _palette.surfaceTint;
  static Color get outline => _palette.outline;
  static Color get outlineVariant => _palette.outlineVariant;
  static Color get primary => _palette.primary;
  static Color get onPrimary => _palette.onPrimary;
  static Color get primaryContainer => _palette.primaryContainer;
  static Color get onPrimaryContainer => _palette.onPrimaryContainer;
  static Color get inversePrimary => _palette.inversePrimary;
  static Color get primaryFixed => _palette.primaryFixed;
  static Color get primaryFixedDim => _palette.primaryFixedDim;
  static Color get onPrimaryFixed => _palette.onPrimaryFixed;
  static Color get onPrimaryFixedVariant => _palette.onPrimaryFixedVariant;
  static Color get secondary => _palette.secondary;
  static Color get onSecondary => _palette.onSecondary;
  static Color get secondaryContainer => _palette.secondaryContainer;
  static Color get onSecondaryContainer => _palette.onSecondaryContainer;
  static Color get secondaryFixed => _palette.secondaryFixed;
  static Color get secondaryFixedDim => _palette.secondaryFixedDim;
  static Color get onSecondaryFixed => _palette.onSecondaryFixed;
  static Color get onSecondaryFixedVariant => _palette.onSecondaryFixedVariant;
  static Color get tertiary => _palette.tertiary;
  static Color get onTertiary => _palette.onTertiary;
  static Color get tertiaryContainer => _palette.tertiaryContainer;
  static Color get onTertiaryContainer => _palette.onTertiaryContainer;
  static Color get tertiaryFixed => _palette.tertiaryFixed;
  static Color get tertiaryFixedDim => _palette.tertiaryFixedDim;
  static Color get onTertiaryFixed => _palette.onTertiaryFixed;
  static Color get onTertiaryFixedVariant => _palette.onTertiaryFixedVariant;
  static Color get error => _palette.error;
  static Color get onError => _palette.onError;
  static Color get errorContainer => _palette.errorContainer;
  static Color get onErrorContainer => _palette.onErrorContainer;
  static Color get lavenderGlow => _palette.lavenderGlow;
  static Color get mintFresh => _palette.mintFresh;
  static Color get mutedIndigo => _palette.mutedIndigo;
  static Color get navDock => _palette.navDock;
  static Color get infoContainer => _palette.infoContainer;
  static Color get onInfoContainer => _palette.onInfoContainer;

  /// Tag colours per dietary preference, keyed by [DietaryPreference.name].
  /// Pairs are (container, onContainer) drawn from the palette above.
  static Map<String, (Color, Color)> get dietaryTagColors => {
        'meat': (errorContainer, onErrorContainer),
        'dairy': (infoContainer, onInfoContainer),
        'vegetarian': (secondaryContainer, onSecondaryContainer),
        'vegan': (secondaryFixedDim, onSecondaryFixed),
        'kosher': (tertiaryFixed, onTertiaryFixedVariant),
        'glutenFree': (primaryFixed, onPrimaryFixedVariant),
        'allergy': (surfaceContainerHighest, onSurfaceVariant),
      };
}
