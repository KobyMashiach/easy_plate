import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/link_email_password_usecase.dart';
import '../../domain/usecases/link_phone_usecase.dart';
import 'auth_error_text.dart';

/// Firebase requires E.164. A local Israeli number is the common paste, so
/// `05…` is upgraded rather than rejected.
String normalisePhone(String raw) {
  final trimmed = raw.replaceAll(RegExp(r'[\s\-()]'), '');
  if (trimmed.startsWith('+')) return trimmed;
  if (trimmed.startsWith('0')) return '+972${trimmed.substring(1)}';
  return '+$trimmed';
}

/// Attaches a phone number to the signed-in account, so signing in with that
/// number later reaches this account rather than creating a second one.
/// Resolves true once the link succeeds.
Future<bool?> showLinkPhoneSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceContainerLowest,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.md)),
    ),
    builder: (_) => const _LinkPhoneSheet(),
  );
}

Future<bool?> showLinkEmailSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceContainerLowest,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.md)),
    ),
    builder: (_) => const _LinkEmailSheet(),
  );
}

class _SheetShell extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SheetShell({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.md,
          right: AppSpacing.md,
          top: AppSpacing.md,
          bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClaySectionHeader(title: title, underline: true),
            const SizedBox(height: AppSpacing.gutter),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _LinkPhoneSheet extends StatefulWidget {
  const _LinkPhoneSheet();

  @override
  State<_LinkPhoneSheet> createState() => _LinkPhoneSheetState();
}

class _LinkPhoneSheetState extends State<_LinkPhoneSheet> {
  final _phone = TextEditingController();
  final _code = TextEditingController();

  String? _verificationId;
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
      if (mounted) setState(() => _verificationId = id);
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
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _error = _messageFor(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// `credential-already-in-use` is the one case worth its own wording: the
  /// number is fine, it just belongs to somebody else's account.
  String _messageFor(Object e) {
    debugPrint('Phone link failed: $e');
    if (e is AppException && e.message == 'credential-already-in-use') {
      return t.auth.phoneAlreadyUsed;
    }
    return e is AppException ? authErrorMessage(e.message) : t.auth.errorUnknown;
  }

  @override
  Widget build(BuildContext context) {
    final awaitingCode = _verificationId != null;

    return _SheetShell(
      title: t.auth.linkPhone,
      children: [
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
        if (_busy) ...[
          const SizedBox(height: AppSpacing.md),
          const Center(child: CircularProgressIndicator()),
        ],
      ],
    );
  }
}

class _LinkEmailSheet extends StatefulWidget {
  const _LinkEmailSheet();

  @override
  State<_LinkEmailSheet> createState() => _LinkEmailSheetState();
}

class _LinkEmailSheetState extends State<_LinkEmailSheet> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final password = _password.text;

    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      setState(() => _error = t.auth.invalidEmail);
      return;
    }
    if (password.length < 6) {
      setState(() => _error = t.auth.passwordTooShort);
      return;
    }

    setState(() {
      _error = null;
      _busy = true;
    });
    try {
      await LinkEmailPasswordUseCase(context.read<AuthRepository>())(email, password);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      debugPrint('Email link failed: $e');
      if (!mounted) return;
      setState(() {
        _error = switch (e) {
          AppException(message: 'email-already-in-use') => t.auth.errorEmailInUse,
          AppException(message: 'provider-already-linked') => t.auth.emailAlreadyLinked,
          AppException(message: final code) => authErrorMessage(code),
          _ => t.auth.errorUnknown,
        };
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SheetShell(
      title: t.auth.addEmailPassword,
      children: [
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          style: AppTextStyles.bodyMd,
          decoration: InputDecoration(labelText: t.auth.email, hintText: t.auth.emailHint),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _password,
          obscureText: true,
          style: AppTextStyles.bodyMd,
          decoration: InputDecoration(
            labelText: t.auth.password,
            hintText: t.auth.passwordHint,
            errorText: _error,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ClayButton(
          label: t.common.save,
          icon: Icons.check_rounded,
          expanded: true,
          onPressed: _busy ? null : _submit,
        ),
        if (_busy) ...[
          const SizedBox(height: AppSpacing.md),
          const Center(child: CircularProgressIndicator()),
        ],
      ],
    );
  }
}
