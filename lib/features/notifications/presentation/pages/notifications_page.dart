import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/services/auth_session_service.dart';
import '../../../../core/services/notifications_service.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/utils/routing/routing.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../../../core/widgets/refreshable_empty_state.dart';
import '../../../my_recipes/domain/repositories/recipes_repository.dart';
import '../../../my_recipes/presentation/pages/recipe_details_page.dart';
import '../../../recipe_sharing/domain/entities/share_invite_entity.dart';
import '../../../recipe_sharing/domain/repositories/recipe_sharing_repository.dart';
import '../../../recipe_sharing/domain/usecases/get_share_invites_usecase.dart';
import '../../../recipe_sharing/domain/usecases/respond_to_share_invite_usecase.dart';
import '../../domain/entities/app_notification_entity.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../../domain/usecases/mark_notification_read_usecase.dart';

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
      final invites =
          await GetShareInvitesUseCase(context.read<RecipeSharingRepository>()).incoming(_uid);
      if (mounted) setState(() => _pending = {for (final i in invites) i.id: i});
    } catch (e) {
      debugPrint('Pending invites load failed: $e');
    }
  }

  Future<void> _markRead(AppNotificationEntity item) async {
    if (item.read) return;
    try {
      await MarkNotificationReadUseCase(context.read<NotificationsRepository>())(_uid, item.id);
    } catch (e) {
      debugPrint('Mark read failed: $e');
    }
  }

  Future<void> _respond(AppNotificationEntity item, ShareInviteEntity invite,
      {required bool accept}) async {
    final useCase = RespondToShareInviteUseCase(
      sharing: context.read<RecipeSharingRepository>(),
      recipes: context.read<RecipesRepository>(),
    );
    setState(() => _busy = true);
    try {
      if (accept) {
        final local = await useCase.accept(invite);
        await _markRead(item);
        if (!mounted) return;
        _toast(t.sharing.accepted);
        context.pushNamed(Routing.recipeDetails, extra: RecipeDetailsArgs(recipe: local));
      } else {
        await useCase.decline(invite);
        await _markRead(item);
        if (mounted) _toast(t.sharing.declined);
      }
      await _loadPending();
    } catch (e) {
      debugPrint('Invite response failed: $e');
      if (mounted) _toast(t.sharing.acceptFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String message) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message, style: AppTextStyles.bodyMd)),
      );

  @override
  Widget build(BuildContext context) {
    return ClayScaffold(
      appBar: ClayTopAppBar(
        title: t.notifications.title,
        leadingIcon: Icons.arrow_back_rounded,
        onLeadingTap: () => Navigator.of(context).maybePop(),
        trailingIcon: Icons.done_all_rounded,
        onTrailingTap: () =>
            MarkNotificationReadUseCase(context.read<NotificationsRepository>()).all(_uid),
      ),
      body: ValueListenableBuilder<List<AppNotificationEntity>>(
        valueListenable: NotificationsService().items,
        builder: (context, items, _) => RefreshIndicator(
          onRefresh: _loadPending,
          color: AppColors.primary,
          child: items.isEmpty
              ? RefreshableEmptyState(
                  child: ClayEmptyState(
                    icon: Icons.notifications_none_rounded,
                    message: t.notifications.empty,
                  ),
                )
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppSpacing.marginMobile),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) => _card(items[index]),
                ),
        ),
      ),
    );
  }

  Widget _card(AppNotificationEntity item) {
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
            t.notifications.sharedRecipe(
              name: item.fromName ?? '',
              recipe: item.recipeTitle ?? '',
            ),
            style: AppTextStyles.bodyMd,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(roleText, style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant)),
          const SizedBox(height: AppSpacing.sm),
          if (invite != null)
            Row(
              children: [
                Expanded(
                  child: ClayButton(
                    label: t.sharing.accept,
                    icon: Icons.check_rounded,
                    expanded: true,
                    onPressed: _busy ? null : () => _respond(item, invite, accept: true),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                TextButton(
                  onPressed: _busy ? null : () => _respond(item, invite, accept: false),
                  child: Text(
                    t.sharing.decline,
                    style: AppTextStyles.labelMd.copyWith(color: AppColors.error),
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
