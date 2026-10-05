import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_enums.dart';
import '../../../../core/translation/content_translation_service.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/utils/routing/routing.dart';
import '../../../../core/walkthrough/app_walkthroughs.dart';
import '../../../../core/walkthrough/walkthrough.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../../../core/widgets/error_retry_view.dart';
import '../../../../core/widgets/language_selector.dart';
import '../../../../core/widgets/theme_mode_selector.dart';
import '../../../user_profile/domain/entities/user_preferences_entity.dart';
import '../bloc/settings_bloc.dart';
import '../widgets/settings_widgets.dart';

/// הגדרות — the account and the app: who you are, what reaches you, which
/// language and look. What the app *does* for you (shopping day, dietary
/// needs, how the books turn) lives on the preferences screen instead.
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
              SettingsLoaded(preferences: final preferences) => _SettingsBody(
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

class _SettingsBody extends StatelessWidget {
  final UserPreferencesEntity preferences;

  const _SettingsBody({required this.preferences});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<SettingsBloc>();

    return SettingsBody(
      title: t.settings.title,
      rows: [
        SettingsGroupLabel(t.settings.account),
        SettingsNavRow(
          icon: Icons.person_rounded,
          label: t.more.profile,
          onTap: () => context.pushNamed(Routing.profileEdit),
        ),
        SettingsNavRow(
          icon: Icons.group_rounded,
          label: t.settings.sharedAccess,
          onTap: () => context.pushNamed(Routing.sharing),
        ),
        SettingsGroupLabel(t.settings.notifications),
        SettingsNavRow(
          icon: Icons.notifications_rounded,
          label: t.notificationSettings.title,
          hint: t.settings.notificationsHint,
          onTap: () => context.pushNamed(Routing.notificationSettings),
        ),
        SettingsCard(
          title: t.settings.language,
          child: LanguageSelector(
            selected: preferences.language,
            onSelect: (language) => _changeLanguage(context, bloc, language),
          ),
        ),
        // Device-wide, not part of the account's preferences: see ThemeController.
        WalkthroughTarget(
          id: WalkthroughIds.settingsTheme,
          child: SettingsCard(
            title: t.settings.appearance,
            child: const ThemeModeSelector(),
          ),
        ),
      ],
    );
  }
}

/// Switches the app's language, then rewrites the account's own recipes,
/// books, plans and lists into it. The switch lands first so the progress
/// card is already in the new language; the content follows behind it.
Future<void> _changeLanguage(
  BuildContext context,
  SettingsBloc bloc,
  AppLanguage language,
) async {
  final service = context.read<ContentTranslationService>();
  bloc.add(SettingsEvent.changeLanguage(language));
  // The bloc switches the locale on its own microtask; the strings below
  // should already be the new ones.
  await Future<void>.delayed(Duration.zero);
  if (!context.mounted) return;
  try {
    // A language this account has been in before is on the device already:
    // that switch is instant and gets no loading card.
    if (await service.isLocal(language)) {
      await service.switchTo(language);
      return;
    }
    if (!context.mounted) return;
    final outcome = await AppDialog.busy(
      context,
      () => service.switchTo(language),
      message: t.settings.translatingContent,
    );
    if (!context.mounted || outcome.didNothing) return;
    if (outcome.failed > 0) {
      AppDialog.warning(
        title: t.settings.translationPartialTitle,
        message: t.settings.translationPartial(count: outcome.failed),
        confirmLabel: t.common.ok,
      ).show(context);
      return;
    }
    AppDialog.success(
      message: t.settings.translatedContent(count: outcome.total),
    ).notify(context);
  } catch (e) {
    debugPrint('Content translation failed: $e');
    if (context.mounted) {
      AppDialog.error(message: t.settings.translationFailed).show(context);
    }
  }
}
