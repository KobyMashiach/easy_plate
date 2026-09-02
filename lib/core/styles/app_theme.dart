import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_text_styles.dart';

/// Material theme built entirely from the Stitch design tokens. Widgets should
/// read from this theme (or the `AppColors`/`AppTextStyles`/`AppSpacing`
/// tokens) rather than declaring their own colours or sizes.
abstract class AppTheme {
  static const _colorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    primaryContainer: AppColors.primaryContainer,
    onPrimaryContainer: AppColors.onPrimaryContainer,
    primaryFixed: AppColors.primaryFixed,
    primaryFixedDim: AppColors.primaryFixedDim,
    onPrimaryFixed: AppColors.onPrimaryFixed,
    onPrimaryFixedVariant: AppColors.onPrimaryFixedVariant,
    secondary: AppColors.secondary,
    onSecondary: AppColors.onSecondary,
    secondaryContainer: AppColors.secondaryContainer,
    onSecondaryContainer: AppColors.onSecondaryContainer,
    secondaryFixed: AppColors.secondaryFixed,
    secondaryFixedDim: AppColors.secondaryFixedDim,
    onSecondaryFixed: AppColors.onSecondaryFixed,
    onSecondaryFixedVariant: AppColors.onSecondaryFixedVariant,
    tertiary: AppColors.tertiary,
    onTertiary: AppColors.onTertiary,
    tertiaryContainer: AppColors.tertiaryContainer,
    onTertiaryContainer: AppColors.onTertiaryContainer,
    tertiaryFixed: AppColors.tertiaryFixed,
    tertiaryFixedDim: AppColors.tertiaryFixedDim,
    onTertiaryFixed: AppColors.onTertiaryFixed,
    onTertiaryFixedVariant: AppColors.onTertiaryFixedVariant,
    error: AppColors.error,
    onError: AppColors.onError,
    errorContainer: AppColors.errorContainer,
    onErrorContainer: AppColors.onErrorContainer,
    surface: AppColors.surface,
    onSurface: AppColors.onSurface,
    surfaceDim: AppColors.surfaceDim,
    surfaceBright: AppColors.surfaceBright,
    surfaceContainerLowest: AppColors.surfaceContainerLowest,
    surfaceContainerLow: AppColors.surfaceContainerLow,
    surfaceContainer: AppColors.surfaceContainer,
    surfaceContainerHigh: AppColors.surfaceContainerHigh,
    surfaceContainerHighest: AppColors.surfaceContainerHighest,
    onSurfaceVariant: AppColors.onSurfaceVariant,
    outline: AppColors.outline,
    outlineVariant: AppColors.outlineVariant,
    inverseSurface: AppColors.inverseSurface,
    onInverseSurface: AppColors.inverseOnSurface,
    inversePrimary: AppColors.inversePrimary,
    surfaceTint: AppColors.surfaceTint,
  );

  static final _textTheme = TextTheme(
    displayLarge: AppTextStyles.displayLg,
    displayMedium: AppTextStyles.headlineLg,
    displaySmall: AppTextStyles.headlineLgMobile,
    headlineLarge: AppTextStyles.headlineLg,
    headlineMedium: AppTextStyles.headlineLgMobile,
    headlineSmall: AppTextStyles.headlineMd,
    titleLarge: AppTextStyles.headlineMd,
    titleMedium: AppTextStyles.bodyLg,
    titleSmall: AppTextStyles.labelMd,
    bodyLarge: AppTextStyles.bodyLg,
    bodyMedium: AppTextStyles.bodyMd,
    bodySmall: AppTextStyles.labelMd,
    labelLarge: AppTextStyles.labelMd,
    labelMedium: AppTextStyles.labelMd,
    labelSmall: AppTextStyles.labelSm,
  );

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: _colorScheme,
      textTheme: _textTheme,
      fontFamily: AppTextStyles.fontFamily,
      fontFamilyFallback: AppTextStyles.fontFamilyFallback,
      scaffoldBackgroundColor: AppColors.background,
      splashFactory: InkSparkle.splashFactory,
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.primary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTextStyles.headlineMd.copyWith(color: AppColors.primary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceContainerLowest,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.std),
          side: const BorderSide(color: AppColors.surfaceVariant),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: 0,
          textStyle: AppTextStyles.labelMd,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.gutter,
          ),
          shape: const StadiumBorder(),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          textStyle: AppTextStyles.labelMd,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          shape: const StadiumBorder(),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppTextStyles.labelMd,
          side: const BorderSide(color: AppColors.outlineVariant),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          shape: const StadiumBorder(),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppTextStyles.labelMd,
          shape: const StadiumBorder(),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        highlightElevation: 0,
        shape: CircleBorder(),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceContainerLow,
        selectedColor: AppColors.primaryFixed,
        checkmarkColor: AppColors.primary,
        labelStyle: AppTextStyles.labelMd,
        secondaryLabelStyle: AppTextStyles.labelMd.copyWith(color: AppColors.primary),
        side: const BorderSide(color: AppColors.outlineVariant),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.base,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainerLow,
        hintStyle: AppTextStyles.bodyMd.copyWith(color: AppColors.outline),
        labelStyle: AppTextStyles.labelMd.copyWith(color: AppColors.onSurfaceVariant),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.gutter,
          vertical: AppSpacing.sm,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.std),
          borderSide: const BorderSide(color: AppColors.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.std),
          borderSide: const BorderSide(color: AppColors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.std),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: AppTextStyles.headlineMd,
        contentTextStyle: AppTextStyles.bodyMd,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: AppColors.outlineVariant,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.onSecondaryContainer
              : AppColors.surfaceContainerLowest,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.secondaryContainer
              : AppColors.surfaceContainerHighest,
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.surfaceVariant, space: 1),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.surfaceContainer,
      ),
      listTileTheme: ListTileThemeData(
        titleTextStyle: AppTextStyles.bodyMd,
        subtitleTextStyle: AppTextStyles.labelMd.copyWith(color: AppColors.onSurfaceVariant),
        iconColor: AppColors.onSurfaceVariant,
      ),
    );
  }
}
