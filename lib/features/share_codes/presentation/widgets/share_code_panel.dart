import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../core/constants/app_shadows.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/services/auth_session_service.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../../../core/widgets/press_scale.dart';
import '../../domain/share_code_entity.dart';

/// The code side of the share sheet: the live code for the chosen role as a
/// QR tile and an eight-letter chip that copies on tap, or the button that
/// makes one. The system share sheet and cancelling the code live here too.
class ShareCodePanel extends StatelessWidget {
  final String subject;
  final CollabRole role;
  final ShareCodeEntity? code;
  final bool busy;
  final VoidCallback onCreate;
  final VoidCallback onRevoke;

  /// The role sentence above the code; off where the role is not a choice.
  final bool showExplain;

  /// The text the system share sheet sends, given the sender's name and
  /// the link. Defaults to the recipe/book/plan wording.
  final String Function(String name, String link)? messageText;

  const ShareCodePanel({
    super.key,
    required this.subject,
    required this.role,
    required this.code,
    required this.busy,
    required this.onCreate,
    required this.onRevoke,
    this.showExplain = true,
    this.messageText,
  });

  String get _roleLabel => switch (role) {
    CollabRole.editor => t.sharing.roleEditor,
    _ => t.sharing.roleViewer,
  };

  @override
  Widget build(BuildContext context) {
    final code = this.code;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showExplain) ...[
          Text(
            t.shareCode.explain(role: _roleLabel),
            style: AppTextStyles.labelSm.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (code == null)
          ClayButton(
            label: t.shareCode.create,
            icon: Icons.qr_code_2_rounded,
            expanded: true,
            onPressed: busy ? null : onCreate,
          )
        else ...[
          ClayCard(
            radius: AppRadius.md,
            padding: const EdgeInsets.all(AppSpacing.gutter),
            color: AppColors.primaryFixed,
            child: Column(
              children: [
                _QrTile(data: code.link),
                const SizedBox(height: AppSpacing.gutter),
                _CodeChip(code: code.code, onCopy: () => _copy(context, code)),
                const SizedBox(height: AppSpacing.base),
                Text(
                  t.shareCode.code,
                  style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.onPrimaryFixedVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ClayButton(
            label: t.shareCode.share,
            icon: Icons.ios_share_rounded,
            expanded: true,
            onPressed: () => _shareOut(context, code),
          ),
          const SizedBox(height: AppSpacing.sm),
          ClayButton(
            label: t.shareCode.revoke,
            icon: Icons.link_off_rounded,
            expanded: true,
            destructive: true,
            onPressed: busy ? null : onRevoke,
          ),
        ],
      ],
    );
  }

  Future<void> _copy(BuildContext context, ShareCodeEntity code) async {
    await Clipboard.setData(ClipboardData(text: code.code));
    HapticFeedback.lightImpact();
    if (context.mounted) {
      AppDialog.success(message: t.shareCode.copied).notify(context);
    }
  }

  /// The system share sheet: WhatsApp, mail, anything the phone offers.
  Future<void> _shareOut(BuildContext context, ShareCodeEntity code) async {
    final name = AuthSessionService().profile?.fullName.trim() ?? '';
    final sender = name.isEmpty ? t.appName : name;
    final text =
        messageText?.call(sender, code.link) ??
        t.shareCode.messageText(
          name: sender,
          title: subject,
          code: code.display,
          link: code.link,
        );
    final box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: subject,
        // iPadOS anchors the popover here; a phone ignores it.
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }
}

/// The QR on a white clay tile with the app icon in its middle, so the
/// code reads as EasyPlate's at a glance.
class _QrTile extends StatelessWidget {
  final String data;
  const _QrTile({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.std),
        boxShadow: AppShadows.card,
      ),
      child: QrImageView(
        data: data,
        size: 164,
        padding: EdgeInsets.zero,
        backgroundColor: Colors.white,
        errorCorrectionLevel: QrErrorCorrectLevel.H,
        eyeStyle: QrEyeStyle(
          eyeShape: QrEyeShape.circle,
          color: AppColors.onPrimaryFixed,
        ),
        dataModuleStyle: QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.circle,
          color: AppColors.onPrimaryFixed,
        ),
        embeddedImage: const AssetImage('assets/app_icon.png'),
        embeddedImageStyle: const QrEmbeddedImageStyle(size: Size(36, 36)),
      ),
    );
  }
}

/// The eight letters in a recessed chip; the chip and the copy button both
/// copy them.
class _CodeChip extends StatelessWidget {
  final String code;
  final VoidCallback onCopy;
  const _CodeChip({required this.code, required this.onCopy});

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onCopy,
      scale: 0.98,
      child: ClayInset(
        radius: AppRadius.std,
        padding: const EdgeInsetsDirectional.only(
          start: AppSpacing.gutter,
          end: AppSpacing.base,
          top: AppSpacing.base,
          bottom: AppSpacing.base,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                code,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.center,
                style: AppTextStyles.headlineMd.copyWith(
                  letterSpacing: 5,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.base),
            ClayIconButton(
              icon: Icons.copy_rounded,
              tooltip: t.shareCode.copy,
              filled: true,
              size: 40,
              onTap: onCopy,
            ),
          ],
        ),
      ),
    );
  }
}
