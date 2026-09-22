import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/clay/clay.dart';

/// What the compose sheet returns.
class ComposedMessage {
  final String title;
  final String body;

  const ComposedMessage({required this.title, required this.body});
}

/// A title (optional) and a body, for a push, a broadcast or a reply. Null
/// when the administrator backs out.
Future<ComposedMessage?> showComposeSheet(
  BuildContext context, {
  required String heading,
  String? hint,
  bool withTitle = true,
  String? quote,
  String? confirmLabel,
}) {
  return showModalBottomSheet<ComposedMessage>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
      ),
      child: _ComposeSheet(
        heading: heading,
        hint: hint,
        withTitle: withTitle,
        quote: quote,
        confirmLabel: confirmLabel ?? t.adminDashboard.send,
      ),
    ),
  );
}

class _ComposeSheet extends StatefulWidget {
  final String heading;
  final String? hint;
  final bool withTitle;
  final String? quote;
  final String confirmLabel;

  const _ComposeSheet({
    required this.heading,
    required this.hint,
    required this.withTitle,
    required this.quote,
    required this.confirmLabel,
  });

  @override
  State<_ComposeSheet> createState() => _ComposeSheetState();
}

class _ComposeSheetState extends State<_ComposeSheet> {
  final _title = TextEditingController();
  final _body = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.marginMobile,
          AppSpacing.md,
          AppSpacing.marginMobile,
          AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.heading, style: AppTextStyles.headlineMd),
            if (widget.quote case final quote?) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  quote,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
            if (widget.hint case final hint?) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                hint,
                style: AppTextStyles.labelSm.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            if (widget.withTitle) ...[
              TextField(
                controller: _title,
                style: AppTextStyles.bodyMd,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  hintText: t.adminDashboard.pushTitle,
                  isDense: true,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            TextField(
              controller: _body,
              style: AppTextStyles.bodyMd,
              minLines: 3,
              maxLines: 8,
              autofocus: !widget.withTitle,
              decoration: InputDecoration(hintText: t.adminDashboard.pushBody),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.gutter),
            ClayButton(
              label: widget.confirmLabel,
              icon: Icons.send_rounded,
              expanded: true,
              onPressed: _body.text.trim().isEmpty
                  ? null
                  : () => Navigator.of(context).pop(
                      ComposedMessage(
                        title: _title.text.trim(),
                        body: _body.text.trim(),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
