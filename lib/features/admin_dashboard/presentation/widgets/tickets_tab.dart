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
import '../../../feedback/presentation/widgets/feedback_form.dart';
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

enum _Filter { unread, all, bugs, suggestions, closed }

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

  /// Closed conversations live under their own filter; every other view
  /// is the open inbox.
  List<FeedbackEntity> _visible(List<FeedbackEntity> all) {
    final open = all.where((f) => !f.closed);
    return switch (_filter) {
      _Filter.unread => open.where((f) => !f.read).toList(),
      _Filter.all => open.toList(),
      _Filter.bugs => open.where((f) => f.type == FeedbackType.bug).toList(),
      _Filter.suggestions =>
        open.where((f) => f.type == FeedbackType.suggestion).toList(),
      _Filter.closed => all.where((f) => f.closed).toList(),
    };
  }

  Future<void> _toggleClosed(FeedbackEntity f) async {
    final s = t.adminDashboard;
    if (!f.closed) {
      final ok = await AppDialog.warning(
        title: s.closeTicket,
        message: s.closeTicketConfirm(
          name: f.authorName.isEmpty ? f.authorUid : f.authorName,
        ),
        confirmLabel: s.closeTicket,
        cancelLabel: t.common.cancel,
      ).show(context);
      if (ok != true || !mounted) return;
    }
    final manage = _manage;
    await _run(
      () => f.closed ? manage.reopen(f) : manage.close(f),
      done: f.closed ? s.ticketReopened : s.ticketClosed,
    );
  }

  Future<void> _run(Future<void> Function() work, {String? done}) async {
    try {
      await AppDialog.busy(context, work);
      if (done != null && mounted) {
        AppDialog.success(message: done).notify(context);
      }
    } catch (e) {
      debugPrint('Ticket action failed: $e');
      if (mounted) {
        AppDialog.error(message: t.common.error).show(context);
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
                      ClaySegment(
                        label: s.closedTickets,
                        icon: Icons.archive_rounded,
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
                        onToggleClosed: () => _toggleClosed(items[index]),
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
  final VoidCallback onToggleClosed;

  const _TicketCard({
    required this.feedback,
    required this.onToggleRead,
    required this.onReply,
    required this.onDelete,
    required this.onToggleClosed,
  });

  @override
  Widget build(BuildContext context) {
    final f = feedback;
    final s = t.adminDashboard;
    final isBug = f.type == FeedbackType.bug;
    final muted = AppTextStyles.labelSm.copyWith(
      color: AppColors.onSurfaceVariant,
    );
    final stamp = intl.DateFormat('dd/MM/yyyy HH:mm');

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
                label: feedbackTypeLabel(f.type),
                icon: feedbackTypeIcon(f.type),
                background: isBug
                    ? AppColors.errorContainer
                    : AppColors.infoContainer,
                foreground: isBug
                    ? AppColors.onErrorContainer
                    : AppColors.onInfoContainer,
              ),
            ),
          ),
          if (f.source == FeedbackSource.shefi) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(t.feedback.viaShefi, style: muted),
          ],
          if (f.closed) ...[
            const SizedBox(height: AppSpacing.xs),
            ClayTag(
              label: f.closedAt == null
                  ? s.closedTag
                  : s.closedAt(date: stamp.format(f.closedAt!)),
              icon: Icons.archive_rounded,
            ),
          ],
          if (f.authorEmail case final email?) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(email, textDirection: TextDirection.ltr, style: muted),
          ],
          // The whole conversation in order: the user's lines plain, the
          // administrator's own answers boxed.
          for (final line in f.thread) ...[
            const SizedBox(height: AppSpacing.sm),
            if (line.fromAdmin)
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
                      s.yourReply(date: stamp.format(line.at)),
                      style: muted,
                    ),
                    const SizedBox(height: 2),
                    Text(line.text, style: AppTextStyles.labelMd),
                  ],
                ),
              )
            else ...[
              if (line.at != f.createdAt)
                Text(
                  t.feedback.userWrote(date: stamp.format(line.at)),
                  style: muted,
                ),
              SelectableText(line.text, style: AppTextStyles.bodyMd),
            ],
          ],
          if (f.appVersion case final version?) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              t.feedback.version(version: version),
              style: AppTextStyles.labelSm.copyWith(color: AppColors.tertiary),
            ),
          ],
          // The signature the mail and WhatsApp routes carry, kept on the
          // message for the administrator; the writer's chat never shows it.
          if (f.details.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              dense: true,
              title: Text(t.feedback.details, style: muted),
              children: [
                for (final e in f.details.entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: SelectableText(
                      '${e.key}: ${e.value}',
                      textDirection: TextDirection.ltr,
                      style: AppTextStyles.labelSm,
                    ),
                  ),
              ],
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
                  // A closed conversation is read only for both sides;
                  // reopen it to answer again.
                  onPressed: f.closed ? null : onReply,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              ClayIconButton(
                icon: f.closed
                    ? Icons.unarchive_rounded
                    : Icons.archive_rounded,
                tooltip: f.closed ? s.reopenTicket : s.closeTicket,
                onTap: onToggleClosed,
              ),
              const SizedBox(width: AppSpacing.xs),
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
