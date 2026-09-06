import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/services/device_locale_store.dart';
import '../../../../core/utils/i18n/app_language_mapper.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/utils/routing/routing.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../../../core/widgets/language_selector.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/apple_sign_in.dart';
import '../widgets/auth_error_text.dart';
import 'phone_verification_page.dart';

enum _Method { email, phone }

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AuthBloc.fromContext(context),
      child: const _LoginView(),
    );
  }
}

class _LoginView extends StatefulWidget {
  const _LoginView();

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _phone = TextEditingController();

  _Method _method = _Method.phone;
  String? _fieldError;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _phone.dispose();
    super.dispose();
  }

  bool _validEmail(String value) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);

  /// Firebase requires E.164. Local Israeli numbers are the common paste, so
  /// `05…` is upgraded rather than rejected.
  String _normalisePhone(String raw) {
    final trimmed = raw.replaceAll(RegExp(r'[\s-()]'), '');
    if (trimmed.startsWith('+')) return trimmed;
    if (trimmed.startsWith('0')) return '+972${trimmed.substring(1)}';
    return '+$trimmed';
  }

  void _submitEmail() {
    final email = _email.text.trim();
    final password = _password.text;

    if (!_validEmail(email)) {
      setState(() => _fieldError = t.auth.invalidEmail);
      return;
    }
    if (password.length < 6) {
      setState(() => _fieldError = t.auth.passwordTooShort);
      return;
    }

    setState(() => _fieldError = null);
    // Sign-in only. An account is opened by phone and nothing else, so email
    // and password are a way back into an account that already linked them.
    context.read<AuthBloc>().add(AuthEvent.signInWithEmail(email, password));
  }

  void _submitPhone() {
    final phone = _normalisePhone(_phone.text);
    if (phone.length < 10) {
      setState(() => _fieldError = t.auth.invalidPhone);
      return;
    }
    setState(() => _fieldError = null);
    context.read<AuthBloc>().add(AuthEvent.startPhoneVerification(phone));
  }

  void _resetPassword() {
    final email = _email.text.trim();
    if (!_validEmail(email)) {
      setState(() => _fieldError = t.auth.invalidEmail);
      return;
    }
    setState(() => _fieldError = null);
    context.read<AuthBloc>().add(AuthEvent.sendPasswordReset(email));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        switch (state) {
          case AuthCodeSent(verificationId: final id, phoneNumber: final phone):
            context.pushNamed(
              Routing.phoneVerify,
              extra: PhoneVerificationArgs(verificationId: id, phoneNumber: phone),
            );
          case AuthPasswordResetSent():
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(t.auth.resetSent, style: AppTextStyles.bodyMd)),
            );
          case AuthError(error: final error):
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(authErrorMessage(error), style: AppTextStyles.bodyMd)),
            );
          default:
            break;
        }
      },
      builder: (context, state) {
        final busy = state is AuthLoading;
        return ClayScaffold(
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.marginMobile),
              children: [
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: _LanguageButton(onChanged: () => setState(() {})),
                ),
                Text(
                  t.auth.welcome,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.headlineLgMobile,
                ),
                const SizedBox(height: AppSpacing.base),
                Text(
                  t.auth.subtitle,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpacing.xl),
                _methodToggle(busy),
                const SizedBox(height: AppSpacing.md),
                ClayCard(
                  radius: AppRadius.md,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: _method == _Method.email ? _emailForm(busy) : _phoneForm(busy),
                ),
                const SizedBox(height: AppSpacing.md),
                _divider(),
                const SizedBox(height: AppSpacing.md),
                ClayButton(
                  label: t.auth.continueWithGoogle,
                  icon: Icons.g_mobiledata_rounded,
                  expanded: true,
                  onPressed:
                      busy ? null : () => context.read<AuthBloc>().add(const AuthEvent.signInWithGoogle()),
                ),
                // iOS only: Apple requires an equivalent privacy-focused option
                // wherever a third-party sign-in is offered, and Android has no
                // such requirement or native sheet.
                if (appleSignInAvailable) ...[
                  const SizedBox(height: AppSpacing.sm),
                  ClayButton(
                    label: t.auth.continueWithApple,
                    icon: Icons.apple_rounded,
                    expanded: true,
                    onPressed: busy
                        ? null
                        : () => context.read<AuthBloc>().add(const AuthEvent.signInWithApple()),
                  ),
                ],
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

  Widget _methodToggle(bool busy) {
    return Row(
      children: [
        Expanded(
          child: _toggleChip(
            label: t.auth.continueWithEmail,
            icon: Icons.alternate_email_rounded,
            selected: _method == _Method.email,
            onTap: busy ? null : () => setState(() => _method = _Method.email),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _toggleChip(
            label: t.auth.continueWithPhone,
            icon: Icons.phone_iphone_rounded,
            selected: _method == _Method.phone,
            onTap: busy ? null : () => setState(() => _method = _Method.phone),
          ),
        ),
      ],
    );
  }

  Widget _toggleChip({
    required String label,
    required IconData icon,
    required bool selected,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.gutter,
        ),
        decoration: ShapeDecoration(
          color: selected ? AppColors.primaryFixed : AppColors.surfaceContainerLow,
          shape: StadiumBorder(
            side: BorderSide(color: selected ? AppColors.primary : AppColors.outlineVariant),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: selected ? AppColors.primary : AppColors.tertiary),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelMd.copyWith(
                  color: selected ? AppColors.primary : AppColors.tertiary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emailForm(bool busy) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClaySectionHeader(title: t.auth.signInTitle),
        const SizedBox(height: AppSpacing.gutter),
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          textInputAction: TextInputAction.next,
          style: AppTextStyles.bodyMd,
          decoration: InputDecoration(labelText: t.auth.email, hintText: t.auth.emailHint),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _password,
          obscureText: true,
          autofillHints: const [AutofillHints.password],
          style: AppTextStyles.bodyMd,
          decoration: InputDecoration(
            labelText: t.auth.password,
            hintText: t.auth.passwordHint,
            errorText: _fieldError,
          ),
          onSubmitted: (_) => busy ? null : _submitEmail(),
        ),
        const SizedBox(height: AppSpacing.md),
        ClayButton(
          label: t.auth.signIn,
          icon: Icons.login_rounded,
          expanded: true,
          onPressed: busy ? null : _submitEmail,
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                t.auth.phoneFirstHint,
                style: AppTextStyles.labelMd.copyWith(color: AppColors.onSurfaceVariant),
              ),
            ),
            TextButton(
              onPressed: busy ? null : _resetPassword,
              child: Text(
                t.auth.forgotPassword,
                style: AppTextStyles.labelMd.copyWith(color: AppColors.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _phoneForm(bool busy) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClaySectionHeader(title: t.auth.phoneNumber),
        const SizedBox(height: AppSpacing.gutter),
        TextField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          autofillHints: const [AutofillHints.telephoneNumber],
          style: AppTextStyles.bodyMd,
          textDirection: TextDirection.ltr,
          decoration: InputDecoration(
            labelText: t.auth.phoneNumber,
            hintText: t.auth.phoneHint,
            errorText: _fieldError,
          ),
          onSubmitted: (_) => busy ? null : _submitPhone(),
        ),
        const SizedBox(height: AppSpacing.md),
        ClayButton(
          label: t.auth.sendCode,
          icon: Icons.sms_rounded,
          expanded: true,
          onPressed: busy ? null : _submitPhone,
        ),
      ],
    );
  }

  Widget _divider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.outlineVariant)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Text(
            t.common.or,
            style: AppTextStyles.labelMd.copyWith(color: AppColors.onSurfaceVariant),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.outlineVariant)),
      ],
    );
  }
}

/// Language control for the pre-sign-in screens.
///
/// The account's own language only becomes available once it is signed in, so
/// the choice made here is stored per device and is what the splash and login
/// use on the next launch.
class _LanguageButton extends StatelessWidget {
  final VoidCallback onChanged;

  const _LanguageButton({required this.onChanged});

  AppLanguage get _current => AppLanguage.values.firstWhere(
        (language) => language.locale == LocaleSettings.currentLocale,
        orElse: () => AppLanguage.hebrew,
      );

  Future<void> _pick(BuildContext context) async {
    final picked = await showModalBottomSheet<AppLanguage>(
      context: context,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.md)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClaySectionHeader(title: t.settings.language, underline: true),
              const SizedBox(height: AppSpacing.md),
              LanguageSelector(
                selected: _current,
                onSelect: (language) => Navigator.of(sheetContext).pop(language),
              ),
            ],
          ),
        ),
      ),
    );
    if (picked == null) return;

    await DeviceLocaleStore().write(picked);
    await LocaleSettings.setLocale(picked.locale);
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _pick(context),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.language_rounded, size: 18, color: AppColors.primary),
            const SizedBox(width: AppSpacing.xs),
            Text(
              _current.label,
              style: AppTextStyles.labelMd.copyWith(color: AppColors.primary),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded,
                size: 18, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
