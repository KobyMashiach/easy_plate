import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_colors.dart';
import '../constants/app_shadows.dart';
import '../services/auth_session_service.dart';
import '../utils/routing/routing.dart';
import 'profile_avatar.dart';
import '../walkthrough/walkthrough_targets.dart';

/// The account entry point that sits in every main screen's app bar, in place
/// of the settings tab the nav dock used to carry. Ringed like the round bar
/// buttons beside it, so the bar reads as one row of controls.
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
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.surfaceContainerHighest),
            boxShadow: AppShadows.control,
          ),
          child: ProfileAvatar(
            name: session.profile?.fullName ?? '',
            photoUrl: session.profile?.photoUrl ?? session.user?.photoUrl,
            size: 34,
          ),
        ),
      ),
    );
  }
}
