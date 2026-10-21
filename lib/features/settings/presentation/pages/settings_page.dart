import 'dart:async';

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
import '../../../../core/features/feature_gate.dart';
import '../../../../core/services/account_deletion_guard.dart';
import '../../../../core/services/presence_service.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../data/account_deletion_remote_datasource.dart';

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
        body: BlocConsumer<SettingsBloc, SettingsState>(
          listenWhen: SettingsBloc.saveFailedBetween,
          listener: (context, _) =>
              AppDialog.error(message: t.settings.saveFailed).notify(context),
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
        WalkthroughTarget(
          id: WalkthroughIds.settingsProfile,
          child: SettingsNavRow(
            icon: Icons.person_rounded,
            label: t.more.profile,
            onTap: () => context.pushNamed(Routing.profileEdit),
          ),
        ),
        FeatureGate.any(
          features: const [
            FeaturesFlags.shareRecipes,
            FeaturesFlags.shareBooks,
            FeaturesFlags.sharePlans,
            FeaturesFlags.shareGroceryLists,
          ],
          child: WalkthroughTarget(
            id: WalkthroughIds.settingsSharing,
            child: SettingsNavRow(
              icon: Icons.group_rounded,
              label: t.settings.sharedAccess,
              onTap: () => context.pushNamed(Routing.sharing),
            ),
          ),
        ),
        FeatureGate(
          feature: FeaturesFlags.notifications,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SettingsGroupLabel(t.settings.notifications),
              WalkthroughTarget(
                id: WalkthroughIds.settingsNotifications,
                child: SettingsNavRow(
                  icon: Icons.notifications_rounded,
                  label: t.notificationSettings.title,
                  hint: t.settings.notificationsHint,
                  onTap: () => context.pushNamed(Routing.notificationSettings),
                ),
              ),
            ],
          ),
        ),
        WalkthroughTarget(
          id: WalkthroughIds.settingsLanguage,
          child: SettingsCard(
            title: t.settings.language,
            child: LanguageSelector(
              selected: preferences.language,
              onSelect: (language) => _changeLanguage(context, bloc, language),
            ),
          ),
        ),
        // The home-screen widgets and their defaults; device-wide too.
        FeatureGate(
          feature: FeaturesFlags.homeWidgets,
          child: SettingsNavRow(
            icon: Icons.widgets_rounded,
            label: t.homeWidgets.title,
            hint: t.homeWidgets.hint,
            onTap: () => context.pushNamed(Routing.homeWidgets),
          ),
        ),
        // "Hey Shefi": device-wide, and only where Shefi and talking to it
        // are both open (a locked Shefi shows its tag and leads to it).
        FeatureGate(
          feature: FeaturesFlags.wakeWord,
          child: FeatureGate(
            feature: FeaturesFlags.assistantVoice,
            child: FeatureGate(
              feature: FeaturesFlags.assistant,
              child: SettingsNavRow(
                icon: Icons.record_voice_over_rounded,
                label: t.wakeWord.title,
                hint: t.wakeWord.hint,
                onTap: () => context.pushNamed(Routing.wakeWord),
              ),
            ),
          ),
        ),
        // Device-wide, not part of the account's preferences: see ThemeController.
        FeatureGate(
          feature: FeaturesFlags.theming,
          child: WalkthroughTarget(
            id: WalkthroughIds.settingsTheme,
            child: SettingsCard(
              title: t.settings.appearance,
              child: ThemeModeSelector(
                onChanged: (mode) =>
                    bloc.add(SettingsEvent.setThemeMode(mode.name)),
              ),
            ),
          ),
        ),
        // The stores require account deletion to be reachable in the app.
        // No feature flag on purpose: it may never be hidden.
        SettingsGroupLabel(t.settings.dangerZone),
        WalkthroughTarget(
          id: WalkthroughIds.settingsDeleteAccount,
          child: SettingsNavRow(
            icon: Icons.delete_forever_rounded,
            label: t.settings.deleteAccount,
            hint: t.settings.deleteAccountHint,
            destructive: true,
            onTap: () => _deleteAccount(context),
          ),
        ),
      ],
    );
  }
}

/// Deletes the account for good, after one explicit confirmation that
/// spells out what goes. The server does the removal (it needs the Admin
/// SDK); signing out afterwards is what empties this device.
Future<void> _deleteAccount(BuildContext context) async {
  final auth = context.read<AuthRepository>();
  final confirmed = await AppDialog.warning(
    title: t.settings.deleteAccountTitle,
    message: t.settings.deleteAccountBody,
    icon: Icons.delete_forever_rounded,
    confirmLabel: t.settings.deleteAccountConfirm,
    cancelLabel: t.common.cancel,
    destructive: true,
  ).show(context);
  if (confirmed != true || !context.mounted) return;
  // Presence quiet for the whole call: a heartbeat during it, or the
  // offline mark sign-out writes after it, would recreate the users/{uid}
  // document the server has just deleted. Back on if the delete fails.
  final reporting = PresenceService().halt();
  void resumePresence() {
    if (reporting != null) PresenceService().start(reporting);
  }

  try {
    await AppDialog.busy(
      context,
      () => AccountDeletionGuard.guard(
        () => AccountDeletionRemoteDataSource().deleteMyAccount(),
      ),
      message: t.settings.deletingAccount,
    );
  } on AccountDeletionRefused {
    resumePresence();
    if (context.mounted) {
      AppDialog.error(message: t.settings.deleteAccountHousehold).show(context);
    }
    return;
  } catch (e) {
    debugPrint('Account deletion failed: $e');
    resumePresence();
    if (context.mounted) {
      AppDialog.error(message: t.settings.deleteAccountFailed).show(context);
    }
    return;
  }
  // The Auth user is gone on the server; signing out drops the session,
  // the local boxes and the Google/Apple session, and the gate shows the
  // sign-in screen.
  try {
    await auth.signOut();
  } catch (e) {
    debugPrint('Sign-out after deletion: $e');
  }
}

/// The content switch in progress, and the newest one asked for. Two
/// switches overlapping (the second picked while the first, instant one
/// still re-saved the library) each wrote against what it read before the
/// other's writes, and the library ended up in a mix of both. They run one
/// at a time, and one overtaken by a newer pick while it waited is dropped.
Future<void> _languageQueue = Future.value();
int _languageRequest = 0;

/// Switches the app's language, then rewrites the account's own recipes,
/// books, plans and lists into it. The switch lands first so the progress
/// card is already in the new language; the content follows behind it.
Future<void> _changeLanguage(
  BuildContext context,
  SettingsBloc bloc,
  AppLanguage language,
) async {
  final service = context.read<ContentTranslationService>();
  final request = ++_languageRequest;
  final saved = Completer<bool>();
  bloc.add(SettingsEvent.changeLanguage(language, saved: saved));
  // Switched off in the console: the interface changes language, the
  // account's own content stays as written.
  if (!FeaturesFlags.contentTranslation.isEnabled) return;
  // Wait for the save itself, not for the record on screen to carry the
  // new language: the bloc shows a change before persisting it, so a
  // refused save used to have its content translated anyway. A refused
  // switch leaves the content as it is.
  if (!await saved.future || !context.mounted) return;
  final previous = _languageQueue;
  final turn = Completer<void>();
  _languageQueue = turn.future;
  try {
    await previous;
    if (request != _languageRequest || !context.mounted) return;
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
  } finally {
    turn.complete();
  }
}
