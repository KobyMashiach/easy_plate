import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../../../core/widgets/nutrition/nutrition_widgets.dart';
import '../../../../core/widgets/weekday_selector.dart';
import '../../../my_recipes/domain/entities/recipe_entity.dart';
import '../../domain/entities/meal_plan_entity.dart';
import '../../domain/nutrition_summary.dart';

class NutritionDashboardArgs {
  final MealPlanEntity plan;
  final Map<String, RecipeEntity> recipes;

  const NutritionDashboardArgs({required this.plan, required this.recipes});
}

/// The week of a meal plan as numbers: the totals up top, a bar per day
/// coloured by macro, the week's split as a ring, then each day's line.
class NutritionDashboardPage extends StatefulWidget {
  final NutritionDashboardArgs args;

  const NutritionDashboardPage({super.key, required this.args});

  @override
  State<NutritionDashboardPage> createState() => _NutritionDashboardPageState();
}

class _NutritionDashboardPageState extends State<NutritionDashboardPage> {
  int? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final week = PlanNutrition.of(widget.args.plan, widget.args.recipes);
    final days = ShoppingDay.values;
    final selected = _selectedDay == null ? null : week.day(_selectedDay!);

    return ClayScaffold(
      appBar: ClayTopAppBar(
        title: t.nutrition.dashboard,
        leadingIcon: Icons.arrow_back_rounded,
        onLeadingTap: () => Navigator.of(context).maybePop(),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.marginMobile,
          AppSpacing.md,
          AppSpacing.marginMobile,
          AppSpacing.xl,
        ),
        children: [
          ClayPageHeader(title: widget.args.plan.name, subtitle: t.nutrition.weekly),
          const SizedBox(height: AppSpacing.gutter),
          if (!week.hasData)
            ClayEmptyState(icon: Icons.insights_rounded, message: t.nutrition.noPlanned)
          else ...[
            // The two numbers that matter, side by side.
            Row(
              children: [
                Expanded(
                  child: _HeroFigure(
                    caption: t.nutrition.dailyAverage,
                    value: kcalNumber(week.dailyAverage.calories),
                    unit: t.nutrition.kcalPerDay,
                    color: AppColors.primary,
                    filled: true,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _HeroFigure(
                    caption: t.nutrition.weekTotal,
                    value: kcalNumber(week.weekTotal.calories),
                    unit: t.nutrition.kcal,
                    color: AppColors.warmAccent,
                    filled: false,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.gutter),
            ClayCard(
              radius: AppRadius.md,
              padding: const EdgeInsets.all(AppSpacing.gutter),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClaySectionHeader(title: t.nutrition.perDay),
                  const SizedBox(height: AppSpacing.gutter),
                  SizedBox(
                    height: 168,
                    child: _WeekBars(
                      week: week,
                      labels: [for (final d in days) weekdayLabel(d)],
                      selected: _selectedDay,
                      onSelect: (i) => setState(() => _selectedDay = _selectedDay == i ? null : i),
                    ),
                  ),
                  if (selected != null) ...[
                    const SizedBox(height: AppSpacing.gutter),
                    _DayLine(day: selected, label: weekdayLabel(days[selected.weekday])),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.gutter),
            ClayCard(
              radius: AppRadius.md,
              padding: const EdgeInsets.all(AppSpacing.gutter),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClaySectionHeader(title: t.nutrition.macroSplit),
                  const SizedBox(height: AppSpacing.gutter),
                  Row(
                    children: [
                      MacroRing(nutrition: week.dailyAverage, size: 128, thickness: 14),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          children: [
                            for (final macro in Macro.values) ...[
                              MacroBar(macro: macro, nutrition: week.dailyAverage),
                              if (macro != Macro.values.last) const SizedBox(height: AppSpacing.sm),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.base),
                  Text(
                    t.nutrition.dailyAverage,
                    style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.gutter),
            ClayCard(
              radius: AppRadius.md,
              padding: const EdgeInsets.all(AppSpacing.gutter),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClaySectionHeader(title: t.nutrition.perMeal),
                  const SizedBox(height: AppSpacing.sm),
                  for (final day in week.days)
                    if (day.hasData)
                      for (final meal in day.meals)
                        if (meal.countedItems > 0)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 44,
                                  child: Text(
                                    weekdayLabel(days[day.weekday]),
                                    style: AppTextStyles.labelSm
                                        .copyWith(color: AppColors.onSurfaceVariant),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    meal.meal.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.labelMd,
                                  ),
                                ),
                                Text(
                                  '${kcalNumber(meal.total.calories)} ${t.nutrition.kcal}',
                                  style: AppTextStyles.labelMd.copyWith(
                                    fontWeight: FontWeight.w800,
                                    fontVariations: const [FontVariation('wght', 800)],
                                  ),
                                ),
                              ],
                            ),
                          ),
                ],
              ),
            ),
            if (week.missingItems > 0) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 14, color: AppColors.outline),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      t.nutrition.missingCount(count: week.missingItems),
                      style: AppTextStyles.labelSm.copyWith(color: AppColors.outline),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}

/// A big number in a coloured tile.
class _HeroFigure extends StatelessWidget {
  final String caption;
  final String value;
  final String unit;
  final Color color;
  final bool filled;

  const _HeroFigure({
    required this.caption,
    required this.value,
    required this.unit,
    required this.color,
    required this.filled,
  });

  @override
  Widget build(BuildContext context) {
    final ink = filled ? AppColors.onPrimary : AppColors.onSurface;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      decoration: BoxDecoration(
        color: filled ? color : AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: filled ? null : Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            caption,
            style: AppTextStyles.labelSm.copyWith(color: ink.withValues(alpha: 0.8)),
          ),
          const SizedBox(height: AppSpacing.base),
          Text(
            value,
            style: AppTextStyles.headlineLgMobile.copyWith(
              color: ink,
              fontWeight: FontWeight.w800,
              fontVariations: const [FontVariation('wght', 800)],
            ),
          ),
          Text(unit, style: AppTextStyles.labelMd.copyWith(color: ink.withValues(alpha: 0.8))),
        ],
      ),
    );
  }
}

/// Seven stacked bars, one per day, each split into its macros by calorie
/// share; the tallest is the week's peak. Tapping a bar selects the day.
class _WeekBars extends StatelessWidget {
  final PlanNutrition week;
  final List<String> labels;
  final int? selected;
  final ValueChanged<int> onSelect;

  const _WeekBars({
    required this.week,
    required this.labels,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final peak = week.peakCalories;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final day in week.days) ...[
          if (day.weekday > 0) const SizedBox(width: AppSpacing.base),
          Expanded(
            child: GestureDetector(
              onTap: () => onSelect(day.weekday),
              behavior: HitTestBehavior.opaque,
              child: _DayBar(
                day: day,
                heightFactor: day.total.calories / peak,
                label: labels[day.weekday],
                selected: selected == day.weekday,
                dimmed: selected != null && selected != day.weekday,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _DayBar extends StatelessWidget {
  final DayNutrition day;
  final double heightFactor;
  final String label;
  final bool selected;
  final bool dimmed;

  const _DayBar({
    required this.day,
    required this.heightFactor,
    required this.label,
    required this.selected,
    required this.dimmed,
  });

  @override
  Widget build(BuildContext context) {
    final shares = day.total.macroShares;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (day.hasData)
          Text(
            kcalNumber(day.total.calories),
            style: AppTextStyles.labelSm.copyWith(
              color: selected ? AppColors.primary : AppColors.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
        const SizedBox(height: AppSpacing.xs),
        Expanded(
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: dimmed ? 0.4 : 1,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: AnimatedFractionallySizedBox(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic,
                heightFactor: day.hasData ? heightFactor.clamp(0.06, 1.0) : 0.06,
                widthFactor: 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: day.hasData
                      ? Column(
                          // Stretch, or a childless ColoredBox sizes itself to
                          // zero width and the bar vanishes.
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Top to bottom: fat, carbs, protein — the same
                            // order as the legend, so the eye matches them.
                            for (final (macro, share) in [
                              (Macro.fat, shares.fat),
                              (Macro.carbs, shares.carbs),
                              (Macro.protein, shares.protein),
                            ])
                              if (share > 0)
                                Expanded(
                                  flex: (share * 1000).round(),
                                  child: ColoredBox(color: macro.color),
                                ),
                          ],
                        )
                      : ColoredBox(color: AppColors.surfaceContainerHigh),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.base),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.labelSm.copyWith(
            color: selected ? AppColors.primary : AppColors.onSurfaceVariant,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// The selected day under the chart: its calories and macro grams in a line.
class _DayLine extends StatelessWidget {
  final DayNutrition day;
  final String label;

  const _DayLine({required this.day, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.primaryFixed,
        borderRadius: BorderRadius.circular(AppRadius.std),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: AppTextStyles.labelMd.copyWith(
              color: AppColors.onPrimaryFixed,
              fontWeight: FontWeight.w800,
              fontVariations: const [FontVariation('wght', 800)],
            ),
          ),
          const Spacer(),
          if (!day.hasData)
            Text(
              t.nutrition.noPlanned,
              style: AppTextStyles.labelSm.copyWith(color: AppColors.onPrimaryFixedVariant),
            )
          else ...[
            Text(
              '${kcalNumber(day.total.calories)} ${t.nutrition.kcal}',
              style: AppTextStyles.labelMd.copyWith(color: AppColors.onPrimaryFixed),
            ),
            const SizedBox(width: AppSpacing.sm),
            for (final macro in Macro.values) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: macro.color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 3),
              Text(
                gramsLabel(macro.gramsOf(day.total)),
                style: AppTextStyles.labelSm.copyWith(color: AppColors.onPrimaryFixedVariant),
              ),
              const SizedBox(width: AppSpacing.base),
            ],
          ],
        ],
      ),
    );
  }
}
