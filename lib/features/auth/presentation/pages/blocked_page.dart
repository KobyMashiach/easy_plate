import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/services/auth_session_service.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../domain/repositories/auth_repository.dart';

/// Where an account the administrator switched off is held: the reason,
/// if one was given, and the way out. Nothing else is reachable while the
/// session's stage is [AuthStage.blocked].
class BlockedPage extends StatelessWidget {
  const BlockedPage({super.key});

  @override
  Widget build(BuildContext context) {
    final message = AuthSessionService().blockMessage?.trim() ?? '';
    return ClayScaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: ClayCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.errorContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.block_rounded,
                      size: 36,
                      color: AppColors.onErrorContainer,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.gutter),
                  Text(
                    t.auth.blockedTitle,
                    style: AppTextStyles.headlineMd,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    message.isEmpty ? t.auth.blockedBody : message,
                    style: AppTextStyles.bodyMd.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ClayButton(
                    label: t.auth.signOut,
                    icon: Icons.logout_rounded,
                    expanded: true,
                    onPressed: () => AppDialog.busy(
                      context,
                      context.read<AuthRepository>().signOut,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
