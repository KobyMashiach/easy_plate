import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/services/auth_session_service.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/utils/routing/routing.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../../../core/widgets/error_retry_view.dart';
import '../../../../core/navigation/main_tabs.dart';
import '../../../collab_containers/domain/container_sharing_service.dart';
import '../../../collab_containers/domain/entities/collab_container_entity.dart';
import '../../../my_recipes/domain/repositories/recipes_repository.dart';
import '../../../recipe_books/domain/entities/recipe_book_entity.dart';
import '../../../my_recipes/presentation/pages/recipe_details_page.dart';
import '../../../recipe_sharing/domain/entities/collab_recipe_entity.dart';
import '../../../recipe_sharing/domain/entities/share_invite_entity.dart';
import '../../../recipe_sharing/domain/repositories/recipe_sharing_repository.dart';
import '../../../recipe_sharing/domain/usecases/get_my_collabs_usecase.dart';
import '../../../recipe_sharing/domain/usecases/get_share_invites_usecase.dart';
import '../../../recipe_sharing/domain/usecases/remove_collab_member_usecase.dart';
import '../../../recipe_sharing/domain/usecases/respond_to_share_invite_usecase.dart';
import '../../../settings/presentation/bloc/settings_bloc.dart';
import '../../../user_profile/domain/entities/public_profile_entity.dart';
import '../../../user_profile/domain/repositories/user_profile_repository.dart';
import '../../../../core/widgets/app_dialog.dart';

/// Everything this account shares or is shared: pending invites to answer,
/// recipes it owns with their members, recipes it was let into, and the
/// book/list counts that were here before. Reached from the account menu.
class SharingManagementPage extends StatefulWidget {
  const SharingManagementPage({super.key});

  @override
  State<SharingManagementPage> createState() => _SharingManagementPageState();
}

class _SharingManagementPageState extends State<SharingManagementPage> {
  List<ShareInviteEntity> _pending = const [];
  List<CollabRecipeEntity> _owned = const [];
  List<CollabRecipeEntity> _sharedWithMe = const [];
  List<CollabContainerEntity> _ownedContainers = const [];
  List<CollabContainerEntity> _containersWithMe = const [];
  Map<String, PublicProfileEntity> _people = const {};
  bool _loading = true;
  bool _busy = false;

  String get _uid => AuthSessionService().user?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final sharing = context.read<RecipeSharingRepository>();
    final containers = context.read<ContainerSharingService>();
    final profiles = context.read<UserProfileRepository>();
    try {
      final invites = GetShareInvitesUseCase(sharing);
      final collabs = GetMyCollabsUseCase(sharing);
      final results = await Future.wait<Object>([
        invites.incoming(_uid),
        collabs.owned(_uid),
        collabs.sharedWithMe(_uid),
        containers.ownedBy(_uid),
        containers.sharedWith(_uid),
      ]);
      final pending = results[0] as List<ShareInviteEntity>;
      final owned = results[1] as List<CollabRecipeEntity>;
      final shared = results[2] as List<CollabRecipeEntity>;
      final ownedContainers = results[3] as List<CollabContainerEntity>;
      final containersWithMe = results[4] as List<CollabContainerEntity>;

      // One name lookup for everyone on the page: inviters, members, owners.
      final uids = <String>{
        ...pending.map((i) => i.ownerUid),
        for (final c in owned) ...c.members.keys,
        for (final c in ownedContainers) ...c.members.keys,
        ...shared.map((c) => c.ownerUid),
        ...containersWithMe.map((c) => c.ownerUid),
      };
      final people = await profiles.getPublicProfiles(uids);

      if (!mounted) return;
      setState(() {
        _pending = pending;
        _owned = owned;
        _sharedWithMe = shared;
        _ownedContainers = ownedContainers;
        _containersWithMe = containersWithMe;
        _people = people;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Sharing page load failed: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  String _nameOf(String uid) => _people[uid]?.fullName ?? '';

  Future<void> _respond(
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
            if (!mounted) return;
            _toast(t.sharing.accepted);
            context.pushNamed(
              Routing.recipeDetails,
              extra: RecipeDetailsArgs(recipe: local),
            );
          case CollabKind.book:
            final book =
                await containers.accept(invite, uid: _uid) as RecipeBookEntity;
            if (!mounted) return;
            _toast(t.sharing.acceptedBook);
            context.pushNamed(Routing.bookDetails, extra: book.id);
          case CollabKind.mealPlan:
            await containers.accept(invite, uid: _uid);
            if (!mounted) return;
            _toast(t.sharing.acceptedPlan);
            Navigator.of(context).maybePop();
            MainTabs.index.value = MainTabs.mealPlan;
        }
      } else {
        if (invite.kind == CollabKind.recipe) {
          await useCase.decline(invite);
        } else {
          await containers.decline(invite);
        }
        if (mounted) _toast(t.sharing.declined);
      }
      await _load();
    } catch (e) {
      debugPrint('Invite response failed: $e');
      if (mounted) _fail(t.sharing.acceptFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _removeMember(
    CollabRecipeEntity collab,
    String memberUid, {
    required bool leaving,
  }) async {
    final useCase = RemoveCollabMemberUseCase(
      context.read<RecipeSharingRepository>(),
    );
    setState(() => _busy = true);
    try {
      await useCase(collab.id, memberUid);
      if (mounted) _toast(leaving ? t.sharing.left : t.sharing.removed);
      await _load();
    } catch (e) {
      debugPrint('Member removal failed: $e');
      if (mounted) _fail(t.sharing.failed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _removeContainerMember(
    CollabContainerEntity container,
    String memberUid, {
    required bool leaving,
  }) async {
    final service = context.read<ContainerSharingService>();
    setState(() => _busy = true);
    try {
      await service.removeMember(container.id, memberUid);
      if (mounted) _toast(leaving ? t.sharing.left : t.sharing.removed);
      await _load();
    } catch (e) {
      debugPrint('Container member removal failed: $e');
      if (mounted) _fail(t.sharing.failed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// A word in passing, gone on its own.
  void _toast(String message) =>
      AppDialog.success(message: message).notify(context);

  /// Something to read before going on.
  void _fail(String message) => AppDialog.error(message: message).show(context);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SettingsBloc.fromContext(context),
      child: ClayScaffold(
        appBar: ClayTopAppBar(
          title: t.settings.sharedAccess,
          leadingIcon: Icons.arrow_back_rounded,
          onLeadingTap: () => Navigator.of(context).maybePop(),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                color: AppColors.primary,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppSpacing.marginMobile),
                  children: [
                    _section(t.sharing.pendingInvites),
                    if (_pending.isEmpty)
                      _muted(t.sharing.noPendingInvites)
                    else
                      for (final invite in _pending) _inviteCard(invite),
                    const SizedBox(height: AppSpacing.lg),
                    _section(t.sharing.sharedByMe),
                    if (_owned.isEmpty && _ownedContainers.isEmpty)
                      _muted(t.sharing.nothingSharedByMe)
                    else ...[
                      for (final container in _ownedContainers)
                        _ownedContainerCard(container),
                      for (final collab in _owned) _ownedCard(collab),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    _section(t.sharing.sharedWithMe),
                    if (_sharedWithMe.isEmpty && _containersWithMe.isEmpty)
                      _muted(t.sharing.nothingSharedWithMe)
                    else ...[
                      for (final container in _containersWithMe)
                        _containerMemberCard(container),
                      for (final collab in _sharedWithMe) _memberCard(collab),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    const _BooksAndListsCard(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: ClaySectionHeader(title: title, underline: true),
  );

  Widget _muted(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
    child: Text(
      text,
      style: AppTextStyles.labelMd.copyWith(color: AppColors.outline),
    ),
  );

  Widget _roleTag(CollabRole role) => ClayTag(
    label: role == CollabRole.editor
        ? t.sharing.editorTag
        : t.sharing.viewerTag,
    icon: role == CollabRole.editor
        ? Icons.edit_rounded
        : Icons.visibility_rounded,
    background: AppColors.secondaryContainer,
    foreground: AppColors.onSecondaryContainer,
  );

  /// What a shared thing is, so a book and a recipe of the same name read
  /// apart on the page.
  Widget _kindTag(CollabKind kind) => ClayTag(
    label: switch (kind) {
      CollabKind.recipe => t.sharing.kindRecipe,
      CollabKind.book => t.sharing.kindBook,
      CollabKind.mealPlan => t.sharing.kindPlan,
    },
    icon: switch (kind) {
      CollabKind.recipe => Icons.restaurant_menu_rounded,
      CollabKind.book => Icons.menu_book_rounded,
      CollabKind.mealPlan => Icons.calendar_month_rounded,
    },
  );

  Widget _titleRow(String title, CollabKind kind) => Row(
    children: [
      Expanded(child: Text(title, style: AppTextStyles.bodyLg)),
      if (kind != CollabKind.recipe) _kindTag(kind),
    ],
  );

  Widget _ownedContainerCard(CollabContainerEntity container) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ClayCard(
        radius: AppRadius.md,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _titleRow(container.title, container.kind),
            const SizedBox(height: AppSpacing.sm),
            if (container.members.isEmpty)
              Text(
                t.sharing.noMembersYet,
                style: AppTextStyles.labelMd.copyWith(color: AppColors.outline),
              )
            else
              for (final entry in container.members.entries)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _nameOf(entry.key),
                        style: AppTextStyles.bodyMd,
                      ),
                    ),
                    _roleTag(entry.value),
                    IconButton(
                      tooltip: t.sharing.remove,
                      icon: Icon(
                        Icons.person_remove_rounded,
                        size: 20,
                        color: AppColors.error,
                      ),
                      onPressed: _busy
                          ? null
                          : () => _removeContainerMember(
                              container,
                              entry.key,
                              leaving: false,
                            ),
                    ),
                  ],
                ),
          ],
        ),
      ),
    );
  }

  Widget _containerMemberCard(CollabContainerEntity container) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ClayCard(
        radius: AppRadius.md,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _titleRow(container.title, container.kind),
                  Text(
                    t.sharing.invitedBy(name: _nameOf(container.ownerUid)),
                    style: AppTextStyles.labelMd.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            _roleTag(container.roleOf(_uid)),
            IconButton(
              tooltip: t.sharing.leave,
              icon: Icon(
                Icons.logout_rounded,
                size: 20,
                color: AppColors.error,
              ),
              onPressed: _busy
                  ? null
                  : () =>
                        _removeContainerMember(container, _uid, leaving: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inviteCard(ShareInviteEntity invite) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ClayCard(
        radius: AppRadius.md,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _titleRow(invite.recipeTitle, invite.kind),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Expanded(
                  child: Text(
                    t.sharing.invitedBy(name: _nameOf(invite.ownerUid)),
                    style: AppTextStyles.labelMd.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
                _roleTag(invite.role),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: ClayButton(
                    label: t.sharing.accept,
                    icon: Icons.check_rounded,
                    expanded: true,
                    onPressed: _busy
                        ? null
                        : () => _respond(invite, accept: true),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => _respond(invite, accept: false),
                  child: Text(
                    t.sharing.decline,
                    style: AppTextStyles.labelMd.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _ownedCard(CollabRecipeEntity collab) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ClayCard(
        radius: AppRadius.md,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(collab.recipe.title, style: AppTextStyles.bodyLg),
            const SizedBox(height: AppSpacing.sm),
            if (collab.members.isEmpty)
              Text(
                t.sharing.noMembersYet,
                style: AppTextStyles.labelMd.copyWith(color: AppColors.outline),
              )
            else
              for (final entry in collab.members.entries)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _nameOf(entry.key),
                        style: AppTextStyles.bodyMd,
                      ),
                    ),
                    _roleTag(entry.value),
                    IconButton(
                      tooltip: t.sharing.remove,
                      icon: Icon(
                        Icons.person_remove_rounded,
                        size: 20,
                        color: AppColors.error,
                      ),
                      onPressed: _busy
                          ? null
                          : () => _removeMember(
                              collab,
                              entry.key,
                              leaving: false,
                            ),
                    ),
                  ],
                ),
          ],
        ),
      ),
    );
  }

  Widget _memberCard(CollabRecipeEntity collab) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ClayCard(
        radius: AppRadius.md,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(collab.recipe.title, style: AppTextStyles.bodyLg),
                  Text(
                    t.sharing.invitedBy(name: _nameOf(collab.ownerUid)),
                    style: AppTextStyles.labelMd.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            _roleTag(collab.roleOf(_uid)),
            IconButton(
              tooltip: t.sharing.leave,
              icon: Icon(
                Icons.logout_rounded,
                size: 20,
                color: AppColors.error,
              ),
              onPressed: _busy
                  ? null
                  : () => _removeMember(collab, _uid, leaving: true),
            ),
          ],
        ),
      ),
    );
  }
}

/// The book and grocery-list share counts, as before.
class _BooksAndListsCard extends StatelessWidget {
  const _BooksAndListsCard();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) => switch (state) {
        SettingsLoading() => const SizedBox.shrink(),
        SettingsLoaded(
          sharedBooksCount: final books,
          sharedListsCount: final lists,
        ) =>
          books == 0 && lists == 0
              ? const SizedBox.shrink()
              : ClayCard(
                  radius: AppRadius.md,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Wrap(
                    spacing: AppSpacing.base,
                    runSpacing: AppSpacing.base,
                    children: [
                      if (books > 0)
                        ClayTag(
                          label: '$books ${t.books.myLibrary}',
                          icon: Icons.menu_book_rounded,
                        ),
                      if (lists > 0)
                        ClayTag(
                          label: '$lists ${t.groceryList.title}',
                          icon: Icons.shopping_cart_rounded,
                          background: AppColors.secondaryContainer,
                          foreground: AppColors.onSecondaryContainer,
                        ),
                    ],
                  ),
                ),
        SettingsError(error: final error) => ErrorRetryView(
          error: error,
          onRetry: () =>
              context.read<SettingsBloc>().add(const SettingsEvent.init()),
        ),
      },
    );
  }
}
