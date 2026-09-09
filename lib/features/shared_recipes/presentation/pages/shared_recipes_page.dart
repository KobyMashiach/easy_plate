import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/ads/feed_ad_layout.dart';
import '../../../../core/ads/feed_ad_pool.dart';
import '../../../../core/ads/native_ad_card.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/monetization/daily_quota_policy.dart';
import '../../../../core/monetization/daily_usage_service.dart';
import '../../../../core/monetization/entitlement_service.dart';
import '../../../../core/monetization/monetization_config.dart';
import '../../../../core/monetization/quota_gates.dart';
import '../../../../core/services/auth_session_service.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/utils/routing/routing.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../../../core/widgets/error_retry_view.dart';
import '../../../../core/widgets/refreshable_empty_state.dart';
import '../../../../core/widgets/measurement_unit_label.dart';
import '../../../community/presentation/widgets/author_row.dart';
import '../../../my_recipes/presentation/widgets/recipe_picker_sheet.dart';
import '../../../my_recipes/domain/entities/recipe_entity.dart';
import '../../../my_recipes/presentation/pages/recipe_details_page.dart';
import '../../domain/entities/shared_recipe_entity.dart';
import '../widgets/shared_feed_filter_sheet.dart';
import '../widgets/shared_feed_query.dart';
import '../widgets/shared_quota_banner.dart';
import '../bloc/shared_recipes_bloc.dart';

class SharedRecipesPage extends StatelessWidget {
  const SharedRecipesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SharedRecipesBloc.fromContext(context),
      child: Builder(
        builder: (context) => BlocConsumer<SharedRecipesBloc, SharedRecipesState>(
          listener: (context, state) {
            if (state is SharedRecipesLoaded && state.imported) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(t.community.savedToMyRecipes, style: AppTextStyles.bodyMd),
                ),
              );
            }
          },
          builder: (context, state) {
            return Stack(
              children: [
                switch (state) {
                  SharedRecipesLoading() => const Center(child: CircularProgressIndicator()),
                  SharedRecipesLoaded(recipes: final recipes, savedIds: final savedIds) =>
                    _Feed(recipes: recipes, savedIds: savedIds),
                  SharedRecipesError(error: final error) => ErrorRetryView(
                      error: error,
                      onRetry: () => context
                          .read<SharedRecipesBloc>()
                          .add(const SharedRecipesEvent.init()),
                    ),
                },
                PositionedDirectional(
                  end: AppSpacing.marginMobile,
                  bottom: ClayNavDock.reservedHeight,
                  child: FloatingActionButton(
                    heroTag: 'share-recipe',
                    backgroundColor: AppColors.primary,
                    onPressed: () => _pickAndShare(context),
                    child: const Icon(Icons.ios_share_rounded, color: AppColors.onPrimary),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// The picker loads My Recipes through its own bloc and renders its own empty
/// state, so there is nothing to pre-load or guard here.
Future<void> _pickAndShare(BuildContext context) async {
  final bloc = context.read<SharedRecipesBloc>();
  final picked = await showRecipePickerSheet(context);
  if (picked != null) bloc.add(SharedRecipesEvent.share(picked));
}

class _Feed extends StatefulWidget {
  final List<SharedRecipeEntity> recipes;
  final Set<String> savedIds;

  const _Feed({required this.recipes, required this.savedIds});

  @override
  State<_Feed> createState() => _FeedState();
}

class _FeedState extends State<_Feed> {
  final _search = TextEditingController();
  SharedFeedQuery _query = const SharedFeedQuery();

  /// The feed's native ads, kept across rebuilds so a like or a filter does
  /// not re-request them.
  final _ads = FeedAdPool();

  /// What the lock badges on the cards depend on.
  late final Listenable _gateSources = Listenable.merge([
    DailyUsageService(),
    EntitlementService(),
    FirebaseService().configRevision,
  ]);

  @override
  void dispose() {
    _search.dispose();
    _ads.dispose();
    super.dispose();
  }

  String get _emptyMessage => switch (_query.scope) {
        SharedFeedScope.mine => t.community.noneOfMine,
        SharedFeedScope.saved || SharedFeedScope.all => t.community.noSharedRecipes,
      };

  /// Hands the indicator a future that completes when the bloc has finished,
  /// rather than one derived from the state stream.
  Future<void> _refreshFeed(BuildContext context) {
    final done = Completer<void>();
    context.read<SharedRecipesBloc>().add(SharedRecipesEvent.refresh(done));
    return done.future;
  }

  Future<void> _openFilters() async {
    final updated = await showSharedFeedFilterSheet(context, _query);
    if (updated != null && mounted) setState(() => _query = updated);
  }

  @override
  Widget build(BuildContext context) {
    final visible = _query.apply(
      widget.recipes,
      viewerUid: AuthSessionService().user?.uid,
      savedIds: widget.savedIds,
    );

    // "Nothing matched" and "nothing has been shared" are different problems
    // and need different wording, so the empty state distinguishes them.
    final isSearchingOrFiltering = _query.search.isNotEmpty || _query.isNarrowed;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.marginMobile,
            0,
            AppSpacing.marginMobile,
            AppSpacing.sm,
          ),
          child: Column(
            children: [
              const SharedQuotaBanner(),
              Row(
                children: [
                  Expanded(child: _searchField()),
                  const SizedBox(width: AppSpacing.sm),
                  _filterButton(),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: _scopeChip(
                      label: t.community.allRecipes,
                      value: SharedFeedScope.all,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: _scopeChip(
                      label: t.community.myRecipes,
                      value: SharedFeedScope.mine,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: _scopeChip(
                      label: t.community.savedOnly,
                      value: SharedFeedScope.saved,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _refreshFeed(context),
            color: AppColors.primary,
            child: visible.isEmpty
                ? RefreshableEmptyState(
                    child: ClayEmptyState(
                      icon: isSearchingOrFiltering
                          ? Icons.search_off_rounded
                          : Icons.public_rounded,
                      message: isSearchingOrFiltering
                          ? t.community.noResults
                          : _emptyMessage,
                    ),
                  )
                : ListenableBuilder(
                    listenable: _gateSources,
                    builder: (context, _) => _list(visible),
                  ),
          ),
        ),
      ],
    );
  }

  /// The recipes with a native ad card after every few of them — for accounts
  /// that see ads at all. The card positions are arithmetic on the visible
  /// list, so a filter that shortens the list moves the ads with it.
  Widget _list(List<SharedRecipeEntity> visible) {
    final layout = FeedAdLayout(
      itemCount: visible.length,
      interval: MonetizationConfig.adFree ? 0 : MonetizationConfig.feedAdInterval,
    );

    return ListView.separated(
      // Always scrollable so a list too short to overflow can still be pulled.
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.marginMobile,
        0,
        AppSpacing.marginMobile,
        ClayNavDock.reservedHeight,
      ),
      itemCount: layout.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, position) => switch (layout.slotAt(position)) {
        ContentSlot(index: final index) => _SharedCard(shared: visible[index]),
        AdSlot(adIndex: final adIndex) => switch (_ads.slot(adIndex)) {
            final slot? => NativeAdCard(slot: slot),
            null => const SizedBox.shrink(),
          },
      },
    );
  }

  Widget _searchField() {
    return ClayInset(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: AppColors.outline),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextField(
              controller: _search,
              style: AppTextStyles.bodyMd,
              decoration: InputDecoration(
                hintText: t.community.searchHint,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.gutter),
              ),
              onChanged: (value) =>
                  setState(() => _query = _query.copyWith(search: value.trim())),
            ),
          ),
          if (_query.search.isNotEmpty)
            GestureDetector(
              onTap: () => setState(() {
                _search.clear();
                _query = _query.copyWith(search: '');
              }),
              child: const Icon(Icons.close_rounded, color: AppColors.outline),
            ),
        ],
      ),
    );
  }

  /// A red dot marks an active filter, so an empty feed is never a mystery.
  /// The button itself keeps its resting look — recolouring the whole control
  /// read as a selected state rather than as a notice.
  Widget _filterButton() {
    final active = _query.isNarrowed || !_query.isDefaultSort;

    return GestureDetector(
      onTap: _openFilters,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        // The dot sits half outside the button, so it needs to paint beyond
        // the stack's bounds.
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.gutter),
            decoration: const ShapeDecoration(
              color: AppColors.surfaceContainerLow,
              shape: StadiumBorder(side: BorderSide(color: AppColors.outlineVariant)),
            ),
            child: const Icon(Icons.tune_rounded, size: 20, color: AppColors.tertiary),
          ),
          if (active)
            PositionedDirectional(
              top: -2,
              end: -2,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                  // Ringed in the page background so the dot stays legible
                  // against the button's own edge.
                  border: Border.all(color: AppColors.background, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _scopeChip({required String label, required SharedFeedScope value}) {
    final selected = _query.scope == value;
    return GestureDetector(
      onTap: () => setState(() => _query = _query.copyWith(scope: value)),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.base),
        decoration: ShapeDecoration(
          color: selected ? AppColors.primaryFixed : AppColors.surfaceContainerLow,
          shape: StadiumBorder(
            side: BorderSide(color: selected ? AppColors.primary : AppColors.outlineVariant),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.labelSm.copyWith(
            color: selected ? AppColors.primary : AppColors.tertiary,
          ),
        ),
      ),
    );
  }
}

class _SharedCard extends StatelessWidget {
  final SharedRecipeEntity shared;

  const _SharedCard({required this.shared});

  /// Edits the *published* copy. Someone else's recipe is not editable here at
  /// all — importing it makes a local copy, and that copy is edited from My
  /// Recipes like any other.
  Future<void> _edit(BuildContext context) async {
    final bloc = context.read<SharedRecipesBloc>();
    final messenger = ScaffoldMessenger.of(context);
    final edited = await context.pushNamed<RecipeEntity>(
      Routing.recipeEditor,
      extra: shared.recipe,
    );
    if (edited == null) return;

    bloc.add(SharedRecipesEvent.updateShared(shared.id, edited));
    messenger.showSnackBar(
      SnackBar(content: Text(t.community.sharedUpdated, style: AppTextStyles.bodyMd)),
    );
  }

  Future<void> _confirmUnshare(BuildContext context) async {
    final bloc = context.read<SharedRecipesBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.community.unshare, style: AppTextStyles.headlineMd),
        content: Text(t.community.unshareConfirm, style: AppTextStyles.bodyMd),
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
    if (confirmed ?? false) bloc.add(SharedRecipesEvent.unshare(shared.id));
  }

  /// Through the daily quota first. Read-only for everyone, the author
  /// included: their edit lives on the card above and rewrites the shared
  /// copy, not a local one.
  Future<void> _open(BuildContext context) async {
    final allowed = await QuotaGates.openSharedRecipe(
      context,
      sharedId: shared.id,
      authorUid: shared.authorUid,
    );
    if (!allowed || !context.mounted) return;
    context.pushNamed(
      Routing.recipeDetails,
      extra: RecipeDetailsArgs(recipe: shared.recipe, readOnly: true),
    );
  }

  /// The badge that says what opening this card will cost — nothing for a
  /// free or already-opened recipe, a play icon for a video, a lock when the
  /// day's allowance is spent.
  IconData? _gateBadge(bool isMine) {
    if (isMine || MonetizationConfig.adFree) return null;
    final usage = DailyUsageService();
    return switch (DailyQuotaPolicy.sharedRecipe(
      viewedToday: usage.sharedViewsToday,
      alreadyViewed: usage.hasViewedShared(shared.id),
      premium: false,
      limits: MonetizationConfig.limits,
    )) {
      GateVerdict.free => null,
      GateVerdict.rewarded => Icons.play_circle_outline_rounded,
      GateVerdict.blocked => Icons.lock_outline_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<SharedRecipesBloc>();
    final isMine = AuthSessionService().user?.uid == shared.authorUid;
    final recipe = shared.recipe;
    final badge = _gateBadge(isMine);

    return ClayCard(
      radius: AppRadius.md,
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: () => _open(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AuthorRow(
            name: shared.authorName,
            photoUrl: shared.authorPhotoUrl,
            createdAt: shared.createdAt,
            trailing: isMine
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: t.community.editShared,
                        icon: const Icon(Icons.edit_rounded,
                            size: 20, color: AppColors.primary),
                        onPressed: () => _edit(context),
                      ),
                      IconButton(
                        tooltip: t.community.unshare,
                        icon: const Icon(Icons.delete_outline_rounded,
                            size: 20, color: AppColors.error),
                        onPressed: () => _confirmUnshare(context),
                      ),
                    ],
                  )
                : null,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(child: Text(recipe.title, style: AppTextStyles.bodyLg)),
              if (badge != null) ...[
                const SizedBox(width: AppSpacing.base),
                Icon(badge, size: 18, color: AppColors.tertiary),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            recipe.ingredients.take(4).map((i) {
              final unit = measurementUnitLabel(i.unit);
              final amount = i.isAmountMissing ? kMissingInfoPlaceholder : '${i.amount}';
              return [amount, unit, i.name].where((s) => s.isNotEmpty).join(' ');
            }).join(' · '),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.labelMd.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  shared.likedByMe ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  size: 20,
                  color: shared.likedByMe ? AppColors.error : AppColors.tertiary,
                ),
                onPressed: () => bloc.add(SharedRecipesEvent.toggleLike(shared.id)),
              ),
              Text(
                '${shared.likeCount}',
                style: AppTextStyles.labelMd.copyWith(color: AppColors.tertiary),
              ),
              const Spacer(),
              ClayButton(
                label: t.community.saveToMyRecipes,
                icon: Icons.bookmark_add_rounded,
                onPressed: () => bloc.add(SharedRecipesEvent.importToMyRecipes(shared)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
