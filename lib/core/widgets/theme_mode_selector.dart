import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_text_styles.dart';
import '../theme/theme_controller.dart';
import '../theme/theme_switcher.dart';
import '../utils/i18n/strings.g.dart';

/// System / light / dark, as pills like the language chips. A tap hands its
/// position to [ThemeSwitcher], which is where the circle starts growing.
class ThemeModeSelector extends StatelessWidget {
  const ThemeModeSelector({super.key});

  static IconData _icon(AppThemeMode mode) => switch (mode) {
        AppThemeMode.system => Icons.brightness_auto_rounded,
        AppThemeMode.light => Icons.light_mode_rounded,
        AppThemeMode.dark => Icons.dark_mode_rounded,
      };

  static String _label(AppThemeMode mode) => switch (mode) {
        AppThemeMode.system => t.settings.themeSystem,
        AppThemeMode.light => t.settings.themeLight,
        AppThemeMode.dark => t.settings.themeDark,
      };

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController(),
      builder: (context, _) {
        final selected = ThemeController().mode;
        return Wrap(
          spacing: AppSpacing.base,
          runSpacing: AppSpacing.base,
          alignment: WrapAlignment.center,
          children: AppThemeMode.values.map((mode) {
            final isSelected = mode == selected;
            return GestureDetector(
              onTapUp: (details) =>
                  ThemeSwitcher.of(context).switchTo(mode, origin: details.globalPosition),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.gutter,
                  vertical: AppSpacing.base,
                ),
                decoration: ShapeDecoration(
                  color: isSelected ? AppColors.primary : AppColors.surfaceContainerLow,
                  shape: StadiumBorder(
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : AppColors.outlineVariant,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _icon(mode),
                      size: 16,
                      color: isSelected ? AppColors.onPrimary : AppColors.tertiary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      _label(mode),
                      style: AppTextStyles.labelMd.copyWith(
                        color: isSelected ? AppColors.onPrimary : AppColors.tertiary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
