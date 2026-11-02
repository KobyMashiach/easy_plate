import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../domain/entities/recipe_image_candidate.dart';

/// The pictures the server offered for a recipe read from a video — the
/// post's cover and stills of the food — with the one on the recipe shown
/// large and the rest in a row to swap in. "No picture" is a choice too.
/// Nothing here touches the recipe: a tap goes out through [onPick] and
/// the bloc writes the file and puts it on the recipe.
class VideoImagePicker extends StatelessWidget {
  final List<RecipeImageCandidate> candidates;

  /// Index into [candidates] of the picture on the recipe; null for none.
  final int? selected;
  final ValueChanged<int?> onPick;

  const VideoImagePicker({
    super.key,
    required this.candidates,
    required this.selected,
    required this.onPick,
  });

  static const thumbSize = 72.0;

  /// "0:12" for a still; the cover is named.
  static String labelFor(RecipeImageCandidate candidate) {
    if (candidate.isCover) return t.ingestion.videoPhotoCover;
    final total = (candidate.atSeconds ?? 0).round();
    final seconds = (total % 60).toString().padLeft(2, '0');
    return '${total ~/ 60}:$seconds';
  }

  RecipeImageCandidate? get _chosen {
    final index = selected;
    if (index == null || index < 0 || index >= candidates.length) return null;
    return candidates[index];
  }

  @override
  Widget build(BuildContext context) {
    final chosen = _chosen;
    return ClayCard(
      radius: AppRadius.md,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClaySectionHeader(
            title: t.ingestion.videoPhotoTitle,
            underline: true,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            t.ingestion.videoPhotoHint,
            style: AppTextStyles.labelMd.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: chosen == null
                  ? Container(
                      color: AppColors.surfaceContainerHigh,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.hide_image_outlined,
                        size: 40,
                        color: AppColors.onSurfaceVariant,
                      ),
                    )
                  : Image.memory(
                      chosen.bytes,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                    ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            // The label under each thumbnail grows with the system text
            // size; a fixed height overflowed the cards from about 1.2×.
            height:
                thumbSize +
                AppSpacing.xs +
                MediaQuery.textScalerOf(context).scale(
                  AppTextStyles.labelSm.fontSize! *
                      (AppTextStyles.labelSm.height ?? 1.4),
                ) +
                2,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: candidates.length + 1,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, index) {
                if (index == candidates.length) {
                  return _Thumb(
                    label: t.ingestion.videoPhotoNone,
                    selected: chosen == null,
                    onTap: () => onPick(null),
                    child: Icon(
                      Icons.hide_image_outlined,
                      color: AppColors.onSurfaceVariant,
                    ),
                  );
                }
                final candidate = candidates[index];
                return _Thumb(
                  label: labelFor(candidate),
                  selected: index == selected,
                  onTap: () => onPick(index),
                  child: Image.memory(
                    candidate.bytes,
                    fit: BoxFit.cover,
                    // Decoded at thumbnail size: six cards of a 720 px
                    // still would otherwise sit in memory at full size.
                    cacheWidth: (thumbSize * 3).round(),
                    gaplessPlayback: true,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  const _Thumb({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: VideoImagePicker.thumbSize,
            height: VideoImagePicker.thumbSize,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(AppRadius.std),
              border: Border.all(
                color: selected ? AppColors.primary : Colors.transparent,
                width: 2.5,
              ),
            ),
            child: child,
          ),
          const SizedBox(height: AppSpacing.xs),
          SizedBox(
            width: VideoImagePicker.thumbSize + AppSpacing.sm,
            child: Text(
              label,
              style: AppTextStyles.labelSm.copyWith(
                color: selected
                    ? AppColors.primary
                    : AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
