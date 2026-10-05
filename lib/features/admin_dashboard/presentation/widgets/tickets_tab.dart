import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' as intl;

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/services/admin_inbox_service.dart';
import '../../../../core/services/auth_session_service.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../../../core/widgets/refreshable_empty_state.dart';
import '../../../community/presentation/widgets/author_row.dart';
import '../../../feedback/domain/entities/feedback_entity.dart';
import '../../../feedback/domain/repositories/feedback_repository.dart';
import '../../../feedback/domain/usecases/manage_feedback_usecase.dart';
import 'compose_sheet.dart';

/// Every message users left on the support screen, live, newest first.
/// Unread ones are tinted and counted on the badge; each can be marked read
/// or unread again, answered (the answer lands in the writer's inbox) or
/// removed. "Read all" clears the badge in one tap.
class TicketsTab extends StatefulWidget {
  const TicketsTab({super.key});

  @override
  State<TicketsTab> createState() => _TicketsTabState();
}

enum _Filter { unread, all, bugs, suggestions }

class _TicketsTabState extends State<TicketsTab> {
  _Filter _filter = _Filter.unread;

  ManageFeedbackUseCase get _manage =>
      ManageFeedbackUseCase(context.read<FeedbackRepository>());

  @override
  void initState() {
    super.initState();
    // Normally bound by the session on sign-in; a hot restart lands here
    // without it, and the tab would sit empty for no reason.
    if (!AdminInboxService().isBound) {
      AdminInboxService().bind(context.read<FeedbackRepository>());
    }
  }

  List<FeedbackEntity> _visible(List<FeedbackEntity> all) => switch (_filter) {
    _Filter.unread => all.where((f) => !f.read).toList(),
    _Filter.all => all,
    _Filter.bugs => all.where((f) => f.type == FeedbackType.bug).toList(),
    _Filter.suggestions =>
      all.where((f) => f.type == FeedbackType.suggestion).toList(),
  };

  Future<void> _run(Future<void> Function() work, {String? done}) async {
    try {
      await AppDialog.busy(context, work);
      if (done != null && mounted) {
        AppDialog.success(message: done).notify(context);
      }
    } catch (e) {
      debugPrint('Ticket action failed: $e');
      if (mounted) {
        AppDialog.error(message: '${t.common.error}\n$e').show(context);
      }
    }
  }

  Future<void> _toggleRead(FeedbackEntity f) =>
      _run(() => _manage.setRead(f, !f.read));

  Future<void> _markAllRead(List<FeedbackEntity> all) =>
      _run(() => _manage.markAllRead(all), done: t.adminDashboard.allRead);

  Future<void> _delete(FeedbackEntity f) async {
    final s = t.adminDashboard;
    final ok = await AppDialog.warning(
      title: s.deleteTicket,
      message: s.deleteTicketConfirm(
        name: f.authorName.isEmpty ? f.authorUid : f.authorName,
      ),
      confirmLabel: t.common.delete,
      cancelLabel: t.common.cancel,
      destructive: true,
    ).show(context);
    if (ok != true || !mounted) return;
    await _run(() => _manage.delete(f), done: s.ticketDeleted);
  }

  Future<void> _reply(FeedbackEntity f) async {
    final s = t.adminDashboard;
    final uid = AuthSessionService().user?.uid;
    if (uid == null) return;
    final message = await showComposeSheet(
      context,
      heading:
          '${s.reply} · ${f.authorName.isEmpty ? f.authorUid : f.authorName}',
      hint: s.replyHint,
      withTitle: false,
      quote: f.message,
      confirmLabel: s.send,
    );
    if (message == null || !mounted) return;
    // Read once, before the awaits inside: `_manage` reaches for context.
    final manage = _manage;
    await _run(
      () async {
        await manage.reply(f, message.body, fromUid: uid);
        if (!f.read) await manage.setRead(f, true);
      },
      done: s.replySent,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = t.adminDashboard;
    return ValueListenableBuilder<List<FeedbackEntity>>(
      valueListenable: AdminInboxService().items,
      builder: (context, all, _) {
        final unread = all.where((f) => !f.read).length;
        final items = _visible(all);
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.marginMobile,
                AppSpacing.sm,
                AppSpacing.marginMobile,
                AppSpacing.sm,
              ),
              child: Column(
                children: [
                  ClaySegmentedControl(
                    segments: [
                      ClaySegment(
                        label: s.unread,
                        icon: Icons.mark_email_unread_rounded,
                        badge: unread,
                      ),
                      ClaySegment(
                        label: t.feedback.all,
                        icon: Icons.inbox_rounded,
                      ),
                      ClaySegment(
                        label: t.feedback.bugs,
                        icon: Icons.bug_report_rounded,
                      ),
                      ClaySegment(
                        label: t.feedback.suggestions,
                        icon: Icons.lightbulb_rounded,
                      ),
                    ],
                    selectedIndex: _filter.index,
                    onSelected: (index) =>
                        setState(() => _filter = _Filter.values[index]),
                  ),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton.icon(
                      onPressed: unread == 0 ? null : () => _markAllRead(all),
                      icon: const Icon(Icons.done_all_rounded, size: 18),
                      label: Text(s.markAllRead),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: items.isEmpty
                  ? RefreshableEmptyState(
                      child: ClayEmptyState(
                        icon: _filter == _Filter.unread
                            ? Icons.mark_email_read_rounded
                            : Icons.inbox_rounded,
                        message: _filter == _Filter.unread
                            ? s.noUnread
                            : t.feedback.none,
                      ),
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.marginMobile,
                        0,
                        AppSpacing.marginMobile,
                        AppSpacing.xl,
                      ),
                      itemCount: items.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) => _TicketCard(
                        feedback: items[index],
                        onToggleRead: () => _toggleRead(items[index]),
                        onReply: () => _reply(items[index]),
                        onDelete: () => _delete(items[index]),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _TicketCard extends StatelessWidget {
  final FeedbackEntity feedback;
  final VoidCallback onToggleRead;
  final VoidCallback onReply;
  final VoidCallback onDelete;

  const _TicketCard({
    required this.feedback,
    required this.onToggleRead,
    required this.onReply,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final f = feedback;
    final s = t.adminDashboard;
    final isBug = f.type == FeedbackType.bug;
    final muted = AppTextStyles.labelSm.copyWith(
      color: AppColors.onSurfaceVariant,
    );

    return ClayCard(
      radius: AppRadius.md,
      padding: const EdgeInsets.all(AppSpacing.md),
      color: f.read ? null : AppColors.primaryFixed,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AuthorRow(
            name: f.authorName.isEmpty ? f.authorUid : f.authorName,
            createdAt: f.createdAt,
            trailing: Padding(
              padding: const EdgeInsetsDirectional.only(start: AppSpacing.sm),
              child: ClayTag(
                label: isBug ? t.feedback.bug : t.feedback.suggestion,
                icon: isBug
                    ? Icons.bug_report_rounded
                    : Icons.lightbulb_rounded,
                background: isBug
                    ? AppColors.errorContainer
                    : AppColors.infoContainer,
                foreground: isBug
                    ? AppColors.onErrorContainer
                    : AppColors.onInfoContainer,
              ),
            ),
          ),
          if (f.authorEmail case final email?) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(email, textDirection: TextDirection.ltr, style: muted),
          ],
          const SizedBox(height: AppSpacing.sm),
          SelectableText(f.message, style: AppTextStyles.bodyMd),
          if (f.appVersion case final version?) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              t.feedback.version(version: version),
              style: AppTextStyles.labelSm.copyWith(color: AppColors.tertiary),
            ),
          ],
          for (final reply in f.replies) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.yourReply(
                      date: intl.DateFormat(
                        'dd/MM/yyyy HH:mm',
                      ).format(reply.at),
                    ),
                    style: muted,
                  ),
                  const SizedBox(height: 2),
                  Text(reply.text, style: AppTextStyles.labelMd),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: ClayButton(
                  label: s.reply,
                  icon: Icons.reply_rounded,
                  expanded: true,
                  onPressed: onReply,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              ClayIconButton(
                icon: f.read
                    ? Icons.mark_email_unread_rounded
                    : Icons.mark_email_read_rounded,
                tooltip: f.read ? s.markUnread : s.markRead,
                onTap: onToggleRead,
              ),
              const SizedBox(width: AppSpacing.xs),
              ClayIconButton(
                icon: Icons.delete_outline_rounded,
                tooltip: s.deleteTicket,
                onTap: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
