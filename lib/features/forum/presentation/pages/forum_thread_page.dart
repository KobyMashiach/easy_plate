import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../../../core/widgets/error_retry_view.dart';
import '../../../community/presentation/widgets/author_row.dart';
import '../../domain/entities/forum_post_entity.dart';
import '../../domain/entities/forum_reply_entity.dart';
import '../../../shared_recipes/domain/entities/shared_recipe_entity.dart';
import '../../../shared_recipes/presentation/widgets/shared_recipe_picker_sheet.dart';
import '../bloc/forum_thread_bloc.dart';
import '../widgets/reply_recipe_link.dart';

class ForumThreadPage extends StatelessWidget {
  final ForumPostEntity post;

  const ForumThreadPage({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ForumThreadBloc.fromContext(context, post.id),
      child: ClayScaffold(
        appBar: ClayTopAppBar(
          title: t.community.forum,
          leadingIcon: Icons.arrow_back_rounded,
          onLeadingTap: () => Navigator.of(context).maybePop(),
        ),
        body: SafeArea(
          child: BlocBuilder<ForumThreadBloc, ForumThreadState>(
            builder: (context, state) {
              return switch (state) {
                ForumThreadLoading() => const Center(
                  child: CircularProgressIndicator(),
                ),
                ForumThreadLoaded(
                  replies: final replies,
                  sending: final sending,
                ) =>
                  _Thread(post: post, replies: replies, sending: sending),
                ForumThreadError(error: final error) => ErrorRetryView(
                  error: error,
                  onRetry: () => context.read<ForumThreadBloc>().add(
                    const ForumThreadEvent.init(),
                  ),
                ),
              };
            },
          ),
        ),
      ),
    );
  }
}

class _Thread extends StatefulWidget {
  final ForumPostEntity post;
  final List<ForumReplyEntity> replies;
  final bool sending;

  const _Thread({
    required this.post,
    required this.replies,
    required this.sending,
  });

  @override
  State<_Thread> createState() => _ThreadState();
}

class _ThreadState extends State<_Thread> {
  final _reply = TextEditingController();

  /// Recipe attached to the reply being written, if any.
  SharedRecipeEntity? _attached;

  /// Mirrors the text field so the send button can disable itself; the guard
  /// in [_send] alone made an empty tap look like a dead button.
  bool _hasText = false;

  bool get _canSend => !widget.sending && (_hasText || _attached != null);

  @override
  void initState() {
    super.initState();
    _reply.addListener(_syncHasText);
  }

  void _syncHasText() {
    final hasText = _reply.text.trim().isNotEmpty;
    if (hasText != _hasText) setState(() => _hasText = hasText);
  }

  @override
  void dispose() {
    _reply.removeListener(_syncHasText);
    _reply.dispose();
    super.dispose();
  }

  Future<void> _attachRecipe() async {
    final shared = await showSharedRecipePickerSheet(context);
    if (shared != null && mounted) setState(() => _attached = shared);
  }

  void _send() {
    final body = _reply.text.trim();
    // A recipe link is a complete reply on its own — the title carries it.
    if (body.isEmpty && _attached == null) return;

    context.read<ForumThreadBloc>().add(
      ForumThreadEvent.addReply(
        body,
        sharedRecipeId: _attached?.id,
        sharedRecipeTitle: _attached?.recipe.title,
      ),
    );
    _reply.clear();
    setState(() => _attached = null);
    // Dismiss so the freshly posted reply is visible instead of hidden behind
    // the keyboard.
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: () {
              final done = Completer<void>();
              context.read<ForumThreadBloc>().add(
                ForumThreadEvent.refresh(done),
              );
              return done.future;
            },
            color: AppColors.primary,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.marginMobile),
              children: [
                ClayCard(
                  radius: AppRadius.md,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AuthorRow(
                        name: widget.post.authorName,
                        photoUrl: widget.post.authorPhotoUrl,
                        createdAt: widget.post.createdAt,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(widget.post.title, style: AppTextStyles.headlineMd),
                      const SizedBox(height: AppSpacing.xs),
                      Text(widget.post.body, style: AppTextStyles.bodyMd),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (widget.replies.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                    child: Text(
                      t.community.noReplies,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.labelMd.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  )
                else
                  for (final reply in widget.replies) ...[
                    ClayCard(
                      radius: AppRadius.md,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AuthorRow(
                            name: reply.authorName,
                            photoUrl: reply.authorPhotoUrl,
                            createdAt: reply.createdAt,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          if (reply.body.isNotEmpty)
                            Text(reply.body, style: AppTextStyles.bodyMd),
                          if (reply.hasRecipe) ...[
                            const SizedBox(height: AppSpacing.sm),
                            Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: ReplyRecipeLink(
                                sharedRecipeId: reply.sharedRecipeId!,
                                title: reply.sharedRecipeTitle,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.marginMobile,
            right: AppSpacing.marginMobile,
            bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.sm,
            top: AppSpacing.sm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_attached case final attached?) ...[
                Row(
                  children: [
                    Flexible(
                      child: ReplyRecipeLink(
                        sharedRecipeId: attached.id,
                        title: attached.recipe.title,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: AppColors.tertiary,
                      ),
                      onPressed: () => setState(() => _attached = null),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
              ],
              Row(
                children: [
                  IconButton(
                    tooltip: t.community.attachRecipe,
                    icon: const Icon(
                      Icons.attach_file_rounded,
                      color: AppColors.primary,
                    ),
                    onPressed: widget.sending ? null : _attachRecipe,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _reply,
                      maxLines: 3,
                      minLines: 1,
                      style: AppTextStyles.bodyMd,
                      decoration: InputDecoration(
                        hintText: t.community.writeReply,
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  IconButton(
                    tooltip: t.community.send,
                    icon: widget.sending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(
                            Icons.send_rounded,
                            color: AppColors.primary,
                          ),
                    onPressed: _canSend ? _send : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
