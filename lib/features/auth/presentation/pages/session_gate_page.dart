import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/services/auth_session_service.dart';
import '../../../../core/services/device_session_service.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../domain/repositories/auth_repository.dart';
import '../widgets/session_takeover_sheet.dart';

/// Where a device that may not hold the account is kept: another device
/// has the session (with a way to try again once it signed out), or the
/// month ran out (with the way back to sign in). Nothing else is reachable
/// while the session's stage is [AuthStage.otherDevice] or
/// [AuthStage.sessionExpired].
class SessionGatePage extends StatelessWidget {
  const SessionGatePage({super.key});

  Future<void> _requestRelease(BuildContext context) async {
    final outcome = await AppDialog.busy(
      context,
      AuthSessionService().requestRelease,
    );
    if (!context.mounted) return;
    final message = switch (outcome) {
      ReleaseOutcome.notified => t.auth.sessionRequestSent,
      ReleaseOutcome.queued => t.auth.sessionRequestQueued,
      ReleaseOutcome.free => null,
      ReleaseOutcome.failed => t.auth.sessionRequestFailed,
    };
    if (message == null) return;
    final takeover = DeviceSessionService().takeoverAt.value;
    final dialog = outcome == ReleaseOutcome.failed
        ? AppDialog.error(message: message)
        : AppDialog.info(
            message: takeover == null
                ? message
                : '$message ${_takeoverText(takeover)}',
          );
    await dialog.show(context);
  }

  /// "If the other device doesn't answer, you're in here on …": a phone
  /// that was lost or wiped cannot answer, and the account must not stay
  /// locked for the rest of its month.
  static String _takeoverText(DateTime at) {
    final locale = LocaleSettings.currentLocale.languageCode;
    final local = at.toLocal();
    return t.auth.sessionRequestTakeover(
      when:
          '${DateFormat.MMMd(locale).format(local)} ${DateFormat.Hm(locale).format(local)}',
    );
  }

  String _platformName(String platform) => switch (platform) {
    'ios' || 'macos' => t.auth.platformIos,
    'android' => t.auth.platformAndroid,
    _ => t.auth.platformOther,
  };

  @override
  Widget build(BuildContext context) {
    final session = AuthSessionService();
    final other = session.stage == AuthStage.otherDevice;
    final refusal = session.sessionRefusal;
    final String body;
    if (other) {
      final since = refusal?.since;
      body = t.auth.sessionOtherDeviceBody(
        platform: _platformName(refusal?.platform ?? 'other'),
        since: since == null
            ? ''
            : t.auth.sessionSince(
                date: DateFormat.yMMMd(
                  LocaleSettings.currentLocale.languageCode,
                ).format(since),
              ),
      );
    } else {
      body = t.auth.sessionExpiredBody;
    }
    return ClayScaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: ClayCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primaryFixed,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      other
                          ? Icons.devices_other_rounded
                          : Icons.schedule_rounded,
                      size: 36,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.gutter),
                  Text(
                    other
                        ? t.auth.sessionOtherDeviceTitle
                        : t.auth.sessionExpiredTitle,
                    style: AppTextStyles.headlineMd,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    body,
                    style: AppTextStyles.bodyMd.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (other) ...[
                    // Asks the device holding the account to sign out; the
                    // gate moves on by itself once it does.
                    ClayButton(
                      label: t.auth.sessionRequestRelease,
                      icon: Icons.phonelink_erase_rounded,
                      expanded: true,
                      onPressed: () => _requestRelease(context),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    // The other phone is lost, wiped or out of reach: a new
                    // SMS code to the account's number, and this device takes
                    // the session over (the other one is signed out).
                    ClayButton(
                      label: t.auth.sessionTakeover,
                      icon: Icons.sms_rounded,
                      expanded: true,
                      onPressed: () => showSessionTakeoverSheet(context),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ValueListenableBuilder<bool>(
                      valueListenable: session.releaseDeclined,
                      builder: (context, declined, _) => declined
                          ? Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.sm,
                              ),
                              child: Text(
                                t.auth.sessionRequestDeclined,
                                style: AppTextStyles.labelMd.copyWith(
                                  color: AppColors.error,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                    ValueListenableBuilder<DateTime?>(
                      valueListenable: DeviceSessionService().takeoverAt,
                      builder: (context, at, _) => at == null
                          ? const SizedBox.shrink()
                          : Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.sm,
                              ),
                              child: Text(
                                _takeoverText(at),
                                style: AppTextStyles.labelMd.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                    ),
                    // The other device signed out: claim again, and the gate
                    // moves on by itself when the server says yes.
                    ClayButton(
                      label: t.auth.sessionRetry,
                      icon: Icons.refresh_rounded,
                      expanded: true,
                      onPressed: () =>
                          AppDialog.busy(context, session.retrySession),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  ClayButton(
                    label: other ? t.auth.signOut : t.auth.signIn,
                    icon: Icons.logout_rounded,
                    expanded: true,
                    onPressed: () => _signOut(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A sign-out that throws (offline release of the session) says so rather
/// than ending as an uncaught error with nothing on screen.
Future<void> _signOut(BuildContext context) async {
  final auth = context.read<AuthRepository>();
  try {
    await AppDialog.busy(context, auth.signOut);
  } catch (e) {
    debugPrint('Sign-out failed: $e');
    if (context.mounted) {
      AppDialog.error(message: t.auth.errorUnknown).show(context);
    }
  }
}
