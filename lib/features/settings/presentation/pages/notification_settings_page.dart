import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../../../core/widgets/error_retry_view.dart';
import '../../../user_profile/domain/entities/user_preferences_entity.dart';
import '../bloc/settings_bloc.dart';
import '../widgets/settings_widgets.dart';

/// Every alert the app can send, each behind its own switch. The choices
/// are saved with the account's preferences, which the Cloud Functions
/// read before writing an inbox item or sending a push — so a switch here
/// is honoured at the source, not just hidden on this phone.
class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage>
    with WidgetsBindingObserver {
  /// Whether the OS lets EasyPlate post notifications at all. Null until
  /// asked, and re-asked on every resume: the user may have just come back
  /// from the device settings.
  bool? _systemAllowed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkSystemPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkSystemPermission();
  }

  Future<void> _checkSystemPermission() async {
    try {
      final settings = await FirebaseMessaging.instance
          .getNotificationSettings();
      final allowed =
          settings.authorizationStatus != AuthorizationStatus.denied;
      if (mounted && allowed != _systemAllowed) {
        setState(() => _systemAllowed = allowed);
      }
    } catch (e) {
      // Without Firebase (tests, a broken start) there is nothing to say.
      debugPrint('Notification permission check failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SettingsBloc.fromContext(context),
      child: ClayScaffold(
        appBar: ClayTopAppBar(
          title: t.notificationSettings.title,
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
                systemAllowed: _systemAllowed,
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
  final bool? systemAllowed;

  const _Body({required this.preferences, required this.systemAllowed});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<SettingsBloc>();
    final push = preferences.pushEnabled;

    SettingsToggle row(
      NotificationSetting setting, {
      required String title,
      String? description,
      bool dependsOnPush = true,
    }) {
      return SettingsToggle(
        title: title,
        description: description,
        value: setting.of(preferences),
        // With the master switch off the rows below it are moot; drawn
        // disabled rather than hidden so the choices are not lost.
        onChanged: dependsOnPush && !push
            ? null
            : (enabled) => bloc.add(.setNotification(setting, enabled)),
      );
    }

    return SettingsBody(
      title: t.notificationSettings.title,
      rows: [
        if (systemAllowed == false) const _SystemDeniedNote(),
        row(
          NotificationSetting.push,
          title: t.notificationSettings.push,
          description: t.notificationSettings.pushHint,
          dependsOnPush: false,
        ),
        SettingsGroupLabel(t.notificationSettings.community),
        row(
          NotificationSetting.repliesOnMyPosts,
          title: t.notificationSettings.repliesOnMyPosts,
          description: t.notificationSettings.repliesOnMyPostsHint,
        ),
        row(
          NotificationSetting.repliesOnThreads,
          title: t.notificationSettings.repliesOnThreads,
          description: t.notificationSettings.repliesOnThreadsHint,
        ),
        SettingsGroupLabel(t.notificationSettings.sharing),
        row(
          NotificationSetting.shareInvites,
          title: t.notificationSettings.shareInvites,
          description: t.notificationSettings.shareInvitesHint,
        ),
        row(
          NotificationSetting.sharedRecipeUpdates,
          title: t.notificationSettings.sharedRecipeUpdates,
          description: t.notificationSettings.sharedRecipeUpdatesHint,
        ),
        SettingsGroupLabel(t.notificationSettings.easyPlate),
        row(
          NotificationSetting.adminReplies,
          title: t.notificationSettings.adminReplies,
        ),
        row(
          NotificationSetting.announcements,
          title: t.notificationSettings.announcements,
          description: t.notificationSettings.announcementsHint,
        ),
        SettingsGroupLabel(t.notificationSettings.inApp),
        row(
          NotificationSetting.foregroundPopups,
          title: t.notificationSettings.foregroundPopups,
          description: t.notificationSettings.foregroundPopupsHint,
        ),
        SettingsGroupLabel(t.notificationSettings.reminders),
        // Scheduled on the device, not pushed: independent of the master
        // switch above, which only governs what the server sends.
        SettingsCard(
          title: t.settings.shoppingReminders,
          child: ReminderSlotPicker(
            selected: preferences.shoppingReminderSlots,
            onChanged: (slots) => bloc.add(.setShoppingReminders(slots)),
          ),
        ),
      ],
    );
  }
}

/// The device itself refuses our notifications: nothing here can change
/// that, so say so at the top.
class _SystemDeniedNote extends StatelessWidget {
  const _SystemDeniedNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.errorContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.notifications_off_rounded,
            size: 20,
            color: AppColors.onErrorContainer,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              t.notificationSettings.pushDenied,
              style: AppTextStyles.labelMd.copyWith(
                color: AppColors.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
