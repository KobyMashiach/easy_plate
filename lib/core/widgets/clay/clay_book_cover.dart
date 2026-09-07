import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_shadows.dart';
import '../../constants/app_spacing.dart';
import '../../constants/app_text_styles.dart';
import 'clay_image.dart';

/// A recipe book rendered as a physical object: thick coloured spine on the
/// binding edge, asymmetric radii, and a heavier shadow than a flat card.
class ClayBookCover extends StatefulWidget {
  final String title;
  final String eyebrow;
  final String meta;
  final Color spineColor;
  final IconData icon;
  final String? imageFileName;

  /// Storage path of the same cover, for a book restored on another device.
  final String? imageRemotePath;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const ClayBookCover({
    super.key,
    required this.title,
    required this.eyebrow,
    required this.meta,
    required this.onTap,
    this.spineColor = AppColors.primary,
    this.icon = Icons.menu_book_rounded,
    this.imageFileName,
    this.imageRemotePath,
    this.onLongPress,
  });

  @override
  State<ClayBookCover> createState() => _ClayBookCoverState();
}

class _ClayBookCoverState extends State<ClayBookCover> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    // Tight radius on the spine edge, generous on the fore-edge.
    const radius = BorderRadiusDirectional.horizontal(
      start: Radius.circular(AppRadius.sm),
      end: Radius.circular(AppRadius.md),
    );

    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: radius,
            boxShadow: AppShadows.book,
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: Row(
              children: [
                Container(width: 12, color: widget.spineColor),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ClayImage(
                          fileName: widget.imageFileName,
                          remotePath: widget.imageRemotePath,
                          fallbackIcon: widget.icon,
                          fallbackIconSize: 56,
                          radius: 0,
                          tint: widget.spineColor.withValues(alpha: 0.12),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.eyebrow,
                              style: AppTextStyles.labelSm.copyWith(color: widget.spineColor),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              widget.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodyLg.copyWith(
                                fontWeight: FontWeight.w700,
                                fontVariations: const [FontVariation('wght', 700)],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Row(
                              children: [
                                const Icon(
                                  Icons.menu_book_rounded,
                                  size: 16,
                                  color: AppColors.outline,
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  widget.meta,
                                  style: AppTextStyles.labelMd.copyWith(
                                    color: AppColors.outline,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
