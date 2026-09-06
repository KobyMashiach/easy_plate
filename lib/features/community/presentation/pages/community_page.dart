import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/account_avatar_button.dart';
import '../../../../core/widgets/notification_bell_button.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../../forum/presentation/pages/forum_page.dart';
import '../../../shared_recipes/presentation/pages/shared_recipes_page.dart';

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
              child: Row(
                children: [
                  Expanded(
                    child: _segment(
                      label: t.community.sharedRecipes,
                      icon: Icons.public_rounded,
                      selected: _index == 0,
                      onTap: () => setState(() => _index = 0),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _segment(
                      label: t.community.forum,
                      icon: Icons.forum_rounded,
                      selected: _index == 1,
                      onTap: () => setState(() => _index = 1),
                    ),
                  ),
                ],
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

  Widget _segment({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.gutter,
        ),
        decoration: ShapeDecoration(
          color: selected ? AppColors.primaryFixed : AppColors.surfaceContainerLow,
          shape: StadiumBorder(
            side: BorderSide(color: selected ? AppColors.primary : AppColors.outlineVariant),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: selected ? AppColors.primary : AppColors.tertiary),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelMd.copyWith(
                  color: selected ? AppColors.primary : AppColors.tertiary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
