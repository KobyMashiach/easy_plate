import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/clay/clay.dart';

/// The rows the settings, preferences and notification screens are built
/// from, so the three read as one place.

/// Clay card holding a single switch, with room for a line explaining what
/// the setting changes.
class SettingsToggle extends StatelessWidget {
  final String title;
  final String? description;
  final bool value;

  /// Null draws the switch disabled — for a choice that depends on another
  /// one being on.
  final ValueChanged<bool>? onChanged;

  const SettingsToggle({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;
    return ClayCard(
      radius: AppRadius.md,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMd.copyWith(
                    color: enabled ? null : AppColors.outline,
                  ),
                ),
                if (description != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    description!,
                    style: AppTextStyles.labelMd.copyWith(
                      color: AppColors.outline,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

/// A titled card around a selector.
class SettingsCard extends StatelessWidget {
  final String title;
  final Widget child;

  const SettingsCard({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return ClayCard(
      radius: AppRadius.md,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClaySectionHeader(title: title),
          const SizedBox(height: AppSpacing.gutter),
          child,
        ],
      ),
    );
  }
}

/// A row that leads to another screen.
class SettingsNavRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? hint;
  final VoidCallback onTap;

  const SettingsNavRow({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return ClayCard(
      radius: AppRadius.md,
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 22, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.bodyLg),
                if (hint != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    hint!,
                    style: AppTextStyles.labelMd.copyWith(
                      color: AppColors.outline,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: AppColors.tertiary),
        ],
      ),
    );
  }
}

/// A small heading between groups of rows.
class SettingsGroupLabel extends StatelessWidget {
  final String label;

  const SettingsGroupLabel(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: AppSpacing.xs,
        top: AppSpacing.base,
      ),
      child: Text(
        label,
        style: AppTextStyles.labelMd.copyWith(
          color: AppColors.onSurfaceVariant,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

/// The scrolling body the three screens share: a page header that stays
/// put and the rows scrolling under it.
class SettingsBody extends StatelessWidget {
  final String title;
  final List<Widget> rows;

  const SettingsBody({super.key, required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.marginMobile,
            AppSpacing.md,
            AppSpacing.marginMobile,
            0,
          ),
          child: ClayPageHeader(title: title),
        ),
        const SizedBox(height: AppSpacing.lg),
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.marginMobile,
              0,
              AppSpacing.marginMobile,
              ClayNavDock.bottomPadding(context),
            ),
            itemCount: rows.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) => rows[index],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

/// Which reminders to get before the shopping day: four fixed moments,
/// any mix of them. None is allowed — some people want no nagging.
class ReminderSlotPicker extends StatelessWidget {
  final List<ShoppingReminderSlot> selected;
  final ValueChanged<List<ShoppingReminderSlot>> onChanged;

  const ReminderSlotPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  static String _label(ShoppingReminderSlot slot) => switch (slot) {
    ShoppingReminderSlot.twoDaysBefore => t.settings.reminderTwoDaysBefore,
    ShoppingReminderSlot.dayBefore => t.settings.reminderDayBefore,
    ShoppingReminderSlot.sameDayMorning => t.settings.reminderSameDayMorning,
    ShoppingReminderSlot.sameDayAfternoon =>
      t.settings.reminderSameDayAfternoon,
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.base,
          runSpacing: AppSpacing.base,
          children: [
            for (final slot in ShoppingReminderSlot.values)
              _SlotChip(
                label: _label(slot),
                isOn: selected.contains(slot),
                onTap: () => onChanged([
                  for (final s in ShoppingReminderSlot.values)
                    if (s == slot
                        ? !selected.contains(slot)
                        : selected.contains(s))
                      s,
                ]),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.base),
        Text(
          t.settings.shoppingRemindersHint,
          style: AppTextStyles.labelMd.copyWith(color: AppColors.outline),
        ),
      ],
    );
  }
}

class _SlotChip extends StatelessWidget {
  final String label;
  final bool isOn;
  final VoidCallback onTap;

  const _SlotChip({
    required this.label,
    required this.isOn,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ink = isOn ? AppColors.onPrimary : AppColors.tertiary;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.base,
        ),
        decoration: ShapeDecoration(
          color: isOn ? AppColors.primary : AppColors.surfaceContainerLow,
          shape: StadiumBorder(
            side: BorderSide(
              color: isOn ? AppColors.primary : AppColors.outlineVariant,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isOn
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_none_rounded,
              size: 16,
              color: ink,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(label, style: AppTextStyles.labelMd.copyWith(color: ink)),
          ],
        ),
      ),
    );
  }
}
