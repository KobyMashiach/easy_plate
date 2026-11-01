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
import 'auth_error_text.dart';

/// "No access to the other device": a new SMS code to the account's own
/// phone, then this device takes the session and the other one is signed
/// out. Resolves true once the gate can open.
Future<bool?> showSessionTakeoverSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceContainerLowest,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.md)),
    ),
    builder: (_) => const _SessionTakeoverSheet(),
  );
}

/// "For your security, verify your phone again": the same SMS round trip to
/// the account's own phone, for a server call that wants a recent sign-in
/// (deleting the account). Resolves true once the phone is confirmed and the
/// ID token refreshed; nothing else happens.
Future<bool?> showPhoneReverifySheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceContainerLowest,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.md)),
    ),
    builder: (_) => const _SessionTakeoverSheet(takeover: false),
  );
}

/// `+972501234567` → `+97250•••4567`: enough to recognise, not to read off.
@visibleForTesting
String maskPhone(String phone) {
  if (phone.length <= 7) return phone;
  final visibleEnd = phone.substring(phone.length - 4);
  final visibleStart = phone.substring(0, phone.length - 7);
  return '$visibleStart•••$visibleEnd';
}

class _SessionTakeoverSheet extends StatefulWidget {
  /// False: only the phone proof (showPhoneReverifySheet), no takeover.
  final bool takeover;

  const _SessionTakeoverSheet({this.takeover = true});

  @override
  State<_SessionTakeoverSheet> createState() => _SessionTakeoverSheetState();
}

class _SessionTakeoverSheetState extends State<_SessionTakeoverSheet> {
  final _code = TextEditingController();
  String? _verificationId;
  bool _busy = false;
  String? _error;

  String? get _phone => AuthSessionService().user?.phoneNumber;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    // A second tap before the rebuild greys the control out.
    if (_busy) return;
    final phone = _phone;
    if (phone == null || phone.isEmpty) return;
    setState(() {
      _error = null;
      _busy = true;
    });
    try {
      final id = await context.read<AuthRepository>().startPhoneLink(
        phone,
        reauthenticate: true,
      );
      if (!mounted) return;
      // Verified without a code: the number is already confirmed again.
      if (id == AuthRepository.instantlyVerified) {
        await _takeover();
        return;
      }
      setState(() => _verificationId = id);
    } catch (e) {
      if (mounted) setState(() => _error = _messageFor(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirm() async {
    // A second tap before the rebuild greys the control out.
    if (_busy) return;
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
      await context.read<AuthRepository>().reauthenticatePhone(
        _verificationId!,
        code,
      );
      await _takeover();
    } catch (e) {
      if (mounted) setState(() => _error = _messageFor(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// After a fresh phone proof: this device takes the session over.
  Future<void> _takeover() async {
    if (!widget.takeover) {
      Navigator.of(context).pop(true);
      return;
    }
    final ok = await AuthSessionService().takeoverSession();
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _error = t.auth.sessionTakeoverFailed);
    }
  }

  String _messageFor(Object e) {
    debugPrint('Phone re-verification failed: $e');
    // The Firebase code when there is one, else the error type (a network
    // failure has no code) — the same fallback as AuthBloc.
    return e is AppException
        ? authErrorMessage(e.message.isNotEmpty ? e.message : e.type.name)
        : t.auth.errorUnknown;
  }

  @override
  Widget build(BuildContext context) {
    final phone = _phone;
    final awaitingCode = _verificationId != null;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.md,
          right: AppSpacing.md,
          top: AppSpacing.md,
          bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.md,
        ),
        // Scrolls once the keyboard (the code field autofocuses) leaves
        // less room than the sheet needs on a short phone.
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClaySectionHeader(
                title: widget.takeover
                    ? t.auth.sessionTakeoverTitle
                    : t.auth.reverifyTitle,
                underline: true,
              ),
              const SizedBox(height: AppSpacing.gutter),
              if (phone == null || phone.isEmpty)
                Text(
                  widget.takeover
                      ? t.auth.sessionTakeoverNoPhone
                      : t.auth.reverifyNoPhone,
                  style: AppTextStyles.bodyMd.copyWith(color: AppColors.error),
                )
              else ...[
                Text(
                  widget.takeover
                      ? t.auth.sessionTakeoverBody(phone: maskPhone(phone))
                      : t.auth.reverifyBody(phone: maskPhone(phone)),
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                if (awaitingCode)
                  TextField(
                    controller: _code,
                    autofocus: true,
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
                      errorText: _error,
                    ),
                  )
                else if (_error != null)
                  Text(
                    _error!,
                    style: AppTextStyles.labelMd.copyWith(
                      color: AppColors.error,
                    ),
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
            ],
          ),
        ),
      ),
    );
  }
}
