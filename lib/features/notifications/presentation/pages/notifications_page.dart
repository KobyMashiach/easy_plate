import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/services/auth_session_service.dart';
import '../../../../core/services/cook_session_service.dart';
import '../../../../core/services/notifications_service.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/utils/routing/routing.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../../../core/navigation/main_tabs.dart';
import '../../../collab_containers/domain/container_sharing_service.dart';
import '../../../forum/presentation/open_forum_thread.dart';
import '../../../recipe_books/domain/entities/recipe_book_entity.dart';
import '../../../my_recipes/domain/repositories/recipes_repository.dart';
import '../../../my_recipes/presentation/pages/recipe_details_page.dart';
import '../../../my_recipes/presentation/pages/cook_mode_page.dart';
import '../../../my_recipes/presentation/cook_mode_entry.dart';
import '../../../my_recipes/domain/entities/recipe_entity.dart';
import '../../../recipe_sharing/domain/entities/share_invite_entity.dart';
import '../../../recipe_sharing/domain/repositories/recipe_sharing_repository.dart';
import '../../../recipe_sharing/domain/usecases/get_share_invites_usecase.dart';
import '../../../recipe_sharing/domain/usecases/respond_to_share_invite_usecase.dart';
import '../../../shared_recipes/domain/repositories/shared_recipes_repository.dart';
import '../../../shared_recipes/domain/usecases/refresh_saved_copy_usecase.dart';
import '../../domain/entities/app_notification_entity.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../../domain/usecases/mark_notification_read_usecase.dart';
import '../../../../core/widgets/app_dialog.dart';

/// The inbox. The list itself is live through [NotificationsService]; the
/// pending invites are fetched here so a share can be answered in place.
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  /// Invite id → invite, for the ones still awaiting an answer.
  Map<String, ShareInviteEntity> _pending = const {};
  bool _busy = false;

  String get _uid => AuthSessionService().user?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _loadPending();
  }

  Future<void> _loadPending() async {
    try {
      final invites = await GetShareInvitesUseCase(
        context.read<RecipeSharingRepository>(),
      ).incoming(_uid);
      if (mounted) {
        setState(() => _pending = {for (final i in invites) i.id: i});
      }
    } catch (e) {
      debugPrint('Pending invites load failed: $e');
    }
  }

  Future<void> _markRead(AppNotificationEntity item) async {
    if (item.read) return;
    try {
      await MarkNotificationReadUseCase(
        context.read<NotificationsRepository>(),
      )(_uid, item.id);
    } catch (e) {
      debugPrint('Mark read failed: $e');
    }
  }

  Future<void> _respond(
    AppNotificationEntity item,
    ShareInviteEntity invite, {
    required bool accept,
  }) async {
    final useCase = RespondToShareInviteUseCase(
      sharing: context.read<RecipeSharingRepository>(),
      recipes: context.read<RecipesRepository>(),
    );
    final containers = context.read<ContainerSharingService>();
    setState(() => _busy = true);
    try {
      if (accept) {
        switch (invite.kind) {
          case CollabKind.recipe:
            final local = await useCase.accept(invite);
            await _markRead(item);
            if (!mounted) return;
            _toast(t.sharing.accepted);
            context.pushNamed(
              Routing.recipeDetails,
              extra: RecipeDetailsArgs(recipe: local),
            );
          case CollabKind.book:
            final book =
                await containers.accept(invite, uid: _uid) as RecipeBookEntity;
            await _markRead(item);
            if (!mounted) return;
            _toast(t.sharing.acceptedBook);
            context.pushNamed(Routing.bookDetails, extra: book.id);
          case CollabKind.mealPlan:
            await containers.accept(invite, uid: _uid);
            await _markRead(item);
            if (!mounted) return;
            _toast(t.sharing.acceptedPlan);
            // The planner is a tab, not a route: leave the inbox and land
            // on it.
            Navigator.of(context).maybePop();
            MainTabs.index.value = MainTabs.mealPlan;
          case CollabKind.household:
            // Never an invite: a household is joined by code.
            break;
        }
      } else {
        if (invite.kind == CollabKind.recipe) {
          await useCase.decline(invite);
        } else {
          await containers.decline(invite);
        }
        await _markRead(item);
        if (mounted) _toast(t.sharing.declined);
      }
      await _loadPending();
    } catch (e) {
      debugPrint('Invite response failed: $e');
      if (mounted) _fail(t.sharing.acceptFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// The author changed a post this account saved: take the new version
  /// (and show it), or keep the copy as it is.
  Future<void> _refreshCopy(AppNotificationEntity item) async {
    final sharedId = item.sharedId;
    if (sharedId == null) return;
    setState(() => _busy = true);
    try {
      final updated = await RefreshSavedCopyUseCase(
        shared: context.read<SharedRecipesRepository>(),
        recipes: context.read<RecipesRepository>(),
      )(sharedId, viewerUid: _uid);
      await _markRead(item);
      if (!mounted) return;
      if (updated == null) {
        _fail(t.notifications.recipeGone);
        return;
      }
      _toast(t.notifications.refreshed);
      context.pushNamed(
        Routing.recipeDetails,
        extra: RecipeDetailsArgs(recipe: updated),
      );
    } catch (e) {
      debugPrint('Refresh saved copy failed: $e');
      if (mounted) _fail(t.common.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _keepCopy(AppNotificationEntity item) async {
    await _markRead(item);
    if (mounted) _toast(t.notifications.keptCopy);
  }

  Future<void> _delete(AppNotificationEntity item) async {
    try {
      await context.read<NotificationsRepository>().delete(_uid, item.id);
    } catch (e) {
      debugPrint('Delete notification failed: $e');
    }
  }

  Future<void> _deleteAll() async {
    final ok = await AppDialog.warning(
      title: t.notifications.deleteAll,
      message: t.notifications.deleteAllBody,
      confirmLabel: t.common.delete,
      cancelLabel: t.common.cancel,
      destructive: true,
    ).show(context);
    if (ok != true || !mounted) return;
    try {
      await AppDialog.busy(
        context,
        () => context.read<NotificationsRepository>().deleteAll(_uid),
      );
    } catch (e) {
      debugPrint('Delete all notifications failed: $e');
    }
  }

  /// A word in passing, gone on its own.
  void _toast(String message) =>
      AppDialog.success(message: message).notify(context);

  /// Something to read before going on.
  void _fail(String message) => AppDialog.error(message: message).show(context);

  @override
  Widget build(BuildContext context) {
    return ClayScaffold(
      // The timers are listed in the body below; no banner on top as well.
      showCookTimers: false,
      appBar: ClayTopAppBar(
        title: t.notifications.title,
        leadingIcon: Icons.arrow_back_rounded,
        onLeadingTap: () => Navigator.of(context).maybePop(),
        trailingIcon: Icons.delete_sweep_rounded,
        onTrailingTap: _deleteAll,
      ),
      body: ValueListenableBuilder<List<AppNotificationEntity>>(
        valueListenable: NotificationsService().items,
        builder: (context, items, _) => AnimatedBuilder(
          animation: CookSessionService(),
          builder: (context, _) {
            // Cooking in progress is the first thing here, inbox or no
            // inbox: it is the way back into cook mode after leaving it.
            // One card per recipe being cooked.
            final cooking = CookSessionService().sessions;
            return RefreshIndicator(
              onRefresh: _loadPending,
              color: AppColors.primary,
              child: items.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(AppSpacing.marginMobile),
                      children: [
                        for (final s in cooking) ...[
                          _CookSessionCard(session: s),
                          const SizedBox(height: AppSpacing.sm),
                        ],
                        if (cooking.isNotEmpty)
                          const SizedBox(height: AppSpacing.md),
                        ClayEmptyState(
                          icon: Icons.notifications_none_rounded,
                          message: t.notifications.empty,
                        ),
                      ],
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(AppSpacing.marginMobile),
                      // The cooking card when there is one, then the "mark all
                      // read" row, then the items, each swipeable away.
                      itemCount: items.length + 1 + cooking.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        if (index < cooking.length) {
                          return _CookSessionCard(session: cooking[index]);
                        }
                        index -= cooking.length;
                        if (index == 0) {
                          return Row(
                            children: [
                              // The switches for what reaches this inbox, one
                              // tap away from it.
                              TextButton.icon(
                                onPressed: () => context.pushNamed(
                                  Routing.notificationSettings,
                                ),
                                icon: const Icon(Icons.tune_rounded, size: 18),
                                label: Text(t.notifications.settings),
                              ),
                              const Spacer(),
                              TextButton.icon(
                                onPressed: () => MarkNotificationReadUseCase(
                                  context.read<NotificationsRepository>(),
                                ).all(_uid),
                                icon: const Icon(
                                  Icons.done_all_rounded,
                                  size: 18,
                                ),
                                label: Text(t.notifications.markAllRead),
                              ),
                            ],
                          );
                        }
                        final item = items[index - 1];
                        return Dismissible(
                          key: ValueKey(item.id),
                          direction: DismissDirection.endToStart,
                          onDismissed: (_) => _delete(item),
                          background: Container(
                            alignment: AlignmentDirectional.centerEnd,
                            padding: const EdgeInsetsDirectional.only(
                              end: AppSpacing.md,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.errorContainer,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            child: Icon(
                              Icons.delete_rounded,
                              color: AppColors.onErrorContainer,
                            ),
                          ),
                          child: _card(item),
                        );
                      },
                    ),
            );
          },
        ),
      ),
    );
  }

  Widget _card(AppNotificationEntity item) {
    if (item.type == AppNotificationType.sharedRecipeUpdated) {
      return _updatedCard(item);
    }
    if (item.type == AppNotificationType.forumReply) {
      return _forumReplyCard(item);
    }
    if (item.type == AppNotificationType.adminReply ||
        item.type == AppNotificationType.adminMessage) {
      return _adminCard(item);
    }
    final invite = item.inviteId == null ? null : _pending[item.inviteId];
    final roleText = item.role == CollabRole.editor
        ? t.notifications.asEditor
        : t.notifications.asViewer;

    return ClayCard(
      radius: AppRadius.md,
      padding: const EdgeInsets.all(AppSpacing.md),
      color: item.read ? null : AppColors.primaryFixed,
      onTap: () => _markRead(item),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            switch (item.kind) {
              CollabKind.book => t.notifications.sharedBook(
                name: item.fromName ?? '',
                recipe: item.recipeTitle ?? '',
              ),
              CollabKind.mealPlan => t.notifications.sharedPlan(
                name: item.fromName ?? '',
                recipe: item.recipeTitle ?? '',
              ),
              CollabKind.recipe ||
              CollabKind.household => t.notifications.sharedRecipe(
                name: item.fromName ?? '',
                recipe: item.recipeTitle ?? '',
              ),
            },
            style: AppTextStyles.bodyMd,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            roleText,
            style: AppTextStyles.labelSm.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (invite != null)
            Row(
              children: [
                Expanded(
                  child: ClayButton(
                    label: t.sharing.accept,
                    icon: Icons.check_rounded,
                    expanded: true,
                    onPressed: _busy
                        ? null
                        : () => _respond(item, invite, accept: true),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => _respond(item, invite, accept: false),
                  child: Text(
                    t.sharing.decline,
                    style: AppTextStyles.labelMd.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            )
          else
            Text(
              t.notifications.alreadyHandled,
              style: AppTextStyles.labelSm.copyWith(color: AppColors.outline),
            ),
        ],
      ),
    );
  }
}

extension on _NotificationsPageState {
  /// Someone replied in a thread of this account's, or one it joined. A tap
  /// opens the thread on that reply; the row is marked read on the way.
  Widget _forumReplyCard(AppNotificationEntity item) {
    final post = item.postTitle ?? '';
    final name = item.fromName ?? '';
    return ClayCard(
      radius: AppRadius.md,
      padding: const EdgeInsets.all(AppSpacing.md),
      color: item.read ? null : AppColors.primaryFixed,
      onTap: () => _openThread(item),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.forum_rounded, size: 18, color: AppColors.primary),
              const SizedBox(width: AppSpacing.base),
              Expanded(
                child: Text(
                  item.onMyPost
                      ? t.notifications.forumReplyOnMyPost(
                          name: name,
                          post: post,
                        )
                      : t.notifications.forumReplyOnThread(
                          name: name,
                          post: post,
                        ),
                  style: AppTextStyles.bodyMd,
                ),
              ),
            ],
          ),
          if (item.excerpt case final excerpt? when excerpt.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              excerpt,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton.icon(
              onPressed: _busy ? null : () => _openThread(item),
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: Text(t.notifications.openThread),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openThread(AppNotificationEntity item) async {
    final postId = item.postId;
    if (postId == null || postId.isEmpty) return;
    await _markRead(item);
    if (!mounted) return;
    await openForumThread(context, postId: postId, replyId: item.replyId);
  }

  /// A word from the administrator: the answer to a support message (with
  /// the message it answers quoted) or an announcement to everyone.
  Widget _adminCard(AppNotificationEntity item) {
    final isReply = item.type == AppNotificationType.adminReply;
    final title = isReply
        ? t.notifications.adminReply
        : (item.title?.trim().isNotEmpty == true
              ? item.title!.trim()
              : t.notifications.adminMessage);
    return ClayCard(
      radius: AppRadius.md,
      padding: const EdgeInsets.all(AppSpacing.md),
      color: item.read ? null : AppColors.primaryFixed,
      onTap: () => _markRead(item),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isReply ? Icons.support_agent_rounded : Icons.campaign_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.base),
              Expanded(child: Text(title, style: AppTextStyles.bodyMd)),
            ],
          ),
          if (isReply && item.feedbackExcerpt != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              t.notifications.adminReplyQuote(excerpt: item.feedbackExcerpt!),
              style: AppTextStyles.labelSm.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          SelectableText(item.message ?? '', style: AppTextStyles.bodyMd),
        ],
      ),
    );
  }

  Widget _updatedCard(AppNotificationEntity item) {
    return ClayCard(
      radius: AppRadius.md,
      padding: const EdgeInsets.all(AppSpacing.md),
      color: item.read ? null : AppColors.primaryFixed,
      onTap: () => _markRead(item),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.notifications.recipeUpdated(
              name: item.fromName ?? '',
              recipe: item.recipeTitle ?? '',
            ),
            style: AppTextStyles.bodyMd,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            t.notifications.recipeUpdatedHint,
            style: AppTextStyles.labelSm.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          if (!item.read) ...[
            const SizedBox(height: AppSpacing.sm),
            // Stacked, not side by side: the two labels together are wider
            // than a phone card.
            ClayButton(
              label: t.notifications.refreshCopy,
              icon: Icons.sync_rounded,
              expanded: true,
              onPressed: _busy ? null : () => _refreshCopy(item),
            ),
            const SizedBox(height: AppSpacing.xs),
            Center(
              child: TextButton(
                onPressed: _busy ? null : () => _keepCopy(item),
                child: Text(
                  t.notifications.keepCopy,
                  style: AppTextStyles.labelMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// "You are in the middle of cooking": the recipe, the step, every running
/// timer with its bar, and the two ways out — back into cook mode exactly
/// where it was, or ending it for good.
class _CookSessionCard extends StatelessWidget {
  final CookSession session;

  const _CookSessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final service = CookSessionService();
    // The list above rebuilds on every tick of the service; a session that
    // ended between two frames just draws nothing.
    if (service.session(session.id) == null) return const SizedBox.shrink();
    return _body(context, service, session.recipe, session.activeTimers);
  }

  Widget _body(
    BuildContext context,
    CookSessionService service,
    RecipeEntity recipe,
    List<MapEntry<int, CookTimer>> timers,
  ) {
    // The plain light card, not the active (primary-tinted) one: the rows
    // and buttons inside carry the colour, and the clock has to stay legible.
    return ClayCard(
      radius: AppRadius.md,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryFixed,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.local_fire_department_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.cookMode.inProgress, style: AppTextStyles.bodyLg),
                    Text(
                      t.cookMode.inProgressBody(
                        recipe: recipe.title,
                        n: '${session.stepIndex + 1}',
                        total: '${recipe.steps.length}',
                      ),
                      style: AppTextStyles.labelMd.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (timers.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            for (final entry in timers)
              CookTimerRow(step: entry.key + 1, timer: entry.value),
          ],
          const SizedBox(height: AppSpacing.gutter),
          Row(
            children: [
              Expanded(
                child: ClayButton(
                  label: t.cookMode.resumeCooking,
                  icon: Icons.play_arrow_rounded,
                  expanded: true,
                  onPressed: () => openCookMode(context, recipe),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ClayButton(
                  label: t.cookMode.endCooking,
                  icon: Icons.stop_rounded,
                  expanded: true,
                  destructive: true,
                  onPressed: () => service.finish(session.id),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
