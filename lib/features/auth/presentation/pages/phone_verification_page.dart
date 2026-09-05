import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/auth_error_text.dart';

class PhoneVerificationArgs {
  final String verificationId;
  final String phoneNumber;

  const PhoneVerificationArgs({required this.verificationId, required this.phoneNumber});
}

class PhoneVerificationPage extends StatelessWidget {
  final PhoneVerificationArgs args;

  const PhoneVerificationPage({super.key, required this.args});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AuthBloc.fromContext(context),
      child: _PhoneVerificationView(args: args),
    );
  }
}

class _PhoneVerificationView extends StatefulWidget {
  final PhoneVerificationArgs args;

  const _PhoneVerificationView({required this.args});

  @override
  State<_PhoneVerificationView> createState() => _PhoneVerificationViewState();
}

class _PhoneVerificationViewState extends State<_PhoneVerificationView> {
  final _code = TextEditingController();

  /// Replaced when the user asks for a new SMS, so the second code is checked
  /// against the second verification id rather than the stale first one.
  late String _verificationId = widget.args.verificationId;
  String? _fieldError;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _verify() {
    final code = _code.text.trim();
    if (code.length < 6) {
      setState(() => _fieldError = t.auth.codeRequired);
      return;
    }
    setState(() => _fieldError = null);
    context.read<AuthBloc>().add(AuthEvent.confirmPhoneCode(_verificationId, code));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        switch (state) {
          case AuthCodeSent(verificationId: final id):
            setState(() => _verificationId = id);
          case AuthError(error: final error):
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(authErrorMessage(error), style: AppTextStyles.bodyMd)),
            );
          default:
            break;
        }
        // A successful sign-in moves the gate on, and the router redirects off
        // this screen on its own.
      },
      builder: (context, state) {
        final busy = state is AuthLoading;
        return ClayScaffold(
          appBar: ClayTopAppBar(
            title: t.auth.signIn,
            leadingIcon: Icons.arrow_back_rounded,
            onLeadingTap: () => Navigator.of(context).maybePop(),
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.marginMobile),
              children: [
                const SizedBox(height: AppSpacing.md),
                Text(
                  t.auth.codeSentTo(phone: widget.args.phoneNumber),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpacing.lg),
                ClayCard(
                  radius: AppRadius.md,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClaySectionHeader(title: t.auth.smsCode),
                      const SizedBox(height: AppSpacing.gutter),
                      TextField(
                        controller: _code,
                        keyboardType: TextInputType.number,
                        autofillHints: const [AutofillHints.oneTimeCode],
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.ltr,
                        style: AppTextStyles.headlineMd,
                        decoration: InputDecoration(
                          hintText: '••••••',
                          errorText: _fieldError,
                        ),
                        onSubmitted: (_) => busy ? null : _verify(),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      ClayButton(
                        label: t.auth.verify,
                        icon: Icons.check_rounded,
                        expanded: true,
                        onPressed: busy ? null : _verify,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Center(
                        child: TextButton(
                          onPressed: busy
                              ? null
                              : () => context
                                  .read<AuthBloc>()
                                  .add(AuthEvent.startPhoneVerification(widget.args.phoneNumber)),
                          child: Text(
                            t.auth.resendCode,
                            style: AppTextStyles.labelMd.copyWith(color: AppColors.primary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (busy) ...[
                  const SizedBox(height: AppSpacing.lg),
                  const Center(child: CircularProgressIndicator()),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
