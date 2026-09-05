import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_spacing.dart';
import '../services/auth_session_service.dart';
import '../utils/routing/routing.dart';
import 'profile_avatar.dart';

/// The account entry point that sits in every main screen's app bar, in place
/// of the settings tab the nav dock used to carry.
class AccountAvatarButton extends StatelessWidget {
  const AccountAvatarButton({super.key});

  @override
  Widget build(BuildContext context) {
    final session = AuthSessionService();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: GestureDetector(
        onTap: () => context.pushNamed(Routing.accountMenu),
        behavior: HitTestBehavior.opaque,
        child: ProfileAvatar(
          name: session.profile?.fullName ?? '',
          photoUrl: session.profile?.photoUrl ?? session.user?.photoUrl,
        ),
      ),
    );
  }
}
