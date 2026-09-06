import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/duration_label.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../../../core/widgets/dietary_chip_selector.dart';
import 'shared_feed_query.dart';

/// Returns the edited query, or null if the sheet was dismissed.
Future<SharedFeedQuery?> showSharedFeedFilterSheet(
  BuildContext context,
  SharedFeedQuery current,
) {
  return showModalBottomSheet<SharedFeedQuery>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceContainerLowest,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.md)),
    ),
    builder: (_) => _SharedFeedFilterSheet(initial: current),
  );
}

class _SharedFeedFilterSheet extends StatefulWidget {
  final SharedFeedQuery initial;

  const _SharedFeedFilterSheet({required this.initial});

  @override
  State<_SharedFeedFilterSheet> createState() => _SharedFeedFilterSheetState();
}

class _SharedFeedFilterSheetState extends State<_SharedFeedFilterSheet> {
  late SharedFeedQuery _query = widget.initial;

  /// Steps of 10 up to a top stop that stays open-ended: 100 means "100 or
  /// more", so the scale never has to grow with the most-liked recipe.
  static const _likeSteps = [0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100];

  String _bucketLabel(TimeBucket bucket) {
    if (bucket.isAny) return t.community.anyTime;
    final boundary = durationLabel(bucket.minutes!);
    return bucket == TimeBucket.over120
        ? t.community.durationPlus(duration: boundary)
        : t.community.upTo(duration: boundary);
  }

  String _likesLabel(int step) {
    if (step == 0) return t.community.anyLikes;
    // The top stop is a floor, not an exact count.
    return step == _likeSteps.last
        ? t.community.likesPlus(count: step)
        : t.community.atLeastLikes(count: step);
  }



  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    const SizedBox(height: AppSpacing.md),
                    ClaySectionHeader(title: t.community.sort, underline: true),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.base,
                      runSpacing: AppSpacing.base,
                      children: [
                        for (final sort in SharedFeedSort.values)
                          _chip(
                            label: _sortLabel(sort),
                            icon: _sortIcon(sort),
                            selected: _query.sort == sort,
                            onTap: () => setState(() => _query = _query.copyWith(sort: sort)),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    ClaySectionHeader(title: t.community.topics, underline: true),
                    const SizedBox(height: AppSpacing.sm),
                    DietaryChipSelector(
                      selected: _query.topics,
                      onToggle: (topic) => setState(() {
                        final topics = [..._query.topics];
                        topics.contains(topic) ? topics.remove(topic) : topics.add(topic);
                        _query = _query.copyWith(topics: topics);
                      }),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _StepSlider<int>(
                      title: t.community.likes,
                      steps: _likeSteps,
                      value: _query.minLikes,
                      labelFor: _likesLabel,
                      onChanged: (step) =>
                          setState(() => _query = _query.copyWith(minLikes: step)),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    // Split is a display choice over the same scale, so the
                    // toggle sits with the sliders it rearranges.
                    _SplitToggle(
                      value: _query.splitTimes,
                      onChanged: (split) =>
                          setState(() => _query = _query.copyWith(splitTimes: split)),
                    ),
                    if (_query.splitTimes) ...[
                      _StepSlider<TimeBucket>(
                        title: t.recipe.prepTime,
                        steps: TimeBucket.values,
                        value: _query.prepTime,
                        labelFor: _bucketLabel,
                        onChanged: (bucket) =>
                            setState(() => _query = _query.copyWith(prepTime: bucket)),
                      ),
                      _StepSlider<TimeBucket>(
                        title: t.recipe.cookTime,
                        steps: TimeBucket.values,
                        value: _query.cookTime,
                        labelFor: _bucketLabel,
                        onChanged: (bucket) =>
                            setState(() => _query = _query.copyWith(cookTime: bucket)),
                      ),
                    ] else
                      _StepSlider<TimeBucket>(
                        title: t.community.totalTime,
                        steps: TimeBucket.values,
                        value: _query.totalTime,
                        labelFor: _bucketLabel,
                        onChanged: (bucket) =>
                            setState(() => _query = _query.copyWith(totalTime: bucket)),
                      ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    children: [
                      if (_query.isNarrowed) ...[
                        ClayButton(
                          label: t.community.clearFilters,
                          icon: Icons.filter_alt_off_rounded,
                          onPressed: () => setState(() => _query = _query.cleared()),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                      ],
                      Expanded(
                        child: ClayButton(
                          label: t.community.applyFilters,
                          icon: Icons.check_rounded,
                          expanded: true,
                          onPressed: () => Navigator.of(context).pop(_query),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _sortLabel(SharedFeedSort sort) => switch (sort) {
        SharedFeedSort.newest => t.community.sortNewest,
        SharedFeedSort.oldest => t.community.sortOldest,
        SharedFeedSort.mostLiked => t.community.sortMostLiked,
      };

  IconData _sortIcon(SharedFeedSort sort) => switch (sort) {
        SharedFeedSort.newest => Icons.schedule_rounded,
        SharedFeedSort.oldest => Icons.history_rounded,
        SharedFeedSort.mostLiked => Icons.favorite_rounded,
      };

  Widget _chip({
    required String label,
    required IconData? icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.gutter,
          vertical: AppSpacing.base,
        ),
        decoration: ShapeDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceContainerLow,
          shape: StadiumBorder(
            side: BorderSide(
              color: selected ? AppColors.primary : AppColors.outlineVariant,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 14, color: selected ? AppColors.onPrimary : AppColors.tertiary),
              const SizedBox(width: AppSpacing.xs),
            ],
            Text(
              label,
              style: AppTextStyles.labelMd.copyWith(
                color: selected ? AppColors.onPrimary : AppColors.tertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A discrete slider over a fixed list of stops.
///
/// Values are dragged along the track rather than tapped as chips, which keeps
/// a long scale (0 to 100 in tens) usable in a sheet. The slider works in
/// indices so the stops can be any type — including a null "no cap" end.
class _StepSlider<T> extends StatelessWidget {
  final String title;
  final List<T> steps;
  final T value;
  final String Function(T step) labelFor;
  final ValueChanged<T> onChanged;

  const _StepSlider({
    required this.title,
    required this.steps,
    required this.value,
    required this.labelFor,
    required this.onChanged,
  });

  /// Falls back to the first stop if the current value is not on the scale,
  /// so a stored filter from an older build cannot leave the thumb detached.
  int get _index {
    final found = steps.indexOf(value);
    return found == -1 ? 0 : found;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: ClaySectionHeader(title: title, underline: true)),
            const SizedBox(width: AppSpacing.sm),
            Text(
              labelFor(value),
              style: AppTextStyles.labelMd.copyWith(color: AppColors.primary),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.outlineVariant,
            thumbColor: AppColors.primary,
            overlayColor: AppColors.primaryFixed,
            activeTickMarkColor: AppColors.onPrimary,
            inactiveTickMarkColor: AppColors.outline,
            valueIndicatorColor: AppColors.primary,
            valueIndicatorTextStyle:
                AppTextStyles.labelSm.copyWith(color: AppColors.onPrimary),
          ),
          child: Slider(
            value: _index.toDouble(),
            min: 0,
            max: (steps.length - 1).toDouble(),
            divisions: steps.length - 1,
            label: labelFor(value),
            onChanged: (raw) => onChanged(steps[raw.round()]),
          ),
        ),
      ],
    );
  }
}

/// Checkbox that swaps the single total-time slider for a prep/cook pair.
class _SplitToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SplitToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.base),
        child: Row(
          children: [
            BouncyCheckbox(value: value, onChanged: (_) => onChanged(!value)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(t.community.splitTimes, style: AppTextStyles.bodyMd),
            ),
          ],
        ),
      ),
    );
  }
}
