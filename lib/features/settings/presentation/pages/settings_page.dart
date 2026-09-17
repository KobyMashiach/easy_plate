import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../../../core/widgets/dietary_chip_selector.dart';
import '../../../../core/widgets/error_retry_view.dart';
import '../../../../core/widgets/language_selector.dart';
import '../../../../core/widgets/theme_mode_selector.dart';
import '../../../../core/widgets/weekday_selector.dart';
import '../../../user_profile/domain/entities/user_preferences_entity.dart';
import '../bloc/settings_bloc.dart';
import '../../../../core/walkthrough/app_walkthroughs.dart';
import '../../../../core/walkthrough/walkthrough.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SettingsBloc.fromContext(context),
      child: ClayScaffold(
        appBar: ClayTopAppBar(
          title: t.more.settings,
          leadingIcon: Icons.arrow_back_rounded,
          onLeadingTap: () => Navigator.of(context).maybePop(),
        ),
        body: BlocBuilder<SettingsBloc, SettingsState>(
          builder: (context, state) {
            return switch (state) {
              SettingsLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
              SettingsLoaded(
                preferences: final preferences,
                sharedBooksCount: final sharedBooks,
                sharedListsCount: final sharedLists,
              ) =>
                _SettingsBody(
                  preferences: preferences,
                  sharedBooksCount: sharedBooks,
                  sharedListsCount: sharedLists,
                ),
              SettingsError(error: final error) => ErrorRetryView(
                error: error,
                onRetry: () => context.read<SettingsBloc>().add(
                  const SettingsEvent.init(),
                ),
              ),
            };
          },
        ),
      ),
    );
  }
}

class _SettingsBody extends StatelessWidget {
  final UserPreferencesEntity preferences;
  final int sharedBooksCount;
  final int sharedListsCount;

  const _SettingsBody({
    required this.preferences,
    required this.sharedBooksCount,
    required this.sharedListsCount,
  });

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<SettingsBloc>();

    final sections = <Widget>[
      _SettingsCard(
        title: t.settings.shoppingDay,
        child: WeekdaySelector(
          selected: preferences.shoppingDay,
          onSelect: (day) => bloc.add(.updateShoppingDay(day)),
        ),
      ),
      _SettingsCard(
        title: t.settings.shoppingReminders,
        child: _ReminderSlotPicker(
          selected: preferences.shoppingReminderSlots,
          onChanged: (slots) => bloc.add(.setShoppingReminders(slots)),
        ),
      ),
      _SettingsCard(
        title: t.settings.dietaryPreferences,
        child: DietaryChipSelector(
          selected: preferences.dietaryPreferences,
          onToggle: (pref) => bloc.add(.toggleDietaryPreference(pref)),
        ),
      ),
      _SettingsToggle(
        title: t.settings.fastPageTurn,
        description: t.settings.fastPageTurnHint,
        value: preferences.fastPageTurnEnabled,
        onChanged: (enabled) => bloc.add(.toggleFastPageTurn(enabled)),
      ),
      _SettingsToggle(
        title: t.settings.communityPrices,
        description: t.settings.communityPricesHint,
        value: preferences.communityPricesEnabled,
        onChanged: (enabled) => bloc.add(.toggleCommunityPrices(enabled)),
      ),
      _SettingsToggle(
        title: t.settings.soundEffects,
        value: preferences.soundEffectsEnabled,
        onChanged: (enabled) => bloc.add(.toggleSoundEffects(enabled)),
      ),
      _SettingsCard(
        title: t.settings.language,
        child: LanguageSelector(
          selected: preferences.language,
          onSelect: (language) => bloc.add(.changeLanguage(language)),
        ),
      ),
      // Device-wide, not part of the account's preferences: see ThemeController.
      const WalkthroughTarget(
        id: WalkthroughIds.settingsTheme,
        child: _SettingsCard(
          title: null,
          child: ThemeModeSelector(),
        ),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The heading sits outside the list so it stays put while the
        // settings scroll under it.
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.marginMobile,
            AppSpacing.md,
            AppSpacing.marginMobile,
            0,
          ),
          child: ClayPageHeader(title: t.settings.title),
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
            itemCount: sections.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) => sections[index],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

/// Clay card holding a single switch, with room for a line explaining what the
/// setting changes.
class _SettingsToggle extends StatelessWidget {
  final String title;
  final String? description;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsToggle({
    required this.title,
    required this.value,
    required this.onChanged,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
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
                Text(title, style: AppTextStyles.bodyMd),
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

/// Pill list of the shipped UI languages, each shown in its own script so the
/// choice is readable whatever the current locale.
class _SettingsCard extends StatelessWidget {
  /// Null reads the appearance heading — the one card whose title is not a
  /// build-time string, because the selector's own label set lives with it.
  final String? title;
  final Widget child;

  const _SettingsCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return ClayCard(
      radius: AppRadius.md,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClaySectionHeader(title: title ?? t.settings.appearance),
          const SizedBox(height: AppSpacing.gutter),
          child,
        ],
      ),
    );
  }
}

/// Which reminders to get before the shopping day: four fixed moments,
/// any mix of them. None is allowed — some people want no nagging.
class _ReminderSlotPicker extends StatelessWidget {
  final List<ShoppingReminderSlot> selected;
  final ValueChanged<List<ShoppingReminderSlot>> onChanged;

  const _ReminderSlotPicker({required this.selected, required this.onChanged});

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
