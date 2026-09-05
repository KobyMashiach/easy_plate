import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/services/auth_session_service.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/refresh_email_verified_usecase.dart';
import '../../domain/usecases/send_email_verification_usecase.dart';
import '../bloc/auth_bloc.dart';

/// Held between signing up with a password and reaching the app, so an address
/// nobody controls cannot become an account.
class EmailVerificationPage extends StatefulWidget {
  const EmailVerificationPage({super.key});

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // The link goes out as soon as the screen appears, so the common path is
    // "check your mail" rather than "press send first".
    WidgetsBinding.instance.addPostFrameCallback((_) => _send(silent: true));
  }

  Future<void> _send({bool silent = false}) async {
    final repository = context.read<AuthRepository>();
    setState(() => _busy = true);
    try {
      await SendEmailVerificationUseCase(repository)();
      if (mounted && !silent) _toast(t.auth.emailResent);
    } catch (e) {
      debugPrint('Email verification send failed: $e');
      if (mounted && !silent) _toast(t.auth.errorUnknown);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _check() async {
    final repository = context.read<AuthRepository>();
    setState(() => _busy = true);
    try {
      final verified = await RefreshEmailVerifiedUseCase(repository)();
      if (!mounted) return;
      if (!verified) {
        _toast(t.auth.stillNotVerified);
        return;
      }
      // The gate re-reads the account and moves on; the router follows.
      final user = repository.currentUser;
      if (user != null) await AuthSessionService().refreshUser(user);
    } catch (e) {
      debugPrint('Verification check failed: $e');
      if (mounted) _toast(t.auth.errorUnknown);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: AppTextStyles.bodyMd)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = AuthSessionService().user?.email ?? '';

    return BlocProvider(
      create: (context) => AuthBloc.fromContext(context),
      child: Builder(
        builder: (context) => ClayScaffold(
          appBar: ClayTopAppBar(
            title: t.auth.verifyEmailTitle,
            trailingIcon: Icons.logout_rounded,
            onTrailingTap:
                _busy ? null : () => context.read<AuthBloc>().add(const AuthEvent.signOut()),
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.marginMobile),
              children: [
                const SizedBox(height: AppSpacing.lg),
                const Icon(Icons.mark_email_unread_rounded, size: 64, color: AppColors.primary),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  t.auth.verifyEmailBody(email: email),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpacing.xl),
                ClayButton(
                  label: t.auth.checkVerification,
                  icon: Icons.refresh_rounded,
                  expanded: true,
                  onPressed: _busy ? null : _check,
                ),
                const SizedBox(height: AppSpacing.sm),
                Center(
                  child: TextButton(
                    onPressed: _busy ? null : () => _send(),
                    child: Text(
                      t.auth.resendEmail,
                      style: AppTextStyles.labelMd.copyWith(color: AppColors.primary),
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
        ),
      ),
    );
  }
}
