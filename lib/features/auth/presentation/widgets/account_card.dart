import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/services/auth_session_service.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../bloc/auth_bloc.dart';
import '../../../../core/widgets/app_dialog.dart';

/// The signed-in account and the way out of it. Lives in settings because that
/// is the only screen the gate lets a signed-in user reach it from.
class AccountCard extends StatelessWidget {
  const AccountCard({super.key});

  Future<void> _confirmSignOut(BuildContext context) async {
    final bloc = context.read<AuthBloc>();
    final confirmed = await AppDialog.warning(
      title: t.auth.signOutTitle,
      message: t.auth.signOutBody,
      icon: Icons.logout_rounded,
      confirmLabel: t.auth.signOut,
      cancelLabel: t.common.cancel,
      destructive: true,
    ).show(context);

    if (confirmed ?? false) bloc.add(const AuthEvent.signOut());
  }

  @override
  Widget build(BuildContext context) {
    final profile = AuthSessionService().profile;
    final user = AuthSessionService().user;

    return ClayCard(
      radius: AppRadius.md,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClaySectionHeader(title: t.profile.myProfile),
          const SizedBox(height: AppSpacing.gutter),
          Row(
            children: [
              SizedBox(
                width: 52,
                height: 52,
                child: ClipOval(
                  child: profile?.photoUrl != null
                      ? Image.network(
                          profile!.photoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const _AvatarFallback(),
                        )
                      : const _AvatarFallback(),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile?.fullName ?? '',
                      style: AppTextStyles.bodyLg,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      profile?.email ?? profile?.phoneNumber ?? user?.email ?? '',
                      style: AppTextStyles.labelMd.copyWith(color: AppColors.onSurfaceVariant),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClayButton(
            label: t.auth.signOut,
            icon: Icons.logout_rounded,
            expanded: true,
            onPressed: () => _confirmSignOut(context),
          ),
        ],
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.primaryFixed,
      child: Icon(Icons.person_rounded, color: AppColors.primary),
    );
  }
}
