import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/i18n/app_language_mapper.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../../../core/widgets/dietary_chip_selector.dart';
import '../../../../core/widgets/error_retry_view.dart';
import '../../../../core/widgets/weekday_selector.dart';
import '../../../user_profile/domain/entities/user_preferences_entity.dart';
import '../bloc/settings_bloc.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SettingsBloc.fromContext(context),
      child: ClayScaffold(
        appBar: ClayTopAppBar(title: t.appName, leadingIcon: Icons.person_rounded),
        body: BlocBuilder<SettingsBloc, SettingsState>(
          builder: (context, state) {
            return switch (state) {
              SettingsLoading() => const Center(child: CircularProgressIndicator()),
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
                  onRetry: () => context.read<SettingsBloc>().add(const SettingsEvent.init()),
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

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.marginMobile,
        AppSpacing.md,
        AppSpacing.marginMobile,
        ClayNavDock.reservedHeight,
      ),
      children: [
        ClayPageHeader(title: t.settings.title),
        const SizedBox(height: AppSpacing.lg),
        _SettingsCard(
          title: t.settings.shoppingDay,
          child: WeekdaySelector(
            selected: preferences.shoppingDay,
            onSelect: (day) => bloc.add(.updateShoppingDay(day)),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _SettingsCard(
          title: t.settings.language,
          child: _LanguageSelector(
            selected: preferences.language,
            onSelect: (language) => bloc.add(.changeLanguage(language)),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _SettingsCard(
          title: t.settings.dietaryPreferences,
          child: DietaryChipSelector(
            selected: preferences.dietaryPreferences,
            onToggle: (pref) => bloc.add(.toggleDietaryPreference(pref)),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _SettingsToggle(
          title: t.settings.fastPageTurn,
          description: t.settings.fastPageTurnHint,
          value: preferences.fastPageTurnEnabled,
          onChanged: (enabled) => bloc.add(.toggleFastPageTurn(enabled)),
        ),
        const SizedBox(height: AppSpacing.md),
        _SettingsToggle(
          title: t.settings.soundEffects,
          value: preferences.soundEffectsEnabled,
          onChanged: (enabled) => bloc.add(.toggleSoundEffects(enabled)),
        ),
        const SizedBox(height: AppSpacing.md),
        _SettingsCard(
          title: t.settings.sharedAccess,
          child: sharedBooksCount == 0 && sharedListsCount == 0
              ? Text(
                  t.settings.noSharedAccess,
                  style: AppTextStyles.labelMd.copyWith(color: AppColors.outline),
                )
              : Wrap(
                  spacing: AppSpacing.base,
                  runSpacing: AppSpacing.base,
                  children: [
                    if (sharedBooksCount > 0)
                      ClayTag(
                        label: '$sharedBooksCount ${t.books.myLibrary}',
                        icon: Icons.menu_book_rounded,
                      ),
                    if (sharedListsCount > 0)
                      ClayTag(
                        label: '$sharedListsCount ${t.groceryList.title}',
                        icon: Icons.shopping_cart_rounded,
                        background: AppColors.secondaryContainer,
                        foreground: AppColors.onSecondaryContainer,
                      ),
                  ],
                ),
        ),
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
                    style: AppTextStyles.labelMd.copyWith(color: AppColors.outline),
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
class _LanguageSelector extends StatelessWidget {
  final AppLanguage selected;
  final ValueChanged<AppLanguage> onSelect;

  const _LanguageSelector({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.base,
      runSpacing: AppSpacing.base,
      children: AppLanguage.values.map((language) {
        final isSelected = language == selected;
        return GestureDetector(
          onTap: () => onSelect(language),
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.gutter,
              vertical: AppSpacing.base,
            ),
            decoration: ShapeDecoration(
              color: isSelected ? AppColors.primary : AppColors.surfaceContainerLow,
              shape: StadiumBorder(
                side: BorderSide(
                  color: isSelected ? AppColors.primary : AppColors.outlineVariant,
                ),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected) ...[
                  const Icon(Icons.check_rounded, size: 16, color: AppColors.onPrimary),
                  const SizedBox(width: AppSpacing.xs),
                ],
                Text(
                  language.label,
                  style: AppTextStyles.labelMd.copyWith(
                    color: isSelected ? AppColors.onPrimary : AppColors.tertiary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final String title;
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
          ClaySectionHeader(title: title),
          const SizedBox(height: AppSpacing.gutter),
          child,
        ],
      ),
    );
  }
}
