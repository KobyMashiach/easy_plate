import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/legal_links.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/utils/routing/routing.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../../settings/presentation/widgets/settings_widgets.dart';

/// Support and the legal pair behind one row of the account menu, in the
/// shape of the settings and the preferences pages. The legal documents open
/// in the browser at the same addresses the paywall links to, so a change to
/// LegalLinks moves every door at once.
class HelpMenuPage extends StatelessWidget {
  const HelpMenuPage({super.key});

  Future<void> _openLegal(BuildContext context, Uri uri) async {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      AppDialog.error(message: t.more.supportUnavailable).show(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClayScaffold(
      appBar: ClayTopAppBar(
        title: t.more.help,
        leadingIcon: Icons.arrow_back_rounded,
        onLeadingTap: () => Navigator.of(context).maybePop(),
      ),
      body: SettingsBody(
        title: t.more.help,
        rows: [
          SettingsNavRow(
            icon: Icons.support_agent_rounded,
            label: t.more.support,
            hint: t.more.supportBody,
            onTap: () => context.pushNamed(Routing.support),
          ),
          SettingsGroupLabel(t.more.legal),
          SettingsNavRow(
            icon: Icons.privacy_tip_rounded,
            label: t.premium.privacy,
            onTap: () => _openLegal(context, LegalLinks.privacy),
          ),
          SettingsNavRow(
            icon: Icons.gavel_rounded,
            label: t.premium.terms,
            onTap: () => _openLegal(context, LegalLinks.terms),
          ),
        ],
      ),
    );
  }
}
