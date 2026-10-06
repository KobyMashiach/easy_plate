import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_motion.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/services/cook_session_service.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/utils/step_duration.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../../../core/widgets/measurement_unit_label.dart';
import '../../domain/entities/recipe_entity.dart';
import '../../domain/entities/recipe_ingredient_entity.dart';

/// One step at a time, in type large enough to read from across the counter,
/// with the screen kept awake. Each step shows the ingredients it mentions
/// and, when the text names a duration, a timer for it. The step and the
/// timers live in [CookSessionService], so closing this screen pauses
/// nothing: the inbox keeps a way back in, and only "done" ends the cooking.
class CookModePage extends StatefulWidget {
  final RecipeEntity recipe;

  const CookModePage({super.key, required this.recipe});

  @override
  State<CookModePage> createState() => _CookModePageState();
}

class _CookModePageState extends State<CookModePage> {
  final _session = CookSessionService();
  late final PageController _pages;

  List<String> get _steps => widget.recipe.steps;
  int get _index => _session.stepIndex;

  @override
  void initState() {
    super.initState();
    _session.start(widget.recipe);
    _pages = PageController(initialPage: _session.stepIndex);
    // No wakelock on the web and in tests; cooking carries on without it.
    unawaited(WakelockPlus.enable().catchError((_) {}));
  }

  @override
  void dispose() {
    unawaited(WakelockPlus.disable().catchError((_) {}));
    _pages.dispose();
    super.dispose();
  }

  void _go(int index) {
    if (index < 0 || index >= _steps.length) return;
    _pages.animateToPage(
      index,
      duration: AppMotion.emphasized,
      curve: AppMotion.easeOut,
    );
  }

  Future<void> _finish() async {
    await showDialog<void>(
      context: context,
      builder: (context) =>
          _FinishedDialog(onClose: () => Navigator.of(context).pop()),
    );
    _session.finish();
    if (mounted) Navigator.of(context).maybePop();
  }

  void _showIngredients() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) =>
          _IngredientsSheet(ingredients: widget.recipe.ingredients),
    );
  }

  /// The ingredients whose name appears in the step text, so the amount is
  /// right under the instruction that uses it.
  List<RecipeIngredientEntity> _ingredientsIn(String step) {
    final haystack = step.toLowerCase();
    return widget.recipe.ingredients.where((ingredient) {
      final name = ingredient.name.trim().toLowerCase();
      if (name.length < 3) return false;
      if (haystack.contains(name)) return true;
      // The step often uses the first word only: "the salmon", not
      // "salmon fillets". A word needs some length to be meaningful.
      final head = name.split(RegExp(r'\s+')).first;
      return head.length >= 4 && haystack.contains(head);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final total = _steps.length;

    return ClayScaffold(
      appBar: ClayTopAppBar(
        title: t.cookMode.title,
        leadingIcon: Icons.close_rounded,
        onLeadingTap: () => Navigator.of(context).maybePop(),
        actions: [
          if (widget.recipe.ingredients.isNotEmpty)
            ClayIconButton(
              icon: Icons.format_list_bulleted_rounded,
              tooltip: t.cookMode.ingredients,
              onTap: _showIngredients,
            ),
          const SizedBox(width: AppSpacing.base),
          // Always in reach: the only way the cooking ends.
          _FinishPill(onTap: total == 0 ? null : _finish),
        ],
      ),
      body: total == 0
          ? ClayEmptyState(
              icon: Icons.restaurant_rounded,
              message: t.cookMode.noSteps,
            )
          : AnimatedBuilder(
              animation: _session,
              builder: (context, _) {
                // Finished elsewhere (the inbox's "end"): nothing to show.
                if (!_session.isActive) return const SizedBox.shrink();
                final isLast = _index == total - 1;
                return SafeArea(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.marginMobile,
                          AppSpacing.gutter,
                          AppSpacing.marginMobile,
                          0,
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    t.cookMode.stepOf(
                                      n: '${_index + 1}',
                                      total: '$total',
                                    ),
                                    style: AppTextStyles.labelMd.copyWith(
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.brightness_7_rounded,
                                  size: 14,
                                  color: AppColors.outline,
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  t.cookMode.screenOn,
                                  style: AppTextStyles.labelSm.copyWith(
                                    color: AppColors.outline,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.base),
                            ClayProgressBar(
                              value: (_index + 1) / total,
                              height: AppSpacing.sm,
                            ),
                          ],
                        ),
                      ),
                      // Every timer counting down, whichever step it is on.
                      _RunningTimersStrip(
                        timers: _session.activeTimers,
                        onTap: _go,
                      ),
                      Expanded(
                        child: PageView.builder(
                          controller: _pages,
                          itemCount: total,
                          onPageChanged: (i) {
                            HapticFeedback.selectionClick();
                            _session.setStep(i);
                          },
                          itemBuilder: (context, i) => _StepPage(
                            number: i + 1,
                            text: _steps[i],
                            ingredients: _ingredientsIn(_steps[i]),
                            timer: _session.timers[i],
                            onToggleTimer: () => _session.toggleTimer(i),
                            onResetTimer: () => _session.resetTimer(i),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.marginMobile,
                          AppSpacing.sm,
                          AppSpacing.marginMobile,
                          AppSpacing.gutter,
                        ),
                        child: Row(
                          children: [
                            ClayIconButton(
                              icon: Icons.arrow_back_rounded,
                              size: 56,
                              tooltip: t.cookMode.previous,
                              onTap: _index == 0 ? null : () => _go(_index - 1),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: ClayButton(
                                label: isLast
                                    ? t.cookMode.finish
                                    : t.cookMode.next,
                                icon: isLast
                                    ? Icons.check_rounded
                                    : Icons.arrow_forward_rounded,
                                expanded: true,
                                onPressed: isLast
                                    ? _finish
                                    : () => _go(_index + 1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

/// "Done" in the app bar: a small stadium that reads as a button, not an icon.
class _FinishPill extends StatelessWidget {
  final VoidCallback? onTap;

  const _FinishPill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final ink = enabled ? AppColors.onSecondaryContainer : AppColors.outline;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.base,
        ),
        decoration: ShapeDecoration(
          color: enabled
              ? AppColors.secondaryContainer
              : AppColors.surfaceContainer,
          shape: const StadiumBorder(),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_rounded, size: 18, color: ink),
            const SizedBox(width: AppSpacing.xs),
            Text(
              t.cookMode.finish,
              style: AppTextStyles.labelMd.copyWith(color: ink),
            ),
          ],
        ),
      ),
    );
  }
}

/// All timers counting down (or just finished), one row each, pinned above
/// the step so none is out of sight. A row jumps to its step.
class _RunningTimersStrip extends StatelessWidget {
  final List<MapEntry<int, CookTimer>> timers;
  final ValueChanged<int> onTap;

  const _RunningTimersStrip({required this.timers, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: AppMotion.standard,
      curve: AppMotion.easeOut,
      alignment: Alignment.topCenter,
      child: timers.isEmpty
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.marginMobile,
                AppSpacing.sm,
                AppSpacing.marginMobile,
                0,
              ),
              child: ClayCard(
                radius: AppRadius.md,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.gutter,
                  vertical: AppSpacing.sm,
                ),
                child: Column(
                  children: [
                    for (final entry in timers)
                      CookTimerRow(
                        step: entry.key + 1,
                        timer: entry.value,
                        onTap: () => onTap(entry.key),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}

/// A compact timer line: step, remaining over total, and a bar. Shared with
/// the inbox card, which shows the same timers outside cook mode.
class CookTimerRow extends StatelessWidget {
  final int step;
  final CookTimer timer;
  final VoidCallback? onTap;

  const CookTimerRow({
    super.key,
    required this.step,
    required this.timer,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final finished = timer.finished;
    final ink = finished ? AppColors.secondary : AppColors.primary;
    final label = t.cookMode.stepLabel(n: '$step');
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.base),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  finished
                      ? Icons.notifications_active_rounded
                      : Icons.timer_rounded,
                  size: 18,
                  color: ink,
                ),
                const SizedBox(width: AppSpacing.base),
                Expanded(
                  child: Text(
                    finished ? '$label · ${t.cookMode.timeUp}' : label,
                    style: AppTextStyles.labelMd.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${formatClock(timer.remaining)} / ${formatClock(timer.total)}',
                  style: AppTextStyles.bodyLg.copyWith(
                    color: ink,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.base),
            ClayProgressBar(value: timer.progress, height: AppSpacing.base),
          ],
        ),
      ),
    );
  }
}

class _StepPage extends StatelessWidget {
  final int number;
  final String text;
  final List<RecipeIngredientEntity> ingredients;
  final CookTimer? timer;
  final VoidCallback onToggleTimer;
  final VoidCallback onResetTimer;

  const _StepPage({
    required this.number,
    required this.text,
    required this.ingredients,
    required this.timer,
    required this.onToggleTimer,
    required this.onResetTimer,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.marginMobile,
        AppSpacing.gutter,
        AppSpacing.marginMobile,
        AppSpacing.gutter,
      ),
      children: [
        ClayCard(
          radius: AppRadius.lg,
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primaryFixed,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$number',
                  style: AppTextStyles.headlineMd.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.gutter),
              // Large enough to read with the phone propped behind the hob.
              Text(
                text,
                style: AppTextStyles.headlineMd.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        if (ingredients.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          ClayCard(
            radius: AppRadius.md,
            padding: const EdgeInsets.all(AppSpacing.gutter),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.cookMode.inThisStep,
                  style: AppTextStyles.labelMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.base),
                Wrap(
                  spacing: AppSpacing.base,
                  runSpacing: AppSpacing.base,
                  children: [
                    for (final ingredient in ingredients)
                      _AmountChip(ingredient: ingredient),
                  ],
                ),
              ],
            ),
          ),
        ],
        if (timer != null) ...[
          const SizedBox(height: AppSpacing.sm),
          _TimerCard(
            timer: timer!,
            onToggle: onToggleTimer,
            onReset: onResetTimer,
          ),
        ],
      ],
    );
  }
}

class _AmountChip extends StatelessWidget {
  final RecipeIngredientEntity ingredient;

  const _AmountChip({required this.ingredient});

  @override
  Widget build(BuildContext context) {
    final amount = ingredient.isAmountMissing
        ? kMissingInfoPlaceholder
        : ingredient.displayAmount;
    final unit = measurementUnitLabel(ingredient.unit);
    final quantity = [amount, unit].where((s) => s.isNotEmpty).join(' ');
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.base,
      ),
      decoration: ShapeDecoration(
        color: AppColors.surfaceContainerLow,
        shape: StadiumBorder(side: BorderSide(color: AppColors.outlineVariant)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            quantity,
            style: AppTextStyles.bodyLg.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: AppSpacing.base),
          Text(ingredient.name, style: AppTextStyles.bodyMd),
        ],
      ),
    );
  }
}

class _TimerCard extends StatelessWidget {
  final CookTimer timer;
  final VoidCallback onToggle;
  final VoidCallback onReset;

  const _TimerCard({
    required this.timer,
    required this.onToggle,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final finished = timer.finished;
    return ClayCard(
      radius: AppRadius.md,
      padding: const EdgeInsets.all(AppSpacing.gutter),
      color: finished ? AppColors.secondaryContainer : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                finished
                    ? Icons.notifications_active_rounded
                    : Icons.timer_rounded,
                size: 20,
                color: finished
                    ? AppColors.onSecondaryContainer
                    : AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.base),
              Text(
                finished ? t.cookMode.timeUp : t.cookMode.timer,
                style: AppTextStyles.labelMd.copyWith(
                  color: finished
                      ? AppColors.onSecondaryContainer
                      : AppColors.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Text(
                formatClock(timer.remaining),
                style: AppTextStyles.displayLg.copyWith(
                  color: finished
                      ? AppColors.onSecondaryContainer
                      : AppColors.onSurface,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClayProgressBar(value: timer.progress, height: AppSpacing.base),
          const SizedBox(height: AppSpacing.gutter),
          Row(
            children: [
              Expanded(
                child: ClayButton(
                  label: finished
                      ? t.cookMode.reset
                      : timer.running
                      ? t.cookMode.pause
                      : timer.remaining == timer.total
                      ? t.cookMode.startTimer
                      : t.cookMode.resume,
                  icon: finished
                      ? Icons.replay_rounded
                      : timer.running
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  expanded: true,
                  onPressed: onToggle,
                ),
              ),
              if (!finished && timer.remaining != timer.total) ...[
                const SizedBox(width: AppSpacing.sm),
                ClayIconButton(
                  icon: Icons.replay_rounded,
                  size: 56,
                  tooltip: t.cookMode.reset,
                  onTap: onReset,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _IngredientsSheet extends StatefulWidget {
  final List<RecipeIngredientEntity> ingredients;

  const _IngredientsSheet({required this.ingredients});

  @override
  State<_IngredientsSheet> createState() => _IngredientsSheetState();
}

class _IngredientsSheetState extends State<_IngredientsSheet> {
  final Set<int> _done = {};

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, controller) => DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.lg),
          ),
        ),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.marginMobile,
            AppSpacing.sm,
            AppSpacing.marginMobile,
            AppSpacing.xl,
          ),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.gutter),
            ClaySectionHeader(title: t.cookMode.ingredients, underline: true),
            const SizedBox(height: AppSpacing.sm),
            for (final entry in widget.ingredients.asMap().entries)
              _IngredientRow(
                ingredient: entry.value,
                done: _done.contains(entry.key),
                onTap: () => setState(() {
                  if (!_done.add(entry.key)) _done.remove(entry.key);
                }),
              ),
          ],
        ),
      ),
    );
  }
}

class _IngredientRow extends StatelessWidget {
  final RecipeIngredientEntity ingredient;
  final bool done;
  final VoidCallback onTap;

  const _IngredientRow({
    required this.ingredient,
    required this.done,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final amount = ingredient.isAmountMissing
        ? kMissingInfoPlaceholder
        : ingredient.displayAmount;
    final unit = measurementUnitLabel(ingredient.unit);
    final line = [
      amount,
      unit,
      ingredient.name,
    ].where((s) => s.isNotEmpty).join(' ');
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.base),
        child: Row(
          children: [
            BouncyCheckbox(value: done, onChanged: (_) => onTap()),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AnimatedDefaultTextStyle(
                duration: AppMotion.quick,
                style: AppTextStyles.bodyLg.copyWith(
                  color: done ? AppColors.outline : AppColors.onSurface,
                  decoration: done ? TextDecoration.lineThrough : null,
                ),
                child: Text(line),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FinishedDialog extends StatelessWidget {
  final VoidCallback onClose;

  const _FinishedDialog({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(AppSpacing.md),
      child: ClayCard(
        radius: AppRadius.lg,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.secondaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.restaurant_rounded,
                size: 36,
                color: AppColors.onSecondaryContainer,
              ),
            ),
            const SizedBox(height: AppSpacing.gutter),
            Text(
              t.cookMode.finishedTitle,
              style: AppTextStyles.headlineMd,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.base),
            Text(
              t.cookMode.finishedBody,
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            ClayButton(
              label: t.common.done,
              icon: Icons.check_rounded,
              expanded: true,
              onPressed: onClose,
            ),
          ],
        ),
      ),
    );
  }
}
