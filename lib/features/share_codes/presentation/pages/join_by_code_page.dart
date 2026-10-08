import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/services/auth_session_service.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/utils/routing/routing.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../domain/share_code_entity.dart';
import '../../domain/share_code_service.dart';
import '../../domain/share_codes_repository.dart';

/// Type, paste or scan a code and the shared recipe, book or plan lands on
/// this account, as accepting the invite from the inbox would. Opened with
/// a code (a link tapped elsewhere) it joins at once.
class JoinByCodePage extends StatefulWidget {
  final String? initialCode;
  const JoinByCodePage({super.key, this.initialCode});

  @override
  State<JoinByCodePage> createState() => _JoinByCodePageState();
}

class _JoinByCodePageState extends State<JoinByCodePage> {
  late final _input = TextEditingController(
    text: switch (widget.initialCode) {
      final raw? => ShareCodeEntity.parse(raw) ?? raw,
      null => '',
    },
  );
  bool _busy = false;
  bool _hasText = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _hasText = _input.text.trim().isNotEmpty;
    _input.addListener(() {
      final has = _input.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
      if (_error != null) setState(() => _error = null);
    });
    if (ShareCodeEntity.parse(widget.initialCode ?? '') != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _join());
    }
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    final code = await context.pushNamed<String>(Routing.scanCode);
    if (code == null || !mounted) return;
    _input.text = code;
    await _join();
  }

  Future<void> _join() async {
    final uid = AuthSessionService().user?.uid;
    if (uid == null || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await context.read<ShareCodeService>().join(
        _input.text,
        uid: uid,
      );
      if (!mounted) return;
      final dialog = result.alreadyMember
          ? AppDialog.info(message: t.shareCode.alreadyMember)
          : result.kind == CollabKind.household
          ? AppDialog.success(message: t.household.joined)
          : AppDialog.success(message: t.shareCode.joined(title: result.title));
      await dialog.show(context);
      if (mounted) Navigator.of(context).maybePop(true);
    } on ShareCodeRefused catch (e) {
      if (!mounted) return;
      setState(
        () => _error = switch (e.code) {
          ShareCodeRefused.expired => t.shareCode.expired,
          ShareCodeRefused.revoked => t.shareCode.revoked,
          ShareCodeRefused.usedUp => t.shareCode.usedUp,
          ShareCodeRefused.self => t.shareCode.self,
          ShareCodeRefused.gone => t.shareCode.gone,
          ShareCodeRefused.full => t.household.full,
          ShareCodeRefused.inHousehold => t.household.inHousehold,
          ShareCodeRefused.notEligible => t.household.notEligibleCode,
          _ => t.shareCode.invalid,
        },
      );
    } catch (e) {
      debugPrint('Join by code failed: $e');
      if (mounted) setState(() => _error = t.shareCode.failed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClayScaffold(
      appBar: ClayTopAppBar(
        title: t.shareCode.joinTitle,
        leadingIcon: Icons.arrow_back_rounded,
        onLeadingTap: () => Navigator.of(context).maybePop(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.marginMobile),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              t.shareCode.joinHint,
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _input,
              autofocus: !_hasText,
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.center,
              textCapitalization: TextCapitalization.characters,
              autocorrect: false,
              enableSuggestions: false,
              inputFormatters: [LengthLimitingTextInputFormatter(120)],
              style: AppTextStyles.headlineMd.copyWith(letterSpacing: 2),
              decoration: InputDecoration(
                hintText: t.shareCode.joinPlaceholder,
                errorText: _error,
              ),
              onSubmitted: (_) => _join(),
            ),
            const SizedBox(height: AppSpacing.md),
            ClayButton(
              label: t.shareCode.join,
              icon: Icons.login_rounded,
              expanded: true,
              onPressed: _busy || !_hasText ? null : _join,
            ),
            const SizedBox(height: AppSpacing.sm),
            ClayButton(
              label: t.shareCode.scanQr,
              icon: Icons.qr_code_scanner_rounded,
              expanded: true,
              onPressed: _busy ? null : _scan,
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
