import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/features/feature_gate.dart';
import '../../../../core/services/auth_session_service.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/utils/routing/routing.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../../../core/widgets/error_retry_view.dart';
import '../../../../core/widgets/language_selector.dart';
import '../../../../core/widgets/theme_mode_selector.dart';
import '../../../settings/presentation/bloc/settings_bloc.dart';
import '../../../settings/presentation/pages/preferences_page.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../../../settings/presentation/widgets/settings_widgets.dart';
import '../../../user_profile/domain/entities/user_preferences_entity.dart';
import '../bloc/onboarding_bloc.dart';

/// The first screen of a new account: look and language, then everything
/// on the העדפות screen (shopping days, prices, diet, books). Each choice
/// is saved as it is made, through the same SettingsBloc as there; Finish
/// only marks the onboarding done, once those saves have landed.
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SettingsBloc.fromContext(context),
      child: Builder(
        builder: (context) {
          final settings = context.read<SettingsBloc>();
          return BlocProvider(
            create: (context) => OnboardingBloc.fromContext(
              context,
              settled: () => settings.idle,
            ),
            child: BlocListener<SettingsBloc, SettingsState>(
              listenWhen: SettingsBloc.saveFailedBetween,
              listener: (context, _) => AppDialog.error(
                message: t.settings.saveFailed,
              ).notify(context),
              child: BlocConsumer<OnboardingBloc, OnboardingState>(
                listener: (context, state) {
                  if (state is Complete) {
                    // Lets the auth gate stop redirecting back here before
                    // we navigate.
                    AuthSessionService().markOnboardingComplete();
                    context.go(Routing.home);
                  }
                  if (state case Editing(saveFailed: true)) {
                    AppDialog.error(
                      message: t.onboarding.saveFailed,
                    ).show(context);
                  }
                },
                builder: (context, state) => ClayScaffold(
                  body: SafeArea(
                    child: switch (state) {
                      Editing() => const _Form(),
                      Saving() || Complete() => const Center(
                        child: CircularProgressIndicator(),
                      ),
                    },
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Form extends StatelessWidget {
  const _Form();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) => switch (state) {
        SettingsLoading() => const Center(child: CircularProgressIndicator()),
        SettingsError(error: final error) => ErrorRetryView(
          error: error,
          onRetry: () => context.read<SettingsBloc>().add(
            const SettingsEvent.init(),
          ),
        ),
        SettingsLoaded(preferences: final preferences) => _Rows(
          preferences: preferences,
        ),
      },
    );
  }
}

class _Rows extends StatelessWidget {
  final UserPreferencesEntity preferences;

  const _Rows({required this.preferences});

  @override
  Widget build(BuildContext context) {
    final settings = context.read<SettingsBloc>();
    final rows = <Widget>[
      const _Welcome(),
      SettingsGroupLabel(t.onboarding.lookAndLanguage),
      // Device-wide, as on the settings screen: see ThemeController.
      FeatureGate(
        feature: FeaturesFlags.theming,
        child: SettingsCard(
          title: t.settings.appearance,
          child: ThemeModeSelector(
            onChanged: (mode) =>
                settings.add(SettingsEvent.setThemeMode(mode.name)),
          ),
        ),
      ),
      SettingsCard(
        title: t.settings.language,
        child: LanguageSelector(
          selected: preferences.language,
          onSelect: (language) =>
              changeAppLanguage(context, settings, language),
        ),
      ),
      ...preferenceRows(settings, preferences, tourTargets: false),
      const SizedBox(height: AppSpacing.sm),
      ClayButton(
        label: t.onboarding.finish,
        // Forward in every language: the icon mirrors itself under RTL.
        icon: Icons.arrow_forward_rounded,
        expanded: true,
        onPressed: () =>
            context.read<OnboardingBloc>().add(const OnboardingEvent.finish()),
      ),
    ];
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.marginMobile),
      itemCount: rows.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) => rows[index],
    );
  }
}

class _Welcome extends StatelessWidget {
  const _Welcome();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: AppSpacing.md),
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: AppColors.primaryFixed,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.restaurant_menu_rounded,
            size: 60,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          t.onboarding.welcomeTitle,
          textAlign: TextAlign.center,
          style: AppTextStyles.headlineLgMobile,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          t.onboarding.welcomeSubtitle,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMd.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }
}
