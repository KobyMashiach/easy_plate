import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/services/auth_session_service.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/link_phone_usecase.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/auth_error_text.dart';
import '../widgets/link_credential_sheets.dart' show normalisePhone;

/// Held between arriving with Google or an email and reaching the app.
///
/// A verified phone is the root identity of every account. Signing up by phone
/// satisfies that on the way in, so this screen only ever sees the other two
/// doors — and the accounts that predate the rule.
///
/// It *links* rather than signs in: the account already exists, and swapping to
/// a phone sign-in here would strand whatever brought the user this far.
class PhoneGatePage extends StatefulWidget {
  const PhoneGatePage({super.key});

  @override
  State<PhoneGatePage> createState() => _PhoneGatePageState();
}

class _PhoneGatePageState extends State<PhoneGatePage> {
  final _phone = TextEditingController();
  final _code = TextEditingController();

  String? _verificationId;
  String? _sentTo;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  LinkPhoneUseCase get _useCase => LinkPhoneUseCase(context.read<AuthRepository>());

  Future<void> _send() async {
    final phone = normalisePhone(_phone.text);
    if (phone.length < 10) {
      setState(() => _error = t.auth.invalidPhone);
      return;
    }
    setState(() {
      _error = null;
      _busy = true;
    });
    try {
      final id = await _useCase.start(phone);
      if (mounted) {
        setState(() {
          _verificationId = id;
          _sentTo = phone;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = _messageFor(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirm() async {
    final code = _code.text.trim();
    if (code.length < 6) {
      setState(() => _error = t.auth.codeRequired);
      return;
    }
    setState(() {
      _error = null;
      _busy = true;
    });
    try {
      await _useCase.confirm(_verificationId!, code);
      if (!mounted) return;
      // The account now carries a `phone` provider, so re-reading it moves the
      // gate on and the router follows by itself.
      final user = context.read<AuthRepository>().currentUser;
      if (user != null) await AuthSessionService().refreshUser(user);
    } catch (e) {
      if (mounted) setState(() => _error = _messageFor(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Lets the user correct a wrong number without signing out and starting over.
  void _editNumber() {
    setState(() {
      _verificationId = null;
      _sentTo = null;
      _error = null;
      _code.clear();
    });
  }

  String _messageFor(Object e) {
    debugPrint('Phone gate failed: $e');
    if (e is AppException && e.message == 'credential-already-in-use') {
      return t.auth.phoneAlreadyUsed;
    }
    return e is AppException ? authErrorMessage(e.message) : t.auth.errorUnknown;
  }

  @override
  Widget build(BuildContext context) {
    final awaitingCode = _verificationId != null;

    return BlocProvider(
      create: (context) => AuthBloc.fromContext(context),
      child: Builder(
        builder: (context) => ClayScaffold(
          appBar: ClayTopAppBar(
            title: t.auth.phoneGateTitle,
            // The only way out for someone who signed in with an account they
            // cannot attach a number to.
            trailingIcon: Icons.logout_rounded,
            onTrailingTap:
                _busy ? null : () => context.read<AuthBloc>().add(const AuthEvent.signOut()),
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.marginMobile),
              children: [
                const SizedBox(height: AppSpacing.lg),
                const Icon(Icons.phone_iphone_rounded, size: 64, color: AppColors.primary),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  awaitingCode
                      ? t.auth.codeSentTo(phone: _sentTo ?? '')
                      : t.auth.phoneGateBody,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpacing.xl),
                if (!awaitingCode)
                  TextField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    textDirection: TextDirection.ltr,
                    style: AppTextStyles.bodyMd,
                    decoration: InputDecoration(
                      labelText: t.auth.phoneNumber,
                      hintText: t.auth.phoneHint,
                      errorText: _error,
                    ),
                  )
                else
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
                    decoration: InputDecoration(hintText: '••••••', errorText: _error),
                  ),
                const SizedBox(height: AppSpacing.md),
                ClayButton(
                  label: awaitingCode ? t.auth.verify : t.auth.sendCode,
                  icon: awaitingCode ? Icons.check_rounded : Icons.sms_rounded,
                  expanded: true,
                  onPressed: _busy ? null : (awaitingCode ? _confirm : _send),
                ),
                if (awaitingCode) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Center(
                    child: TextButton(
                      onPressed: _busy ? null : _editNumber,
                      child: Text(
                        t.auth.changeNumber,
                        style: AppTextStyles.labelMd.copyWith(color: AppColors.primary),
                      ),
                    ),
                  ),
                ],
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
