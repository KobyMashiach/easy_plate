import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/allergen_chip_selector.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../../../core/widgets/dietary_chip_selector.dart';
import '../../../../core/widgets/error_retry_view.dart';
import '../../../../core/widgets/weekday_selector.dart';
import '../../../user_profile/domain/entities/user_preferences_entity.dart';
import '../bloc/settings_bloc.dart';
import '../widgets/settings_widgets.dart';
import '../../../../core/features/feature_gate.dart';
import '../../../../core/walkthrough/walkthrough.dart';
import '../../../../core/walkthrough/app_walkthroughs.dart';

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
        body: BlocConsumer<SettingsBloc, SettingsState>(
          listenWhen: SettingsBloc.saveFailedBetween,
          listener: (context, _) =>
              AppDialog.error(message: t.settings.saveFailed).notify(context),
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
    return SettingsBody(
      title: t.preferences.title,
      rows: preferenceRows(context.read<SettingsBloc>(), preferences),
    );
  }
}

/// The rows of העדפות, also drawn on the onboarding screen (without the
/// guided-tour anchors, which belong to this screen's tour).
List<Widget> preferenceRows(
  SettingsBloc bloc,
  UserPreferencesEntity preferences, {
  bool tourTargets = true,
}) {
  Widget target(String id, Widget child) =>
      tourTargets ? WalkthroughTarget(id: id, child: child) : child;
  return [
    SettingsGroupLabel(t.preferences.shopping),
    target(
      WalkthroughIds.prefsShoppingDay,
      // Closed in any way, the card is the one-day picker it always was.
      FeatureGate.builder(
        feature: FeaturesFlags.multiShoppingDays,
        builder: (context, access) => access.isEnabled
            ? SettingsCard(
                title: t.settings.shoppingDays,
                description: t.settings.shoppingDaysHint,
                child: WeekdaySelector.multiple(
                  selected: preferences.shoppingDays,
                  onChanged: (days) => bloc.add(.updateShoppingDays(days)),
                ),
              )
            : SettingsCard(
                title: t.settings.shoppingDay,
                child: WeekdaySelector(
                  selected: preferences.shoppingDay,
                  onSelect: (day) => bloc.add(.updateShoppingDays([day])),
                ),
              ),
      ),
    ),
    FeatureGate(
      feature: FeaturesFlags.priceBook,
      child: target(
        WalkthroughIds.prefsCommunityPrices,
        SettingsToggle(
          title: t.settings.communityPrices,
          description: t.settings.communityPricesHint,
          value: preferences.communityPricesEnabled,
          onChanged: (enabled) => bloc.add(.toggleCommunityPrices(enabled)),
        ),
      ),
    ),
    SettingsGroupLabel(t.settings.dietaryPreferences),
    target(
      WalkthroughIds.prefsDietary,
      SettingsCard(
        title: t.settings.dietaryPreferences,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DietaryChipSelector(
              selected: preferences.dietaryPreferences,
              onToggle: (pref) => bloc.add(.toggleDietaryPreference(pref)),
            ),
            // Which allergens, once "allergy" is on: what the recipe
            // suggestions then leave out.
            if (preferences.dietaryPreferences.contains(
              DietaryPreference.allergy,
            )) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                t.allergens.avoid,
                style: AppTextStyles.labelSm.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.base),
              AllergenChipSelector(
                selected: preferences.allergens,
                onToggle: (a) => bloc.add(.toggleAllergen(a)),
              ),
            ],
          ],
        ),
      ),
    ),
    SettingsGroupLabel(t.preferences.books),
    target(
      WalkthroughIds.prefsFastPageTurn,
      SettingsToggle(
        title: t.settings.fastPageTurn,
        description: t.settings.fastPageTurnHint,
        value: preferences.fastPageTurnEnabled,
        onChanged: (enabled) => bloc.add(.toggleFastPageTurn(enabled)),
      ),
    ),
    target(
      WalkthroughIds.prefsSound,
      SettingsToggle(
        title: t.settings.soundEffects,
        value: preferences.soundEffectsEnabled,
        onChanged: (enabled) => bloc.add(.toggleSoundEffects(enabled)),
      ),
    ),
  ];
}
