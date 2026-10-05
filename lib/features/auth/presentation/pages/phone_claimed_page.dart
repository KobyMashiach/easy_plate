import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/services/auth_session_service.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../domain/repositories/auth_repository.dart';

/// Shown when a phone sign-in has just opened a new account for a number the
/// app knows belongs to another one (see [AuthStage.phoneClaimed]).
///
/// The way back is the existing account's own sign-in: the new, empty
/// account is deleted and the user lands on the login screen. Starting over
/// is still possible — a stale directory entry must never lock a number out
/// for good.
class PhoneClaimedPage extends StatefulWidget {
  const PhoneClaimedPage({super.key});

  @override
  State<PhoneClaimedPage> createState() => _PhoneClaimedPageState();
}

/// Wraps [text] in a left-to-right isolate, so a phone number keeps its
/// order inside a right-to-left sentence.
String _isolateLtr(String text) =>
    '${String.fromCharCode(0x2066)}$text${String.fromCharCode(0x2069)}';

class _PhoneClaimedPageState extends State<PhoneClaimedPage> {
  bool _busy = false;

  /// Deletes the account minted a moment ago — it has no profile and no
  /// data — then signs out, so the login screen is where the user lands.
  Future<void> _backToExisting() async {
    final auth = context.read<AuthRepository>();
    setState(() => _busy = true);
    try {
      await auth.deleteCurrentUser();
    } catch (e) {
      // Worst case the empty account lingers; signing out still gets the
      // user to the right door.
      debugPrint('Deleting the duplicate account failed: $e');
    }
    try {
      await auth.signOut();
    } catch (e) {
      debugPrint('Sign-out after duplicate failed: $e');
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _createNew() async {
    final ok = await AppDialog.warning(
      title: t.auth.phoneClaimedCreateNew,
      message: t.auth.phoneClaimedCreateNewConfirm,
      confirmLabel: t.auth.phoneClaimedCreateNew,
      cancelLabel: t.common.cancel,
    ).show(context);
    if (ok == true) AuthSessionService().acknowledgePhoneClaim();
  }

  @override
  Widget build(BuildContext context) {
    final phone = AuthSessionService().user?.phoneNumber ?? '';
    return ClayScaffold(
      appBar: ClayTopAppBar(title: t.appName),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.marginMobile),
          children: [
            const SizedBox(height: AppSpacing.lg),
            Icon(
              Icons.manage_accounts_rounded,
              size: 64,
              color: AppColors.primary,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              t.auth.phoneClaimedTitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.headlineMd,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              // The number reads left to right inside the Hebrew sentence.
              t.auth.phoneClaimedBody(phone: _isolateLtr(phone)),
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            ClayButton(
              label: t.auth.phoneClaimedSignIn,
              icon: Icons.login_rounded,
              expanded: true,
              onPressed: _busy ? null : _backToExisting,
            ),
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: TextButton(
                onPressed: _busy ? null : _createNew,
                child: Text(
                  t.auth.phoneClaimedCreateNew,
                  style: AppTextStyles.labelMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            if (_busy) ...[
              const SizedBox(height: AppSpacing.lg),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }
}
