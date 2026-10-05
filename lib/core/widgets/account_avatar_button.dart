import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_colors.dart';
import '../constants/app_shadows.dart';
import '../services/admin_inbox_service.dart';
import '../services/auth_session_service.dart';
import '../utils/routing/routing.dart';
import 'count_badge.dart';
import 'profile_avatar.dart';
import '../walkthrough/walkthrough_targets.dart';

/// The account entry point that sits in every main screen's app bar, in place
/// of the settings tab the nav dock used to carry. Ringed like the round bar
/// buttons beside it, so the bar reads as one row of controls.
///
/// For the administrator it also carries the support inbox's unread count,
/// the way the bell carries the notifications': a new message shows from
/// any screen, without opening the menu.
class AccountAvatarButton extends StatelessWidget {
  const AccountAvatarButton({super.key});

  @override
  Widget build(BuildContext context) {
    final session = AuthSessionService();

    return WalkthroughTarget(
      id: 'bar.avatar',
      child: GestureDetector(
        onTap: () => context.pushNamed(Routing.accountMenu),
        behavior: HitTestBehavior.opaque,
        child: ValueListenableBuilder<int>(
          valueListenable: AdminInboxService().unreadCount,
          builder: (context, unread, child) => BadgedBox(
            count: unread,
            top: -4,
            end: -4,
            child: child!,
          ),
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.surfaceContainerHighest),
              boxShadow: AppShadows.control,
            ),
            // This button is a const in five app bars: it is never rebuilt
            // on its own, so a renamed account or a new photo has to reach
            // it through the listenable rather than a plain read.
            child: ValueListenableBuilder(
              valueListenable: session.profileListenable,
              builder: (context, profile, _) => ProfileAvatar(
                name: profile?.fullName ?? '',
                photoUrl: profile?.photoUrl ?? session.user?.photoUrl,
                size: 34,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
