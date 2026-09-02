import 'package:flutter/material.dart';

/// Colour tokens synchronised from the Stitch "EasyPlate Claymorphic Design
/// System" (project 7084543715612353080). Values here mirror the Stitch
/// `namedColors` map one-to-one — do not hand-tune them.
abstract class AppColors {
  // Surfaces
  static const background = Color(0xFFFCF8FF);
  static const onBackground = Color(0xFF181445);
  static const surface = Color(0xFFFCF8FF);
  static const surfaceDim = Color(0xFFDAD6FF);
  static const surfaceBright = Color(0xFFFCF8FF);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFF6F2FF);
  static const surfaceContainer = Color(0xFFEFEBFF);
  static const surfaceContainerHigh = Color(0xFFE9E5FF);
  static const surfaceContainerHighest = Color(0xFFE3DFFF);
  static const surfaceVariant = Color(0xFFE3DFFF);
  static const onSurface = Color(0xFF181445);
  static const onSurfaceVariant = Color(0xFF484555);
  static const inverseSurface = Color(0xFF2D2A5B);
  static const inverseOnSurface = Color(0xFFF3EEFF);
  static const surfaceTint = Color(0xFF5D3FE0);

  // Outlines
  static const outline = Color(0xFF797587);
  static const outlineVariant = Color(0xFFC9C4D8);

  // Primary
  static const primary = Color(0xFF5B3CDD);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFF7459F7);
  static const onPrimaryContainer = Color(0xFFFFFBFF);
  static const inversePrimary = Color(0xFFC9BFFF);
  static const primaryFixed = Color(0xFFE5DEFF);
  static const primaryFixedDim = Color(0xFFC9BFFF);
  static const onPrimaryFixed = Color(0xFF1A0063);
  static const onPrimaryFixedVariant = Color(0xFF441CC8);

  // Secondary
  static const secondary = Color(0xFF006B5F);
  static const onSecondary = Color(0xFFFFFFFF);
  static const secondaryContainer = Color(0xFF62FAE3);
  static const onSecondaryContainer = Color(0xFF007165);
  static const secondaryFixed = Color(0xFF62FAE3);
  static const secondaryFixedDim = Color(0xFF3CDDC7);
  static const onSecondaryFixed = Color(0xFF00201C);
  static const onSecondaryFixedVariant = Color(0xFF005047);

  // Tertiary
  static const tertiary = Color(0xFF4651B9);
  static const onTertiary = Color(0xFFFFFFFF);
  static const tertiaryContainer = Color(0xFF606AD4);
  static const onTertiaryContainer = Color(0xFFFFFBFF);
  static const tertiaryFixed = Color(0xFFE0E0FF);
  static const tertiaryFixedDim = Color(0xFFBDC2FF);
  static const onTertiaryFixed = Color(0xFF000767);
  static const onTertiaryFixedVariant = Color(0xFF2F3AA3);

  // Error
  static const error = Color(0xFFBA1A1A);
  static const onError = Color(0xFFFFFFFF);
  static const errorContainer = Color(0xFFFFDAD6);
  static const onErrorContainer = Color(0xFF93000A);

  /// Brand anchors called out in the Stitch style guidelines. [lavenderGlow]
  /// tints every claymorphic shadow; [mintFresh] marks success/health states.
  static const lavenderGlow = Color(0xFF7B61FF);
  static const mintFresh = Color(0xFF2DD4BF);
  static const mutedIndigo = Color(0xFF818CF8);

  /// Floating navigation dock: near-black glass at 90% opacity.
  static const navDock = Color(0xFF1E1E24);

  /// Info accent used by the "Gluten-Free" style tags in the Stitch meal cards.
  static const infoContainer = Color(0xFFD0E4FF);
  static const onInfoContainer = Color(0xFF001D36);

  /// Tag colours per dietary preference, keyed by [DietaryPreference.name].
  /// Pairs are (container, onContainer) drawn from the palette above.
  static const dietaryTagColors = <String, (Color, Color)>{
    'meat': (errorContainer, onErrorContainer),
    'dairy': (infoContainer, onInfoContainer),
    'vegetarian': (secondaryContainer, onSecondaryContainer),
    'vegan': (secondaryFixedDim, onSecondaryFixed),
    'kosher': (tertiaryFixed, onTertiaryFixedVariant),
    'glutenFree': (primaryFixed, onPrimaryFixedVariant),
    'allergy': (surfaceContainerHighest, onSurfaceVariant),
  };
}
