import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/services/auth_session_service.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/utils/routing/routing.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../../../core/widgets/profile_avatar.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

/// Reached from the avatar in every main screen's app bar.
class AccountMenuPage extends StatelessWidget {
  const AccountMenuPage({super.key});

  Future<void> _confirmSignOut(BuildContext context) async {
    final bloc = context.read<AuthBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.auth.signOutTitle, style: AppTextStyles.headlineMd),
        content: Text(t.auth.signOutBody, style: AppTextStyles.bodyMd),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(t.common.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              t.auth.signOut,
              style: AppTextStyles.labelMd.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed ?? false) bloc.add(const AuthEvent.signOut());
  }

  @override
  Widget build(BuildContext context) {
    final session = AuthSessionService();
    final profile = session.profile;

    return BlocProvider(
      create: (context) => AuthBloc.fromContext(context),
      child: Builder(
        builder: (context) => ClayScaffold(
          appBar: ClayTopAppBar(
            title: t.more.title,
            leadingIcon: Icons.arrow_back_rounded,
            onLeadingTap: () => Navigator.of(context).maybePop(),
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.marginMobile),
              children: [
                ClayCard(
                  radius: AppRadius.md,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      ProfileAvatar(
                        name: profile?.fullName ?? '',
                        photoUrl: profile?.photoUrl ?? session.user?.photoUrl,
                        size: 56,
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
                              profile?.email ??
                                  profile?.phoneNumber ??
                                  session.user?.email ??
                                  session.user?.phoneNumber ??
                                  '',
                              style: AppTextStyles.labelMd
                                  .copyWith(color: AppColors.onSurfaceVariant),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _MenuRow(
                  icon: Icons.tune_rounded,
                  label: t.more.settings,
                  onTap: () => context.pushNamed(Routing.settings),
                ),
                const SizedBox(height: AppSpacing.sm),
                _MenuRow(
                  icon: Icons.person_rounded,
                  label: t.more.profile,
                  onTap: () => context.pushNamed(Routing.profileEdit),
                ),
                const SizedBox(height: AppSpacing.sm),
                _MenuRow(
                  icon: Icons.support_agent_rounded,
                  label: t.more.support,
                  onTap: () => context.pushNamed(Routing.support),
                ),
                const SizedBox(height: AppSpacing.xl),
                // Non-production builds are marked so a tester can tell at a
                // glance which one is on the device. Listens rather than reads
                // once, so a refresh landing while this page is open takes
                // effect immediately.
                ValueListenableBuilder<bool>(
                  valueListenable: FirebaseService().isProdListenable,
                  builder: (context, isProd, _) => isProd
                      ? const SizedBox.shrink()
                      : const Padding(
                          padding: EdgeInsets.only(bottom: AppSpacing.sm),
                          child: _DevBadge(),
                        ),
                ),
                ClayButton(
                  label: t.auth.signOut,
                  icon: Icons.logout_rounded,
                  expanded: true,
                  onPressed: () => _confirmSignOut(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuRow({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClayCard(
      radius: AppRadius.md,
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 22, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(label, style: AppTextStyles.bodyLg)),
          const Icon(Icons.chevron_right_rounded, color: AppColors.tertiary),
        ],
      ),
    );
  }
}

class _DevBadge extends StatelessWidget {
  const _DevBadge();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.base,
        ),
        decoration: const ShapeDecoration(
          color: AppColors.errorContainer,
          shape: StadiumBorder(),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.construction_rounded,
                size: 16, color: AppColors.onErrorContainer),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'DEV',
              style: AppTextStyles.labelMd.copyWith(
                color: AppColors.onErrorContainer,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
