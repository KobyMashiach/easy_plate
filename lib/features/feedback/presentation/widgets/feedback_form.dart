import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' as intl;
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/features/features_flags.dart';
import '../../../../core/services/auth_session_service.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/utils/routing/routing.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../domain/entities/feedback_entity.dart';
import '../../domain/repositories/feedback_repository.dart';
import '../../domain/support_details.dart';
import '../../domain/usecases/send_feedback_usecase.dart';

/// The reason's name in the UI's language.
String feedbackTypeLabel(FeedbackType type) => switch (type) {
  FeedbackType.bug => t.feedback.reasons.bug,
  FeedbackType.suggestion => t.feedback.reasons.suggestion,
  FeedbackType.account => t.feedback.reasons.account,
  FeedbackType.billing => t.feedback.reasons.billing,
  FeedbackType.sharing => t.feedback.reasons.sharing,
  FeedbackType.recipes => t.feedback.reasons.recipes,
  FeedbackType.other => t.feedback.reasons.other,
};

IconData feedbackTypeIcon(FeedbackType type) => switch (type) {
  FeedbackType.bug => Icons.bug_report_rounded,
  FeedbackType.suggestion => Icons.lightbulb_rounded,
  FeedbackType.account => Icons.person_rounded,
  FeedbackType.billing => Icons.workspace_premium_rounded,
  FeedbackType.sharing => Icons.group_rounded,
  FeedbackType.recipes => Icons.auto_awesome_rounded,
  FeedbackType.other => Icons.chat_bubble_rounded,
};

/// Reason, message, send: the opening of a support conversation. Lives at
/// the bottom of the support screen; the message lands in the
/// administrator's inbox and, with the chat on, the screen goes on to the
/// conversation, where the answer arrives. Below the form, the account's
/// own conversations.
class FeedbackForm extends StatefulWidget {
  const FeedbackForm({super.key});

  @override
  State<FeedbackForm> createState() => _FeedbackFormState();
}

class _FeedbackFormState extends State<FeedbackForm> {
  final _message = TextEditingController();
  FeedbackType? _type;
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

  bool get _chatOn => FeaturesFlags.supportChat.isEnabled;

  Future<void> _send() async {
    final session = AuthSessionService();
    final uid = session.user?.uid;
    final type = _type;
    if (uid == null || type == null || _sending) return;

    // Read before the first await: the repository comes from the tree, and
    // the tree may be gone by the time the version lookup returns.
    final useCase = SendFeedbackUseCase(context.read<FeedbackRepository>());
    final chatOn = _chatOn;
    setState(() => _sending = true);
    try {
      String? version;
      try {
        version = (await PackageInfo.fromPlatform()).version;
      } catch (_) {
        // A missing version is not worth losing the message over.
      }
      final details = await SupportDetails.collect();
      final id = await useCase(
        type: type,
        message: _message.text,
        authorUid: uid,
        authorName: session.profile?.fullName ?? '',
        authorEmail: session.profile?.email ?? session.user?.email,
        appVersion: version,
        details: details,
      );
      if (!mounted) return;
      _message.clear();
      setState(() => _type = null);
      FocusScope.of(context).unfocus();
      if (chatOn) {
        context.pushNamed(Routing.supportChat, extra: id);
      } else {
        AppDialog.success(message: t.feedback.sent).notify(context);
      }
    } catch (e) {
      debugPrint('Feedback send failed: $e');
      if (mounted) AppDialog.error(message: t.feedback.failed).show(context);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = AuthSessionService().user?.uid;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClayCard(
          radius: AppRadius.md,
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClaySectionHeader(title: t.feedback.title, underline: true),
              const SizedBox(height: AppSpacing.base),
              Text(
                t.feedback.subtitle,
                style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.gutter),
              DropdownButtonFormField<FeedbackType>(
                key: const ValueKey('feedback.reason'),
                initialValue: _type,
                isExpanded: true,
                hint: Text(
                  t.feedback.reasonHint,
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.outline,
                  ),
                ),
                decoration: InputDecoration(labelText: t.feedback.reasonLabel),
                style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.onSurface,
                ),
                dropdownColor: AppColors.surfaceBright,
                borderRadius: BorderRadius.circular(AppRadius.std),
                items: [
                  for (final type in FeedbackType.values)
                    DropdownMenuItem(
                      value: type,
                      child: Row(
                        children: [
                          Icon(
                            feedbackTypeIcon(type),
                            size: 18,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: AppSpacing.base),
                          Expanded(
                            child: Text(
                              feedbackTypeLabel(type),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
                onChanged: (type) => setState(() => _type = type),
              ),
              const SizedBox(height: AppSpacing.gutter),
              TextField(
                key: const ValueKey('feedback.message'),
                controller: _message,
                minLines: 4,
                maxLines: 8,
                maxLength: 4000,
                style: AppTextStyles.bodyMd,
                decoration: InputDecoration(
                  labelText: t.feedback.messageLabel,
                  hintText: t.feedback.messageHint,
                  alignLabelWithHint: true,
                  counterText: '',
                ),
              ),
              const SizedBox(height: AppSpacing.gutter),
              ClayButton(
                key: const ValueKey('feedback.send'),
                label: t.feedback.send,
                icon: Icons.send_rounded,
                expanded: true,
                // Both fields are required: the button waits for them.
                onPressed: _hasText && _type != null && !_sending
                    ? _send
                    : null,
              ),
            ],
          ),
        ),
        if (uid != null && _chatOn) _MyConversations(uid: uid),
      ],
    );
  }
}

/// The account's own conversations, newest activity first, with a mark on
/// the ones the team answered since they were last opened.
class _MyConversations extends StatelessWidget {
  final String uid;

  const _MyConversations({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<FeedbackEntity>>(
      stream: context.read<FeedbackRepository>().watchMine(uid),
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <FeedbackEntity>[];
        if (items.isEmpty) return const SizedBox.shrink();
        final open = [for (final i in items) if (!i.closed) i];
        final closed = [for (final i in items) if (i.closed) i];
        return Padding(
          padding: const EdgeInsets.only(top: AppSpacing.lg),
          child: ClayCard(
            radius: AppRadius.md,
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClaySectionHeader(
                  title: t.feedback.myConversations,
                  underline: true,
                ),
                if (open.isEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    t.feedback.noOpenConversations,
                    style: AppTextStyles.labelMd.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
                for (final item in open) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _ConversationRow(item: item),
                ],
                // The closed ones, folded away: still readable, no longer
                // writable.
                if (closed.isNotEmpty)
                  ExpansionTile(
                    key: const ValueKey('feedback.closed'),
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.archive_rounded,
                      color: AppColors.onSurfaceVariant,
                    ),
                    title: Text(
                      t.feedback.closedConversations(n: closed.length),
                      style: AppTextStyles.bodyMd,
                    ),
                    children: [
                      for (final item in closed) _ConversationRow(item: item),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ConversationRow extends StatelessWidget {
  final FeedbackEntity item;

  const _ConversationRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final last = item.last;
    final unread = item.userUnread;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      onTap: () => context.pushNamed(Routing.supportChat, extra: item.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.base),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: item.closed
                    ? AppColors.surfaceContainer
                    : unread
                    ? AppColors.primary
                    : AppColors.primaryFixed,
                shape: BoxShape.circle,
              ),
              child: Icon(
                item.closed ? Icons.lock_rounded : feedbackTypeIcon(item.type),
                size: 20,
                color: item.closed
                    ? AppColors.onSurfaceVariant
                    : unread
                    ? AppColors.onPrimary
                    : AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          feedbackTypeLabel(item.type),
                          style: unread
                              ? AppTextStyles.bodyMd.copyWith(
                                  fontWeight: FontWeight.w700,
                                )
                              : AppTextStyles.bodyMd,
                        ),
                      ),
                      Text(
                        intl.DateFormat('dd/MM').format(last.at),
                        style: AppTextStyles.labelSm.copyWith(
                          color: AppColors.outline,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${last.fromAdmin ? t.feedback.team : t.feedback.you}: '
                    '${FeedbackEntity.excerptOf(last.text)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelSm.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
