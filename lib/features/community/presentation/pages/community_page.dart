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
import '../../../../core/features/feature_gate.dart';
import '../../../../core/constants/app_text_styles.dart';

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
    return ListenableBuilder(
      listenable: FeaturesFlags.listenable,
      builder: (context, _) {
        final shared = FeaturesFlags.sharedRecipes.access;
        final forum = FeaturesFlags.forum.access;
        // Both surfaces, with their state; a hidden one leaves the dock.
        final surfaces = [
          if (shared.isVisible)
            (
              index: 0,
              feature: FeaturesFlags.sharedRecipes,
              state: shared,
              label: t.community.sharedRecipes,
              icon: Icons.public_rounded,
            ),
          if (forum.isVisible)
            (
              index: 1,
              feature: FeaturesFlags.forum,
              state: forum,
              label: t.community.forum,
              icon: Icons.forum_rounded,
            ),
        ];
        final selected = surfaces.indexWhere((s) => s.index == _index);
        final current = selected == -1 ? 0 : selected;

        return ClayScaffold(
          appBar: ClayTopAppBar(
            title: t.community.title,
            leading: const AccountAvatarButton(),
            actions: const [NotificationBellButton()],
          ),
          body: SafeArea(
            child: Column(
              children: [
                if (surfaces.length > 1) ...[
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
                          for (final surface in surfaces)
                            ClaySegment(
                              label: surface.label,
                              icon: surface.icon,
                            ),
                        ],
                        selectedIndex: current,
                        onSelected: (index) =>
                            setState(() => _index = surfaces[index].index),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                // IndexedStack so switching back to a tab keeps its scroll
                // position and does not re-hit Firestore.
                Expanded(
                  child: surfaces.isEmpty
                      ? Center(
                          child: Text(
                            t.feature.unavailable,
                            style: AppTextStyles.bodyMd,
                          ),
                        )
                      : IndexedStack(
                          index: current,
                          children: [
                            for (final surface in surfaces)
                              !surface.state.isEnabled
                                  ? Center(
                                      child: GatedNotice(
                                        label: surface.label,
                                        feature: surface.feature,
                                        access: surface.state,
                                      ),
                                    )
                                  : surface.index == 0
                                  ? const SharedRecipesPage()
                                  : const ForumPage(),
                          ],
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
