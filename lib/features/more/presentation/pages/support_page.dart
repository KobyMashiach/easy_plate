import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/services/auth_session_service.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/clay/clay.dart';

/// Two ways to reach a human. Both hand off to another app, so the only
/// failure worth handling is "that app isn't installed".
class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  static const supportPhone = '972508247743';
  static const supportEmail = 'support@easyplate.app';

  /// The signed-in identity goes in the message body so a reply does not have
  /// to start by asking who is writing.
  String get _signature {
    final session = AuthSessionService();
    final name = session.profile?.fullName ?? '';
    final uid = session.user?.uid ?? '';
    return '\n\n---\n$name\nID: $uid';
  }

  Future<void> _open(BuildContext context, Uri uri) async {
    final messenger = ScaffoldMessenger.of(context);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) {
      messenger.showSnackBar(
        SnackBar(content: Text(t.more.supportUnavailable, style: AppTextStyles.bodyMd)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClayScaffold(
      appBar: ClayTopAppBar(
        title: t.more.support,
        leadingIcon: Icons.arrow_back_rounded,
        onLeadingTap: () => Navigator.of(context).maybePop(),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.marginMobile),
          children: [
            const SizedBox(height: AppSpacing.lg),
            const Icon(Icons.support_agent_rounded, size: 64, color: AppColors.primary),
            const SizedBox(height: AppSpacing.lg),
            Text(
              t.more.supportTitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.headlineMd,
            ),
            const SizedBox(height: AppSpacing.base),
            Text(
              t.more.supportBody,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.xl),
            ClayButton(
              label: t.more.whatsapp,
              icon: Icons.chat_rounded,
              expanded: true,
              onPressed: () => _open(
                context,
                Uri.https('wa.me', '/$supportPhone', {'text': _signature.trim()}),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ClayButton(
              label: t.more.email,
              icon: Icons.mail_rounded,
              expanded: true,
              onPressed: () => _open(
                context,
                Uri(
                  scheme: 'mailto',
                  path: supportEmail,
                  // Built by hand rather than with queryParameters, which
                  // encodes spaces as '+' — mail clients show that literally.
                  query: 'subject=${Uri.encodeComponent(t.appName)}'
                      '&body=${Uri.encodeComponent(_signature)}',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
