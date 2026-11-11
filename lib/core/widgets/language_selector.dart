import 'package:flutter/material.dart';

import 'clay/min_tap_target.dart';

import '../constants/app_colors.dart';
import '../constants/app_enums.dart';
import '../constants/app_spacing.dart';
import '../constants/app_text_styles.dart';
import '../utils/i18n/app_language_mapper.dart';
import '../constants/app_motion.dart';

/// The language chips, shared by settings and the pre-sign-in screens so both
/// offer the same list in the same shape.
class LanguageSelector extends StatelessWidget {
  final AppLanguage selected;
  final ValueChanged<AppLanguage> onSelect;

  const LanguageSelector({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.base,
      runSpacing: AppSpacing.base,
      alignment: WrapAlignment.center,
      children: AppLanguage.values.map((language) {
        final isSelected = language == selected;
        return MinTapTarget(
          // Read as a choice with its state, and touched at 48 high even
          // where the pill is drawn smaller.
          child: Semantics(
            button: true,
            selected: isSelected,
            child: GestureDetector(
              onTap: () => onSelect(language),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: AppMotion.quick,
                curve: AppMotion.easeOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.gutter,
                  vertical: AppSpacing.base,
                ),
                decoration: ShapeDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.surfaceContainerLow,
                  shape: StadiumBorder(
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.outlineVariant,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected) ...[
                      Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: AppColors.onPrimary,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                    ],
                    Text(
                      language.label,
                      style: AppTextStyles.labelMd.copyWith(
                        color: isSelected
                            ? AppColors.onPrimary
                            : AppColors.tertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
