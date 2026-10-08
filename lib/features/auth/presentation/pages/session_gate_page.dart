import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/services/auth_session_service.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../domain/repositories/auth_repository.dart';

/// Where a device that may not hold the account is kept: another device
/// has the session (with a way to try again once it signed out), or the
/// month ran out (with the way back to sign in). Nothing else is reachable
/// while the session's stage is [AuthStage.otherDevice] or
/// [AuthStage.sessionExpired].
class SessionGatePage extends StatelessWidget {
  const SessionGatePage({super.key});

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
                    onPressed: () => AppDialog.busy(
                      context,
                      context.read<AuthRepository>().signOut,
                    ),
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
