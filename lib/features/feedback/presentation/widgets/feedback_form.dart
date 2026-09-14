import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/services/auth_session_service.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../domain/entities/feedback_entity.dart';
import '../../domain/repositories/feedback_repository.dart';
import '../../domain/usecases/send_feedback_usecase.dart';

/// Bug or suggestion, a few lines of text, send. Lives at the bottom of the
/// support screen; the message lands in the administrator's inbox.
class FeedbackForm extends StatefulWidget {
  const FeedbackForm({super.key});

  @override
  State<FeedbackForm> createState() => _FeedbackFormState();
}

class _FeedbackFormState extends State<FeedbackForm> {
  final _message = TextEditingController();
  FeedbackType _type = FeedbackType.bug;
  bool _sending = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _message.addListener(() {
      final has = _message.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
  }

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final session = AuthSessionService();
    final uid = session.user?.uid;
    if (uid == null || _sending) return;

    // Read before the first await: the repository comes from the tree, and
    // the tree may be gone by the time the version lookup returns.
    final useCase = SendFeedbackUseCase(context.read<FeedbackRepository>());
    setState(() => _sending = true);
    try {
      String? version;
      try {
        version = (await PackageInfo.fromPlatform()).version;
      } catch (_) {
        // A missing version is not worth losing the message over.
      }
      await useCase(
        type: _type,
        message: _message.text,
        authorUid: uid,
        authorName: session.profile?.fullName ?? '',
        authorEmail: session.profile?.email ?? session.user?.email,
        appVersion: version,
      );
      if (!mounted) return;
      _message.clear();
      FocusScope.of(context).unfocus();
      AppDialog.success(message: t.feedback.sent).notify(context);
    } catch (e) {
      debugPrint('Feedback send failed: $e');
      if (mounted) AppDialog.error(message: t.feedback.failed).show(context);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClayCard(
      radius: AppRadius.md,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClaySectionHeader(title: t.feedback.title, underline: true),
          const SizedBox(height: AppSpacing.base),
          Text(
            t.feedback.subtitle,
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.gutter),
          ClaySegmentedControl(
            segments: [
              ClaySegment(label: t.feedback.bug, icon: Icons.bug_report_rounded),
              ClaySegment(label: t.feedback.suggestion, icon: Icons.lightbulb_rounded),
            ],
            selectedIndex: _type == FeedbackType.bug ? 0 : 1,
            onSelected: (index) => setState(
              () => _type = index == 0 ? FeedbackType.bug : FeedbackType.suggestion,
            ),
          ),
          const SizedBox(height: AppSpacing.gutter),
          TextField(
            controller: _message,
            minLines: 4,
            maxLines: 8,
            style: AppTextStyles.bodyMd,
            // The prompt follows the category: a bug wants what happened
            // and what was expected, an idea wants what it would change.
            decoration: InputDecoration(
              hintText: _type == FeedbackType.bug
                  ? t.feedback.bugHint
                  : t.feedback.suggestionHint,
            ),
          ),
          const SizedBox(height: AppSpacing.gutter),
          ClayButton(
            label: t.feedback.send,
            icon: Icons.send_rounded,
            expanded: true,
            onPressed: _hasText && !_sending ? _send : null,
          ),
        ],
      ),
    );
  }
}
