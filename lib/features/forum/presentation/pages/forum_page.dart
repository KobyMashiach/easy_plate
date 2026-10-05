import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/ads/feed_ad_layout.dart';
import '../../../../core/ads/feed_ad_pool.dart';
import '../../../../core/ads/native_ad_card.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/monetization/entitlement_service.dart';
import '../../../../core/monetization/monetization_config.dart';
import '../../../../core/services/auth_session_service.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/utils/routing/routing.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../../../core/widgets/error_retry_view.dart';
import '../../../../core/widgets/refreshable_empty_state.dart';
import '../../../community/presentation/widgets/author_row.dart';
import '../../../community/presentation/widgets/like_button.dart';
import '../../domain/entities/forum_post_entity.dart';
import '../bloc/forum_bloc.dart';
import '../../../../core/widgets/app_dialog.dart';

/// The forum tab. Live: the bloc holds a Firestore listener on the thread
/// window, so a reply or a new thread from anyone shows without a pull.
class ForumPage extends StatefulWidget {
  const ForumPage({super.key});

  @override
  State<ForumPage> createState() => _ForumPageState();
}

class _ForumPageState extends State<ForumPage> with WidgetsBindingObserver {
  late final ForumBloc _bloc = ForumBloc.fromContext(context);

  /// Owned here rather than by the list so it outlives a switch between the
  /// loaded, empty and error views and keeps the reader's place.
  final _scroll = ScrollController();

  /// Within this many pixels of the top the list counts as "at the top": new
  /// threads join it directly instead of waiting on the pill.
  static const _topSlack = 24.0;

  bool _atTop = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _bloc.close();
    super.dispose();
  }

  /// The listener is closed while the app is in the background: nothing is
  /// looking, and a phone in a pocket should not hold a socket open for it.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _bloc.add(const ForumEvent.setLive(true));
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _bloc.add(const ForumEvent.setLive(false));
      case AppLifecycleState.inactive:
        break;
    }
  }

  void _onScroll() {
    final atTop = !_scroll.hasClients || _scroll.offset <= _topSlack;
    if (atTop == _atTop) return;
    _atTop = atTop;
    _bloc.add(ForumEvent.viewportAtTop(atTop));
  }

  Future<void> _showIncoming() async {
    _bloc.add(const ForumEvent.revealIncoming());
    await scrollToTop();
  }

  Future<void> scrollToTop() async {
    if (!_scroll.hasClients) return;
    await _scroll.animateTo(
      0,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: Stack(
        children: [
          BlocBuilder<ForumBloc, ForumState>(
            builder: (context, state) {
              return switch (state) {
                ForumLoading() => const Center(
                  child: CircularProgressIndicator(),
                ),
                ForumLoaded(posts: final posts) => _PostList(
                  posts: posts,
                  controller: _scroll,
                ),
                ForumError(error: final error) => ErrorRetryView(
                  error: error,
                  onRetry: () =>
                      context.read<ForumBloc>().add(const ForumEvent.init()),
                ),
              };
            },
          ),
          // Threads that arrived while the reader was further down. Selected
          // narrowly so a like or a reply count elsewhere does not touch it.
          Positioned(
            top: AppSpacing.sm,
            left: 0,
            right: 0,
            child: Center(
              child: BlocSelector<ForumBloc, ForumState, int>(
                selector: (state) => switch (state) {
                  ForumLoaded(incoming: final incoming) => incoming.length,
                  _ => 0,
                },
                builder: (context, count) => _IncomingPill(
                  count: count,
                  onTap: _showIncoming,
                ),
              ),
            ),
          ),
          PositionedDirectional(
            end: AppSpacing.marginMobile,
            bottom: ClayNavDock.bottomPadding(context),
            child: FloatingActionButton(
              heroTag: 'forum-new-post',
              backgroundColor: AppColors.primary,
              onPressed: () => _openComposer(context),
              child: Icon(Icons.edit_rounded, color: AppColors.onPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openComposer(BuildContext context) async {
    final result = await showModalBottomSheet<({String title, String body})>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.md)),
      ),
      builder: (_) => const _PostComposer(),
    );
    if (result == null || !context.mounted) return;
    await AppDialog.busyEvent(
      context,
      _bloc,
      ForumEvent.createPost(result.title, result.body),
    );
    // The new thread is at the top; take the author there.
    if (mounted) await scrollToTop();
  }
}

/// Dispatches a reload and hands the indicator a future that completes when the
/// bloc is actually done with it.
Future<void> refreshForum(BuildContext context) {
  final done = Completer<void>();
  context.read<ForumBloc>().add(ForumEvent.refresh(done));
  return done.future;
}

/// "N new posts", slid in over the list when there is something to show.
class _IncomingPill extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _IncomingPill({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.5),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: count == 0
          ? const SizedBox.shrink()
          : Material(
              key: const ValueKey('forum-incoming'),
              color: AppColors.primary,
              shape: const StadiumBorder(),
              elevation: 4,
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.gutter,
                    vertical: AppSpacing.base,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.arrow_upward_rounded,
                        size: 16,
                        color: AppColors.onPrimary,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        count == 1
                            ? t.community.oneNewPost
                            : t.community.newPosts(count: count),
                        style: AppTextStyles.labelMd.copyWith(
                          color: AppColors.onPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

class _PostList extends StatefulWidget {
  final List<ForumPostEntity> posts;
  final ScrollController controller;

  const _PostList({required this.posts, required this.controller});

  @override
  State<_PostList> createState() => _PostListState();
}

class _PostListState extends State<_PostList> {
  /// Kept across rebuilds so a new reply count does not re-request the ads.
  final _ads = FeedAdPool();

  late final Listenable _adSources = Listenable.merge([
    EntitlementService(),
    FirebaseService().configRevision,
  ]);

  @override
  void dispose() {
    _ads.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final posts = widget.posts;

    return RefreshIndicator(
      onRefresh: () => refreshForum(context),
      color: AppColors.primary,
      child: posts.isEmpty
          ? RefreshableEmptyState(
              child: ClayEmptyState(
                icon: Icons.forum_rounded,
                message: t.community.noPosts,
              ),
            )
          : ListenableBuilder(
              listenable: _adSources,
              builder: (context, _) {
                // A native card after every few posts, for accounts that see
                // ads at all.
                final layout = FeedAdLayout(
                  itemCount: posts.length,
                  interval: MonetizationConfig.adFree
                      ? 0
                      : MonetizationConfig.feedAdInterval,
                );
                return ListView.separated(
                  controller: widget.controller,
                  // Always scrollable so a list too short to overflow can
                  // still be pulled.
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.marginMobile,
                    0,
                    AppSpacing.marginMobile,
                    ClayNavDock.bottomPadding(context, withFab: true),
                  ),
                  itemCount: layout.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, position) =>
                      switch (layout.slotAt(position)) {
                        // Keyed by thread so a row that moves keeps its
                        // element — and its ink state — rather than being
                        // rebuilt as a different thread's card.
                        ContentSlot(index: final index) => RepaintBoundary(
                          key: ValueKey(posts[index].id),
                          child: _PostCard(post: posts[index]),
                        ),
                        AdSlot(adIndex: final adIndex) => switch (_ads.slot(
                          adIndex,
                        )) {
                          final slot? => NativeAdCard(slot: slot),
                          null => const SizedBox.shrink(),
                        },
                      },
                );
              },
            ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final ForumPostEntity post;

  const _PostCard({required this.post});

  String get _replyLabel => switch (post.replyCount) {
    0 => t.community.noReplies,
    1 => t.community.oneReply,
    _ => t.community.replies(count: post.replyCount),
  };

  Future<void> _confirmDelete(BuildContext context) async {
    final bloc = context.read<ForumBloc>();
    final confirmed = await AppDialog.warning(
      title: t.community.deletePost,
      message: t.community.deletePostConfirm,
      icon: Icons.delete_outline_rounded,
      confirmLabel: t.common.delete,
      cancelLabel: t.common.cancel,
      destructive: true,
    ).show(context);
    if (!(confirmed ?? false) || !context.mounted) return;
    await AppDialog.busyEvent(context, bloc, ForumEvent.deletePost(post.id));
  }

  /// The row is live, so likes and replies given inside the thread reach it
  /// on their own; nothing to reload on return.
  void _open(BuildContext context) =>
      context.pushNamed(Routing.forumThread, extra: post);

  @override
  Widget build(BuildContext context) {
    final isMine = AuthSessionService().user?.uid == post.authorUid;
    final bloc = context.read<ForumBloc>();

    return ClayCard(
      radius: AppRadius.md,
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: () => _open(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AuthorRow(
            name: post.authorName,
            photoUrl: post.authorPhotoUrl,
            createdAt: post.createdAt,
            trailing: isMine
                ? IconButton(
                    tooltip: t.community.deletePost,
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      size: 20,
                      color: AppColors.error,
                    ),
                    onPressed: () => _confirmDelete(context),
                  )
                : null,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(post.title, style: AppTextStyles.bodyLg),
          const SizedBox(height: AppSpacing.xs),
          Text(
            post.body,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              LikeButton(
                liked: post.likedByMe,
                count: post.likeCount,
                onPressed: () => bloc.add(ForumEvent.toggleLike(post.id)),
              ),
              const SizedBox(width: AppSpacing.md),
              Icon(
                Icons.mode_comment_outlined,
                size: 16,
                color: AppColors.tertiary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                _replyLabel,
                style: AppTextStyles.labelSm.copyWith(
                  color: AppColors.tertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PostComposer extends StatefulWidget {
  const _PostComposer();

  @override
  State<_PostComposer> createState() => _PostComposerState();
}

class _PostComposerState extends State<_PostComposer> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _title.text.trim();
    final body = _body.text.trim();
    if (title.isEmpty) {
      setState(() => _error = t.community.postTitleRequired);
      return;
    }
    if (body.isEmpty) {
      setState(() => _error = t.community.postBodyRequired);
      return;
    }
    Navigator.of(context).pop((title: title, body: body));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.md,
          right: AppSpacing.md,
          top: AppSpacing.md,
          bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClaySectionHeader(title: t.community.newPost, underline: true),
            const SizedBox(height: AppSpacing.gutter),
            TextField(
              controller: _title,
              textInputAction: TextInputAction.next,
              style: AppTextStyles.bodyMd,
              decoration: InputDecoration(labelText: t.community.postTitle),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _body,
              maxLines: 5,
              style: AppTextStyles.bodyMd,
              decoration: InputDecoration(
                hintText: t.community.postBody,
                errorText: _error,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ClayButton(
              label: t.community.publish,
              icon: Icons.send_rounded,
              expanded: true,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
