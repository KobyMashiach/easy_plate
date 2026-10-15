import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/services/auth_session_service.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/utils/routing/routing.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../../feedback/presentation/widgets/feedback_form.dart';
import '../../../../core/features/feature_gate.dart';

/// Ways to get help: the guide, a human by WhatsApp or mail, and a form for
/// a bug or a suggestion that lands in the administrator's inbox.
class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  /// From Remote Config (`support_phone`, `support_email`), so the console
  /// can change where help goes without a release. wa.me wants digits only.
  static String get supportPhone => FirebaseService()
      .remoteString(FirebaseService.supportPhoneKey)
      .replaceAll(RegExp(r'\D'), '');
  static String get supportEmail =>
      FirebaseService().remoteString(FirebaseService.supportEmailKey);

  /// Who is writing and from which build, under the space the user types
  /// in, so a reply does not have to start by asking. Only the lines that
  /// have a value; the labels in the user's language.
  Future<String> _signature() async {
    final session = AuthSessionService();
    final s = t.more;
    String? version;
    try {
      final info = await PackageInfo.fromPlatform();
      version = '${info.version} (${info.buildNumber})';
    } catch (_) {}
    final device = switch (defaultTargetPlatform) {
      TargetPlatform.iOS => 'iOS',
      TargetPlatform.android => 'Android',
      _ => null,
    };
    final lines = <String>[
      for (final (label, value) in [
        (s.signatureName, session.profile?.fullName),
        (s.signatureEmail, session.user?.email),
        (s.signaturePhone, session.user?.phoneNumber),
        (s.signatureId, session.user?.uid),
        (
          s.signatureVersion,
          [version, device].whereType<String>().join(' · '),
        ),
      ])
        if (value != null && value.trim().isNotEmpty)
          '▪️ $label: ${value.trim()}',
    ];
    return '\n\n\n━━━━━━━━━━━━\n📋 ${s.signatureTitle}\n${lines.join('\n')}';
  }

  Future<void> _open(BuildContext context, Uri uri) async {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) {
      if (context.mounted) {
        AppDialog.error(message: t.more.supportUnavailable).show(context);
      }
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
          padding: EdgeInsets.fromLTRB(
            AppSpacing.marginMobile,
            AppSpacing.marginMobile,
            AppSpacing.marginMobile,
            MediaQuery.viewInsetsOf(context).bottom + AppSpacing.xl,
          ),
          children: [
            // The guide first: it answers most "how do I" questions before a
            // message has to be written.
            FeatureGate(
              feature: FeaturesFlags.tutorialBook,
              gapAfter: AppSpacing.lg,
              child: ClayCard(
                radius: AppRadius.md,
                padding: const EdgeInsets.all(AppSpacing.md),
                color: AppColors.primaryFixed,
                onTap: () => context.pushNamed(Routing.tutorial),
                child: Row(
                  children: [
                    const ClayIconButton(
                      icon: Icons.school_rounded,
                      filled: true,
                      size: 48,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.walkthrough.start,
                            style: AppTextStyles.bodyLg,
                          ),
                          Text(
                            t.walkthrough.startHint,
                            style: AppTextStyles.labelSm.copyWith(
                              color: AppColors.onPrimaryFixedVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: AppColors.primary),
                  ],
                ),
              ),
            ),
            Icon(
              Icons.support_agent_rounded,
              size: 56,
              color: AppColors.primary,
            ),
            const SizedBox(height: AppSpacing.gutter),
            Text(
              t.more.supportTitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.headlineMd,
            ),
            const SizedBox(height: AppSpacing.base),
            Text(
              t.more.supportBody,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ClayButton(
              label: t.more.whatsapp,
              icon: Icons.chat_rounded,
              expanded: true,
              onPressed: () async {
                final signature = await _signature();
                if (!context.mounted) return;
                await _open(
                  context,
                  Uri.https('wa.me', '/$supportPhone', {'text': signature}),
                );
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            ClayButton(
              label: t.more.email,
              icon: Icons.mail_rounded,
              expanded: true,
              onPressed: () async {
                final signature = await _signature();
                if (!context.mounted) return;
                await _open(
                  context,
                  Uri(
                    scheme: 'mailto',
                    path: supportEmail,
                    // Built by hand rather than with queryParameters, which
                    // encodes spaces as '+' — mail clients show that literally.
                    query:
                        'subject=${Uri.encodeComponent(t.appName)}'
                        '&body=${Uri.encodeComponent(signature)}',
                  ),
                );
              },
            ),
            const FeatureGate(
              feature: FeaturesFlags.feedback,
              gapBefore: AppSpacing.xl,
              child: FeedbackForm(),
            ),
          ],
        ),
      ),
    );
  }
}
