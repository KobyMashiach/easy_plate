import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/dietary_chip_selector.dart';
import '../../../../core/widgets/error_retry_view.dart';
import '../../../user_profile/domain/entities/user_preferences_entity.dart';
import '../../../../core/widgets/weekday_selector.dart';
import '../bloc/settings_bloc.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SettingsBloc.fromContext(context),
      child: Scaffold(
        appBar: AppBar(title: Text(t.settings.title)),
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
      padding: const EdgeInsets.all(24),
      children: [
        Text(t.settings.shoppingDay, style: AppTextStyles.pageHeading),
        const SizedBox(height: 12),
        WeekdaySelector(
          selected: preferences.shoppingDay,
          onSelect: (day) => bloc.add(.updateShoppingDay(day)),
        ),
        const SizedBox(height: 32),
        Text(t.settings.dietaryPreferences, style: AppTextStyles.pageHeading),
        const SizedBox(height: 12),
        DietaryChipSelector(
          selected: preferences.dietaryPreferences,
          onToggle: (pref) => bloc.add(.toggleDietaryPreference(pref)),
        ),
        const SizedBox(height: 32),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(t.settings.soundEffects, style: AppTextStyles.pageHeading),
          value: preferences.soundEffectsEnabled,
          onChanged: (enabled) => bloc.add(.toggleSoundEffects(enabled)),
        ),
        const SizedBox(height: 32),
        Text(t.settings.sharedAccess, style: AppTextStyles.pageHeading),
        const SizedBox(height: 12),
        if (sharedBooksCount == 0 && sharedListsCount == 0)
          Text(t.settings.noSharedAccess, style: AppTextStyles.caption)
        else ...[
          if (sharedBooksCount > 0) Text('$sharedBooksCount ${t.books.myLibrary}'),
          if (sharedListsCount > 0) Text('$sharedListsCount ${t.groceryList.title}'),
        ],
      ],
    );
  }
}
