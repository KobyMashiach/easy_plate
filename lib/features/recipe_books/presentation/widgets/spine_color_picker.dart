import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../domain/entities/book_spine.dart';

/// The ten spine colours. The first three follow the theme's own accents;
/// the rest are fixed mid-saturation tones that read on the lavender shelf
/// in light and dark alike.
Color bookSpineColor(BookSpine spine) => switch (spine) {
      BookSpine.violet => AppColors.primary,
      BookSpine.indigo => AppColors.tertiary,
      BookSpine.teal => AppColors.secondary,
      BookSpine.mint => AppColors.mintFresh,
      BookSpine.amber => AppColors.warmAccent,
      BookSpine.coral => const Color(0xFFE8734A),
      BookSpine.rose => const Color(0xFFD6457A),
      BookSpine.plum => const Color(0xFF8E44AD),
      BookSpine.forest => const Color(0xFF2E8B57),
      BookSpine.slate => const Color(0xFF5C6F82),
    };

/// A row of swatches; the chosen one carries a tick.
class SpineColorPicker extends StatelessWidget {
  final BookSpine? selected;
  final ValueChanged<BookSpine> onSelect;

  const SpineColorPicker({super.key, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      alignment: WrapAlignment.center,
      children: [
        for (final spine in BookSpine.values)
          GestureDetector(
            onTap: () => onSelect(spine),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: bookSpineColor(spine),
                shape: BoxShape.circle,
                border: Border.all(
                  color: spine == selected ? AppColors.onSurface : AppColors.surfaceContainerLowest,
                  width: spine == selected ? 3 : 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: bookSpineColor(spine).withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: spine == selected
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 22)
                  : null,
            ),
          ),
      ],
    );
  }
}
