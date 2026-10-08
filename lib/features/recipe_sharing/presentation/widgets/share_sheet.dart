import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/services/auth_session_service.dart';
import '../../../../core/utils/contact_hash.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../../share_codes/domain/share_code_entity.dart';
import '../../../share_codes/presentation/share_code_hooks.dart';
import '../../../share_codes/presentation/widgets/share_code_panel.dart';
import '../../domain/usecases/share_recipe_usecase.dart';
import '../../../../core/features/feature_gate.dart';

/// What the sheet does once a contact and a role are chosen. Throws
/// [ShareFailure] for the reasons the sheet knows how to word.
typedef ShareSender =
    Future<void> Function(
      String contact, {
      required CollabRole role,
      required String uid,
      required List<String> senderContacts,
    });

/// Who to share with and what they may do — the same sheet for a recipe, a
/// book or a plan; only the heading and what happens on send differ. With
/// [codes] the sheet has a second mode: a code, link and QR anyone can
/// redeem, which produces the same invite a contact share does.
/// Resolves true when an invite went out.
Future<bool?> showShareSheet(
  BuildContext context, {
  required String title,
  required String subject,
  String? note,
  required ShareSender onSend,
  ShareCodeHooks? codes,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceContainerLowest,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.md)),
    ),
    builder: (_) => _ShareSheet(
      title: title,
      subject: subject,
      note: note,
      onSend: onSend,
      codes: codes,
    ),
  );
}

class _ShareSheet extends StatefulWidget {
  final String title;
  final String subject;
  final String? note;
  final ShareSender onSend;
  final ShareCodeHooks? codes;
  const _ShareSheet({
    required this.title,
    required this.subject,
    this.note,
    required this.onSend,
    this.codes,
  });

  @override
  State<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<_ShareSheet> {
  final _contact = TextEditingController();
  CollabRole _role = CollabRole.viewer;
  bool _busy = false;
  bool _hasContact = false;
  String? _error;

  /// 0 = a contact, 1 = a code or link.
  int _mode = 0;
  List<ShareCodeEntity>? _activeCodes;
  String? _codeError;

  @override
  void initState() {
    super.initState();
    _contact.addListener(() {
      final has = _contact.text.trim().isNotEmpty;
      if (has != _hasContact) setState(() => _hasContact = has);
    });
  }

  @override
  void dispose() {
    _contact.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (normalizeContact(_contact.text) == null) {
      setState(() => _error = t.sharing.invalidContact);
      return;
    }
    final user = AuthSessionService().user;
    final uid = user?.uid;
    if (uid == null) return;

    if (widget.codes case final codes?) {
      if (!await codes.gate(context, uid) || !mounted) return;
    }

    setState(() {
      _error = null;
      _busy = true;
    });
    try {
      await widget.onSend(
        _contact.text,
        role: _role,
        uid: uid,
        senderContacts: [user?.email, user?.phoneNumber].nonNulls.toList(),
      );
      await widget.codes?.recordShare();
      if (mounted) Navigator.of(context).pop(true);
    } on ShareFailure catch (e) {
      if (!mounted) return;
      setState(
        () => _error = switch (e.code) {
          ShareFailure.notFound => t.sharing.notFound,
          ShareFailure.directoryUnavailable => t.sharing.directoryUnavailable,
          ShareFailure.self => t.sharing.self,
          _ => t.sharing.invalidContact,
        },
      );
    } catch (e) {
      debugPrint('Share failed: $e');
      if (mounted) setState(() => _error = t.sharing.failed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _enterCodeMode() async {
    setState(() => _mode = 1);
    if (_activeCodes != null) return;
    final uid = AuthSessionService().user?.uid;
    final codes = widget.codes;
    if (uid == null || codes == null) return;
    try {
      final active = await codes.active(uid);
      if (mounted) setState(() => _activeCodes = active);
    } catch (e) {
      debugPrint('Share codes unavailable: $e');
      if (mounted) setState(() => _activeCodes = const []);
    }
  }

  ShareCodeEntity? get _codeForRole =>
      _activeCodes?.where((c) => c.role == _role).firstOrNull;

  Future<void> _createCode() async {
    final uid = AuthSessionService().user?.uid;
    final codes = widget.codes;
    if (uid == null || codes == null) return;
    if (!await codes.gate(context, uid) || !mounted) return;
    setState(() {
      _busy = true;
      _codeError = null;
    });
    try {
      final created = await codes.create(role: _role, uid: uid);
      await codes.recordShare();
      if (mounted) {
        setState(() => _activeCodes = [created, ...?_activeCodes]);
      }
    } catch (e) {
      debugPrint('Share code creation failed: $e');
      if (mounted) setState(() => _codeError = t.shareCode.failed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _revokeCode(ShareCodeEntity code) async {
    final codes = widget.codes;
    if (codes == null) return;
    setState(() => _busy = true);
    try {
      await codes.revoke(code);
      if (mounted) {
        setState(
          () => _activeCodes = [
            for (final c in _activeCodes ?? const <ShareCodeEntity>[])
              if (c.code != code.code) c,
          ],
        );
      }
    } catch (e) {
      debugPrint('Share code revoke failed: $e');
      if (mounted) setState(() => _codeError = t.shareCode.failed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final codeMode = _mode == 1 && widget.codes != null;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.md,
          right: AppSpacing.md,
          top: AppSpacing.md,
          bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.md,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClaySectionHeader(title: widget.title, underline: true),
              const SizedBox(height: AppSpacing.xs),
              Text(widget.subject, style: AppTextStyles.bodyLg),
              if (widget.note case final note?)
                Text(
                  note,
                  style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              const SizedBox(height: AppSpacing.md),
              if (widget.codes != null &&
                  FeaturesFlags.shareCodes.isVisible) ...[
                ClaySegmentedControl(
                  segments: [
                    ClaySegment(
                      label: t.shareCode.tabContact,
                      icon: Icons.alternate_email_rounded,
                    ),
                    ClaySegment(
                      label: t.shareCode.tabCode,
                      icon: Icons.qr_code_2_rounded,
                    ),
                  ],
                  selectedIndex: _mode,
                  onSelected: (index) {
                    if (index != 1) {
                      setState(() => _mode = 0);
                    } else if (guardFeature(
                      context,
                      FeaturesFlags.shareCodes,
                    )) {
                      _enterCodeMode();
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              if (!codeMode)
                TextField(
                  controller: _contact,
                  keyboardType: TextInputType.emailAddress,
                  textDirection: TextDirection.ltr,
                  autofillHints: const [
                    AutofillHints.email,
                    AutofillHints.telephoneNumber,
                  ],
                  style: AppTextStyles.bodyMd,
                  decoration: InputDecoration(
                    labelText: t.sharing.contactLabel,
                    hintText: t.sharing.contactHint,
                    errorText: _error,
                  ),
                ),
              if (!codeMode) const SizedBox(height: AppSpacing.md),
              ClaySectionHeader(title: t.sharing.roleTitle),
              const SizedBox(height: AppSpacing.sm),
              _roleOption(
                role: CollabRole.viewer,
                icon: Icons.visibility_rounded,
                title: t.sharing.roleViewer,
                hint: t.sharing.roleViewerHint,
              ),
              const SizedBox(height: AppSpacing.sm),
              _roleOption(
                role: CollabRole.editor,
                icon: Icons.edit_rounded,
                title: t.sharing.roleEditor,
                hint: t.sharing.roleEditorHint,
              ),
              const SizedBox(height: AppSpacing.md),
              if (codeMode && _activeCodes == null)
                const Center(child: CircularProgressIndicator())
              else if (codeMode)
                ShareCodePanel(
                  subject: widget.subject,
                  role: _role,
                  code: _codeForRole,
                  busy: _busy,
                  onCreate: _createCode,
                  onRevoke: () {
                    if (_codeForRole case final code?) _revokeCode(code);
                  },
                )
              else
                ClayButton(
                  label: t.sharing.send,
                  icon: Icons.send_rounded,
                  expanded: true,
                  onPressed: _busy || !_hasContact ? null : _send,
                ),
              if (codeMode && _codeError != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _codeError!,
                  style: AppTextStyles.labelSm.copyWith(color: AppColors.error),
                ),
              ],
              if (_busy && !codeMode) ...[
                const SizedBox(height: AppSpacing.md),
                const Center(child: CircularProgressIndicator()),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleOption({
    required CollabRole role,
    required IconData icon,
    required String title,
    required String hint,
  }) {
    final selected = _role == role;
    return ClayCard(
      radius: AppRadius.md,
      padding: const EdgeInsets.all(AppSpacing.md),
      isActive: selected,
      onTap: () => setState(() => _role = role),
      child: Row(
        children: [
          Icon(
            icon,
            size: 22,
            color: selected ? AppColors.primary : AppColors.tertiary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.bodyLg),
                Text(
                  hint,
                  style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (selected)
            Icon(Icons.check_circle_rounded, color: AppColors.primary),
        ],
      ),
    );
  }
}
