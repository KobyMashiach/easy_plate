import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_motion.dart';
import '../constants/app_spacing.dart';
import '../constants/app_text_styles.dart';
import '../theme/text_size_controller.dart';
import '../utils/i18n/strings.g.dart';
import 'clay/min_tap_target.dart';

/// Normal / large / extra large, as pills like the theme's, over a line of
/// sample text. The whole app (this row included) changes size on the tap,
/// so the sample is simply drawn at the app's size: what it shows is what
/// every screen now looks like.
class TextSizeSelector extends StatelessWidget {
  const TextSizeSelector({super.key});

  static String _label(AppTextSize size) => switch (size) {
    AppTextSize.normal => t.settings.textSizeNormal,
    AppTextSize.large => t.settings.textSizeLarge,
    AppTextSize.extraLarge => t.settings.textSizeExtraLarge,
  };

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: TextSizeController(),
      builder: (context, _) {
        final selected = TextSizeController().size;
        return Column(
          children: [
            Wrap(
              spacing: AppSpacing.base,
              runSpacing: AppSpacing.base,
              alignment: WrapAlignment.center,
              children: AppTextSize.values.map((size) {
                final isSelected = size == selected;
                final ink = isSelected
                    ? AppColors.onPrimary
                    : AppColors.tertiary;
                return MinTapTarget(
                  child: Semantics(
                    button: true,
                    selected: isSelected,
                    child: GestureDetector(
                      onTap: () => TextSizeController().setSize(size),
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
                            // The glyph grows with the step, so the three
                            // read as sizes before their names are read.
                            ExcludeSemantics(
                              child: Text(
                                'A',
                                textScaler: TextScaler.noScaling,
                                style: AppTextStyles.labelMd.copyWith(
                                  color: ink,
                                  fontSize: 12 * size.scale,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              _label(size),
                              style: AppTextStyles.labelMd.copyWith(
                                color: ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.md),
            AnimatedSize(
              duration: AppMotion.move(context, AppMotion.quick),
              curve: AppMotion.easeOut,
              child: Text(
                t.settings.textSizePreview,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
