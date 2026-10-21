import 'dart:async';

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
import '../widgets/sign_out_action.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../domain/send_log.dart';

/// Held between signing up with a password and reaching the app, so an address
/// nobody controls cannot become an account.
class EmailVerificationPage extends StatefulWidget {
  const EmailVerificationPage({super.key});

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  bool _busy = false;

  /// Seconds before another mail may be asked for: one goes out on every
  /// arrival here already, and Firebase throttles an address hit repeatedly.
  int _resendIn = 0;
  Timer? _cooldown;
  static const _resendWait = 30;

  @override
  void initState() {
    super.initState();
    // The link goes out as soon as the screen appears, so the common path is
    // "check your mail" rather than "press send first".
    // Not when one went out moments ago — linking an email sends its own,
    // and a second straight after is a duplicate (or a throttle).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final uid = context.read<AuthRepository>().currentUser?.uid;
      final left = SendLog.mailWaitLeft(uid, _resendWait);
      if (left > 0) {
        _startCooldown(left);
      } else {
        _send(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _cooldown?.cancel();
    super.dispose();
  }

  void _startCooldown([int seconds = _resendWait]) {
    _cooldown?.cancel();
    setState(() => _resendIn = seconds);
    _cooldown = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      setState(() => _resendIn--);
      if (_resendIn <= 0) timer.cancel();
    });
  }

  Future<void> _send({bool silent = false}) async {
    final repository = context.read<AuthRepository>();
    setState(() => _busy = true);
    _startCooldown();
    try {
      await SendEmailVerificationUseCase(repository)();
      if (mounted && !silent) _toast(t.auth.emailResent);
    } catch (e) {
      debugPrint('Email verification send failed: $e');
      if (mounted && !silent) _fail(t.auth.errorUnknown);
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
        _warn(t.auth.stillNotVerified);
        return;
      }
      // The gate re-reads the account and moves on; the router follows.
      final user = repository.currentUser;
      if (user != null) await AuthSessionService().refreshUser(user);
    } catch (e) {
      debugPrint('Verification check failed: $e');
      if (mounted) _fail(t.auth.errorUnknown);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// A word in passing, gone on its own.
  void _toast(String message) =>
      AppDialog.success(message: message).notify(context);

  /// Something to read before going on.
  void _fail(String message) => AppDialog.error(message: message).show(context);

  void _warn(String message) =>
      AppDialog.warning(message: message).notify(context);

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
            onTrailingTap: _busy
                ? null
                : () => signOutWithFeedback(context, context.read<AuthBloc>()),
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.marginMobile),
              children: [
                const SizedBox(height: AppSpacing.lg),
                Icon(
                  Icons.mark_email_unread_rounded,
                  size: 64,
                  color: AppColors.primary,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  t.auth.verifyEmailBody(email: email),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
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
                    onPressed: _busy || _resendIn > 0 ? null : () => _send(),
                    child: Text(
                      _resendIn > 0
                          ? t.auth.resendIn(seconds: _resendIn)
                          : t.auth.resendEmail,
                      style: AppTextStyles.labelMd.copyWith(
                        color: AppColors.primary,
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
        ),
      ),
    );
  }
}
