import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../../../core/widgets/dietary_chip_selector.dart';
import '../../../../core/widgets/error_retry_view.dart';
import '../../../../core/widgets/weekday_selector.dart';
import '../../../user_profile/domain/entities/user_preferences_entity.dart';
import '../bloc/settings_bloc.dart';
import '../widgets/settings_widgets.dart';

/// העדפות — how the app behaves for this account: the shopping day, dietary
/// needs, price estimates, and how the books turn their pages.
class PreferencesPage extends StatelessWidget {
  const PreferencesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SettingsBloc.fromContext(context),
      child: ClayScaffold(
        appBar: ClayTopAppBar(
          title: t.preferences.title,
          leadingIcon: Icons.arrow_back_rounded,
          onLeadingTap: () => Navigator.of(context).maybePop(),
        ),
        body: BlocBuilder<SettingsBloc, SettingsState>(
          builder: (context, state) {
            return switch (state) {
              SettingsLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
              SettingsLoaded(preferences: final preferences) => _Body(
                preferences: preferences,
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

class _Body extends StatelessWidget {
  final UserPreferencesEntity preferences;

  const _Body({required this.preferences});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<SettingsBloc>();

    return SettingsBody(
      title: t.preferences.title,
      rows: [
        SettingsGroupLabel(t.preferences.shopping),
        SettingsCard(
          title: t.settings.shoppingDay,
          child: WeekdaySelector(
            selected: preferences.shoppingDay,
            onSelect: (day) => bloc.add(.updateShoppingDay(day)),
          ),
        ),
        SettingsToggle(
          title: t.settings.communityPrices,
          description: t.settings.communityPricesHint,
          value: preferences.communityPricesEnabled,
          onChanged: (enabled) => bloc.add(.toggleCommunityPrices(enabled)),
        ),
        SettingsGroupLabel(t.settings.dietaryPreferences),
        SettingsCard(
          title: t.settings.dietaryPreferences,
          child: DietaryChipSelector(
            selected: preferences.dietaryPreferences,
            onToggle: (pref) => bloc.add(.toggleDietaryPreference(pref)),
          ),
        ),
        SettingsGroupLabel(t.preferences.books),
        SettingsToggle(
          title: t.settings.fastPageTurn,
          description: t.settings.fastPageTurnHint,
          value: preferences.fastPageTurnEnabled,
          onChanged: (enabled) => bloc.add(.toggleFastPageTurn(enabled)),
        ),
        SettingsToggle(
          title: t.settings.soundEffects,
          value: preferences.soundEffectsEnabled,
          onChanged: (enabled) => bloc.add(.toggleSoundEffects(enabled)),
        ),
      ],
    );
  }
}
