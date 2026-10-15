import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' as intl;

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../domain/entities/feedback_entity.dart';
import '../../domain/repositories/feedback_repository.dart';
import '../../domain/usecases/send_feedback_usecase.dart';
import '../widgets/feedback_form.dart';

/// One support conversation, live: the user's lines on one side, the
/// team's on the other, and a box to write the next one. Opening it marks
/// the team's answer as seen. The signature details the message carries
/// (name, email, phone, build…) are the administrator's to read; nothing
/// here shows them.
class SupportChatPage extends StatefulWidget {
  final String feedbackId;

  const SupportChatPage({super.key, required this.feedbackId});

  @override
  State<SupportChatPage> createState() => _SupportChatPageState();
}

class _SupportChatPageState extends State<SupportChatPage> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  bool _sending = false;
  bool _hasText = false;
  int _seenLength = -1;

  ContinueFeedbackUseCase get _useCase =>
      ContinueFeedbackUseCase(context.read<FeedbackRepository>());

  @override
  void initState() {
    super.initState();
    _input.addListener(() {
      final has = _input.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// A new line (ours or theirs) scrolls into view, and an unseen answer
  /// is marked seen — once per change, not on every rebuild.
  void _onThread(FeedbackEntity item) {
    final length = item.thread.length;
    if (length == _seenLength) return;
    _seenLength = length;
    if (item.userUnread) _useCase.seen(item.id);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    if (_sending || !_hasText) return;
    final useCase = _useCase;
    final text = _input.text;
    setState(() => _sending = true);
    try {
      await useCase.followUp(widget.feedbackId, text);
      if (mounted) _input.clear();
    } catch (e) {
      debugPrint('Follow-up failed: $e');
      if (mounted) AppDialog.error(message: t.feedback.failed).show(context);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<FeedbackEntity?>(
      stream: context.read<FeedbackRepository>().watchOne(widget.feedbackId),
      builder: (context, snapshot) {
        final item = snapshot.data;
        if (item != null) _onThread(item);
        return ClayScaffold(
          appBar: ClayTopAppBar(
            title: item == null
                ? t.feedback.chatTitle
                : feedbackTypeLabel(item.type),
            leadingIcon: Icons.arrow_back_rounded,
            onLeadingTap: () => Navigator.of(context).maybePop(),
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: switch ((snapshot.connectionState, item)) {
                    (ConnectionState.waiting, null) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    (_, null) => Center(
                      child: ClayEmptyState(
                        icon: Icons.chat_bubble_outline_rounded,
                        message: t.feedback.conversationGone,
                      ),
                    ),
                    (_, final FeedbackEntity thread) => _Thread(
                      item: thread,
                      controller: _scroll,
                    ),
                  },
                ),
                if (item != null && item.closed)
                  const _ClosedNotice()
                else if (item != null)
                  _Composer(
                    controller: _input,
                    enabled: _hasText && !_sending,
                    onSend: _send,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Thread extends StatelessWidget {
  final FeedbackEntity item;
  final ScrollController controller;

  const _Thread({required this.item, required this.controller});

  @override
  Widget build(BuildContext context) {
    final lines = item.thread;
    return ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.marginMobile,
        AppSpacing.gutter,
        AppSpacing.marginMobile,
        AppSpacing.gutter,
      ),
      children: [
        for (final line in lines) _Bubble(line: line),
        if (!item.answered && !item.closed)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              t.feedback.waitingForReply,
              textAlign: TextAlign.center,
              style: AppTextStyles.labelSm.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  final FeedbackMessage line;

  const _Bubble({required this.line});

  @override
  Widget build(BuildContext context) {
    final mine = !line.fromAdmin;
    const radius = Radius.circular(AppRadius.std);
    return Align(
      alignment: mine
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.8,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.base,
        ),
        decoration: BoxDecoration(
          color: mine ? AppColors.primaryFixed : AppColors.surfaceContainer,
          borderRadius: BorderRadiusDirectional.only(
            topStart: radius,
            topEnd: radius,
            bottomStart: mine ? radius : Radius.zero,
            bottomEnd: mine ? Radius.zero : radius,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              mine ? t.feedback.you : t.feedback.team,
              style: AppTextStyles.labelSm.copyWith(
                color: mine ? AppColors.primary : AppColors.tertiary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            SelectableText(line.text, style: AppTextStyles.bodyMd),
            const SizedBox(height: 2),
            Text(
              intl.DateFormat('dd/MM/yyyy HH:mm').format(line.at),
              style: AppTextStyles.labelSm.copyWith(color: AppColors.outline),
            ),
          ],
        ),
      ),
    );
  }
}

/// In place of the composer once the team closed the conversation.
class _ClosedNotice extends StatelessWidget {
  const _ClosedNotice();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.base,
        AppSpacing.gutter,
        AppSpacing.gutter,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_rounded, size: 16, color: AppColors.outline),
          const SizedBox(width: AppSpacing.base),
          Flexible(
            child: Text(
              t.feedback.closedNotice,
              textAlign: TextAlign.center,
              style: AppTextStyles.labelMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSend;

  const _Composer({
    required this.controller,
    required this.enabled,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.base,
        AppSpacing.gutter,
        MediaQuery.viewInsetsOf(context).bottom + AppSpacing.gutter,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              key: const ValueKey('supportChat.input'),
              controller: controller,
              minLines: 1,
              maxLines: 5,
              maxLength: 4000,
              textInputAction: TextInputAction.newline,
              style: AppTextStyles.bodyMd,
              decoration: InputDecoration(
                hintText: t.feedback.replyHint,
                counterText: '',
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.base),
          ClayIconButton(
            key: const ValueKey('supportChat.send'),
            icon: Icons.send_rounded,
            filled: true,
            size: 48,
            onTap: enabled ? onSend : null,
          ),
        ],
      ),
    );
  }
}
