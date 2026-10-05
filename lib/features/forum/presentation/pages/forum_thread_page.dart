import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/services/auth_session_service.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../../../core/widgets/error_retry_view.dart';
import '../../../community/presentation/widgets/author_row.dart';
import '../../../community/presentation/widgets/like_button.dart';
import '../../domain/entities/forum_post_entity.dart';
import '../../domain/entities/forum_reply_entity.dart';
import '../../../shared_recipes/domain/entities/shared_recipe_entity.dart';
import '../../../shared_recipes/presentation/widgets/shared_recipe_picker_sheet.dart';
import '../bloc/forum_thread_bloc.dart';
import '../widgets/reply_recipe_link.dart';

/// One thread: the opening post, its replies (live), and the composer.
///
/// [highlightReplyId] is set when a notification brought the reader here:
/// the thread scrolls to that reply and lights it up for a moment.
class ForumThreadPage extends StatefulWidget {
  final ForumPostEntity post;
  final String? highlightReplyId;

  const ForumThreadPage({super.key, required this.post, this.highlightReplyId});

  @override
  State<ForumThreadPage> createState() => _ForumThreadPageState();
}

class _ForumThreadPageState extends State<ForumThreadPage>
    with WidgetsBindingObserver {
  late final ForumThreadBloc _bloc = ForumThreadBloc.fromContext(
    context,
    widget.post,
  );
  final _scroll = ScrollController();

  /// One key per reply the page may need to scroll to: the highlighted one.
  final _highlightKey = GlobalKey();

  /// Still to be scrolled to. Cleared once done, so a later snapshot does
  /// not yank the reader back to it.
  String? _pendingHighlight;

  /// Lit up right now, for the flash after the scroll.
  String? _lit;
  Timer? _litTimer;

  /// How many replies the last state had, to notice the reader's own reply
  /// arriving and follow it down.
  int _replyCount = -1;

  /// Estimate for a reply card, used to jump near a reply that has not been
  /// laid out yet; the exact position is settled once it is on screen.
  static const _estimatedReplyExtent = 150.0;

  String get _uid => AuthSessionService().user?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _pendingHighlight = widget.highlightReplyId;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _litTimer?.cancel();
    _scroll.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _bloc.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _bloc.add(const ForumThreadEvent.setLive(true));
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _bloc.add(const ForumThreadEvent.setLive(false));
      case AppLifecycleState.inactive:
        break;
    }
  }

  void _onLoaded(ForumThreadLoaded state) {
    final replies = state.replies;
    final wasFirst = _replyCount == -1;
    final grew = !wasFirst && replies.length > _replyCount;
    _replyCount = replies.length;

    if (_pendingHighlight case final id?) {
      final index = replies.indexWhere((r) => r.id == id);
      if (index != -1) {
        _pendingHighlight = null;
        _scrollToReply(index, id);
        return;
      }
    }
    // The reader's own reply just landed: follow it to the bottom, as any
    // chat does. Someone else's is left where it is so the page does not
    // jump under a reader mid-thread.
    if (grew && replies.last.authorUid == _uid) _scrollToEnd();
  }

  Future<void> _scrollToReply(int index, String id) async {
    // First pass: land close enough that the sliver builds the card.
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted || !_scroll.hasClients) return;
    final rough = (index * _estimatedReplyExtent).clamp(
      0.0,
      _scroll.position.maxScrollExtent,
    );
    _scroll.jumpTo(rough);
    // Second pass: the card exists now; line it up exactly.
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    final target = _highlightKey.currentContext;
    if (target != null && target.mounted) {
      await Scrollable.ensureVisible(
        target,
        alignment: 0.15,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
    if (!mounted) return;
    setState(() => _lit = id);
    _litTimer?.cancel();
    _litTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _lit = null);
    });
  }

  Future<void> _scrollToEnd() async {
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted || !_scroll.hasClients) return;
    await _scroll.animateTo(
      _scroll.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: ClayScaffold(
        appBar: ClayTopAppBar(
          title: t.community.forum,
          leadingIcon: Icons.arrow_back_rounded,
          onLeadingTap: () => Navigator.of(context).maybePop(),
        ),
        body: SafeArea(
          child: BlocConsumer<ForumThreadBloc, ForumThreadState>(
            listener: (context, state) {
              if (state is ForumThreadLoaded) _onLoaded(state);
            },
            // The composer has its own selector; the thread body only cares
            // about the post and the replies.
            buildWhen: (previous, current) => switch ((previous, current)) {
              (
                ForumThreadLoaded(post: final p1, replies: final r1),
                ForumThreadLoaded(post: final p2, replies: final r2),
              ) =>
                p1 != p2 || r1 != r2,
              _ => true,
            },
            builder: (context, state) {
              return switch (state) {
                ForumThreadLoading() => const Center(
                  child: CircularProgressIndicator(),
                ),
                ForumThreadLoaded(post: final post, replies: final replies) =>
                  Column(
                    children: [
                      Expanded(
                        child: _Thread(
                          post: post,
                          replies: replies,
                          controller: _scroll,
                          highlightKey: _highlightKey,
                          highlightId: widget.highlightReplyId,
                          litId: _lit,
                        ),
                      ),
                      const _ReplyComposer(),
                    ],
                  ),
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

class _Thread extends StatelessWidget {
  final ForumPostEntity post;
  final List<ForumReplyEntity> replies;
  final ScrollController controller;
  final GlobalKey highlightKey;
  final String? highlightId;
  final String? litId;

  const _Thread({
    required this.post,
    required this.replies,
    required this.controller,
    required this.highlightKey,
    required this.highlightId,
    required this.litId,
  });

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ForumThreadBloc>();

    return RefreshIndicator(
      onRefresh: () {
        final done = Completer<void>();
        bloc.add(ForumThreadEvent.refresh(done));
        return done.future;
      },
      color: AppColors.primary,
      child: CustomScrollView(
        controller: controller,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.marginMobile,
              AppSpacing.marginMobile,
              AppSpacing.marginMobile,
              AppSpacing.lg,
            ),
            sliver: SliverToBoxAdapter(
              child: ClayCard(
                radius: AppRadius.md,
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AuthorRow(
                      name: post.authorName,
                      photoUrl: post.authorPhotoUrl,
                      createdAt: post.createdAt,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(post.title, style: AppTextStyles.headlineMd),
                    const SizedBox(height: AppSpacing.xs),
                    Text(post.body, style: AppTextStyles.bodyMd),
                    const SizedBox(height: AppSpacing.sm),
                    LikeButton(
                      liked: post.likedByMe,
                      count: post.likeCount,
                      onPressed: () =>
                          bloc.add(const ForumThreadEvent.togglePostLike()),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (replies.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Text(
                  t.community.noReplies,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.labelMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.marginMobile,
                0,
                AppSpacing.marginMobile,
                AppSpacing.marginMobile,
              ),
              // Lazy: a long thread builds only the replies on screen.
              sliver: SliverList.separated(
                itemCount: replies.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final reply = replies[index];
                  return RepaintBoundary(
                    key: reply.id == highlightId
                        ? highlightKey
                        : ValueKey(reply.id),
                    child: _ReplyCard(
                      reply: reply,
                      lit: reply.id == litId,
                      onLike: () => bloc.add(
                        ForumThreadEvent.toggleReplyLike(reply.id),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _ReplyCard extends StatelessWidget {
  final ForumReplyEntity reply;
  final bool lit;
  final VoidCallback onLike;

  const _ReplyCard({
    required this.reply,
    required this.lit,
    required this.onLike,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      // Drawn ahead of the server's answer: faded a touch until it lands.
      opacity: reply.pending ? 0.6 : 1,
      duration: const Duration(milliseconds: 200),
      child: ClayCard(
        radius: AppRadius.md,
        padding: const EdgeInsets.all(AppSpacing.md),
        color: lit ? AppColors.primaryFixed : null,
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
            const SizedBox(height: AppSpacing.xs),
            LikeButton(
              liked: reply.likedByMe,
              count: reply.likeCount,
              onPressed: reply.pending ? null : onLike,
            ),
          ],
        ),
      ),
    );
  }
}

/// The box at the bottom. Its own widget with its own state, so typing
/// rebuilds this row and not the thread above it.
class _ReplyComposer extends StatefulWidget {
  const _ReplyComposer();

  @override
  State<_ReplyComposer> createState() => _ReplyComposerState();
}

class _ReplyComposerState extends State<_ReplyComposer> {
  final _reply = TextEditingController();

  /// Recipe attached to the reply being written, if any.
  SharedRecipeEntity? _attached;

  /// Mirrors the text field so the send button can disable itself; the guard
  /// in [_send] alone made an empty tap look like a dead button.
  bool _hasText = false;

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
    return BlocConsumer<ForumThreadBloc, ForumThreadState>(
      listenWhen: (previous, current) =>
          current is ForumThreadLoaded &&
          current.sendError != null &&
          (previous is! ForumThreadLoaded ||
              previous.sendError != current.sendError),
      listener: (context, state) {
        AppDialog.error(message: t.community.replyFailed).show(context);
      },
      buildWhen: (previous, current) => switch ((previous, current)) {
        (
          ForumThreadLoaded(sending: final s1),
          ForumThreadLoaded(sending: final s2),
        ) =>
          s1 != s2,
        _ => true,
      },
      builder: (context, state) {
        final sending = state is ForumThreadLoaded && state.sending;
        final canSend = !sending && (_hasText || _attached != null);

        return Padding(
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
                      icon: Icon(
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
                    icon: Icon(
                      Icons.attach_file_rounded,
                      color: AppColors.primary,
                    ),
                    onPressed: sending ? null : _attachRecipe,
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
                    icon: sending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            Icons.send_rounded,
                            color: AppColors.primary,
                          ),
                    onPressed: canSend ? _send : null,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
