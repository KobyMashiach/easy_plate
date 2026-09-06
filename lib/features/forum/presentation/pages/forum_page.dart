import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/services/auth_session_service.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/utils/routing/routing.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../../../core/widgets/error_retry_view.dart';
import '../../../../core/widgets/refreshable_empty_state.dart';
import '../../../community/presentation/widgets/author_row.dart';
import '../../domain/entities/forum_post_entity.dart';
import '../bloc/forum_bloc.dart';

class ForumPage extends StatelessWidget {
  const ForumPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ForumBloc.fromContext(context),
      child: Builder(
        builder: (context) => Stack(
          children: [
            BlocBuilder<ForumBloc, ForumState>(
              builder: (context, state) {
                return switch (state) {
                  ForumLoading() => const Center(child: CircularProgressIndicator()),
                  ForumLoaded(posts: final posts) => _PostList(posts: posts),
                  ForumError(error: final error) => ErrorRetryView(
                      error: error,
                      onRetry: () => context.read<ForumBloc>().add(const ForumEvent.init()),
                    ),
                };
              },
            ),
            PositionedDirectional(
              end: AppSpacing.marginMobile,
              bottom: ClayNavDock.reservedHeight,
              child: FloatingActionButton(
                heroTag: 'forum-new-post',
                backgroundColor: AppColors.primary,
                onPressed: () => _openComposer(context),
                child: const Icon(Icons.edit_rounded, color: AppColors.onPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _openComposer(BuildContext context) async {
  final bloc = context.read<ForumBloc>();
  final result = await showModalBottomSheet<({String title, String body})>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceContainerLowest,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.md)),
    ),
    builder: (_) => const _PostComposer(),
  );
  if (result != null) bloc.add(ForumEvent.createPost(result.title, result.body));
}

/// Dispatches a reload and hands the indicator a future that completes when the
/// bloc is actually done with it.
Future<void> refreshForum(BuildContext context) {
  final done = Completer<void>();
  context.read<ForumBloc>().add(ForumEvent.refresh(done));
  return done.future;
}

class _PostList extends StatelessWidget {
  final List<ForumPostEntity> posts;

  const _PostList({required this.posts});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => refreshForum(context),
      color: AppColors.primary,
      child: posts.isEmpty
          ? RefreshableEmptyState(
              child: ClayEmptyState(icon: Icons.forum_rounded, message: t.community.noPosts),
            )
          : ListView.separated(
              // Always scrollable so a list too short to overflow can still be
              // pulled.
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.marginMobile,
                0,
                AppSpacing.marginMobile,
                ClayNavDock.reservedHeight,
              ),
              itemCount: posts.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) => _PostCard(post: posts[index]),
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.community.deletePost, style: AppTextStyles.headlineMd),
        content: Text(t.community.deletePostConfirm, style: AppTextStyles.bodyMd),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(t.common.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              t.common.delete,
              style: AppTextStyles.labelMd.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed ?? false) bloc.add(ForumEvent.deletePost(post.id));
  }

  @override
  Widget build(BuildContext context) {
    final isMine = AuthSessionService().user?.uid == post.authorUid;

    return ClayCard(
      radius: AppRadius.md,
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: () => context.pushNamed(Routing.forumThread, extra: post),
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
                    icon: const Icon(Icons.delete_outline_rounded,
                        size: 20, color: AppColors.error),
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
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Icon(Icons.mode_comment_outlined, size: 16, color: AppColors.tertiary),
              const SizedBox(width: AppSpacing.xs),
              Text(
                _replyLabel,
                style: AppTextStyles.labelSm.copyWith(color: AppColors.tertiary),
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
