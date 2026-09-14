import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/account_avatar_button.dart';
import '../../../../core/widgets/notification_bell_button.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../../forum/presentation/pages/forum_page.dart';
import '../../../shared_recipes/presentation/pages/shared_recipes_page.dart';
import '../../../../core/walkthrough/walkthrough.dart';
import '../../../../core/walkthrough/app_walkthroughs.dart';

/// Hosts the two community surfaces behind one nav tab, so the dock keeps a
/// workable number of destinations.
class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return ClayScaffold(
      appBar: ClayTopAppBar(
        title: t.community.title,
        leading: const AccountAvatarButton(),
        actions: const [NotificationBellButton()],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.marginMobile,
                AppSpacing.md,
                AppSpacing.marginMobile,
                0,
              ),
              child: WalkthroughTarget(
                id: WalkthroughIds.communitySegments,
                child: ClaySegmentedControl(
                  segments: [
                    ClaySegment(
                      label: t.community.sharedRecipes,
                      icon: Icons.public_rounded,
                    ),
                    ClaySegment(
                      label: t.community.forum,
                      icon: Icons.forum_rounded,
                    ),
                  ],
                  selectedIndex: _index,
                  onSelected: (index) => setState(() => _index = index),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // IndexedStack so switching back to a tab keeps its scroll position
            // and does not re-hit Firestore.
            Expanded(
              child: IndexedStack(
                index: _index,
                children: const [SharedRecipesPage(), ForumPage()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
