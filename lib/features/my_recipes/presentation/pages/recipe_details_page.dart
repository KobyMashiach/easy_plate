import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/duration_label.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/utils/routing/routing.dart';
import '../../../../core/widgets/allergen_chip_selector.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../../../core/widgets/dietary_chip_selector.dart';
import '../../../../core/hive/user_scope.dart';
import '../../../../core/services/image_storage_service.dart';
import '../../../../core/sync/recipe_image_store.dart';
import '../../../../core/widgets/image_source_sheet.dart';
import '../../../../core/widgets/image_viewer_page.dart';
import '../../../../core/widgets/measurement_unit_label.dart';
import '../../../../core/widgets/nutrition/nutrition_widgets.dart';
import '../widgets/nutrition_facts_card.dart';
import '../../domain/entities/recipe_entity.dart';
import '../cook_mode_entry.dart';
import '../../domain/entities/recipe_ingredient_entity.dart';
import '../../domain/repositories/recipes_repository.dart';
import '../../domain/usecases/save_recipe_usecase.dart';
import '../../../recipe_ingestion/domain/repositories/recipe_ingestion_repository.dart';
import '../../../recipe_sharing/domain/repositories/recipe_sharing_repository.dart';
import '../../../shared_recipes/domain/usecases/update_shared_recipe_usecase.dart';
import '../../../grocery_list/data/datasources/active_grocery_list_store.dart';
import '../../../grocery_list/domain/repositories/grocery_lists_repository.dart';
import '../../../grocery_list/domain/usecases/create_recipe_grocery_list_usecase.dart';
import '../../../grocery_list/presentation/widgets/grocery_lists_ui.dart';
import '../../../../core/navigation/main_tabs.dart';
import '../../../shared_recipes/domain/repositories/shared_recipes_repository.dart';
import '../../../recipe_sharing/domain/usecases/save_collab_recipe_usecase.dart';
import '../../../recipe_sharing/domain/usecases/sync_collab_recipe_usecase.dart';
import '../../../../core/services/auth_session_service.dart';
import '../../../recipe_ingestion/domain/usecases/estimate_nutrition_usecase.dart';
import '../../../recipe_ingestion/domain/usecases/generate_image_usecase.dart';
import '../../../recipe_ingestion/domain/usecases/generate_recipe_usecase.dart';
import '../../../recipe_ingestion/domain/usecases/parse_raw_text_usecase.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/features/feature_gate.dart';
import '../../../assistant/domain/assistant_scope.dart';
import '../../../assistant/presentation/widgets/assistant_fab.dart';

/// Route payload for [RecipeDetailsPage]. A bare entity was not enough once
/// the same screen started opening community recipes: those must not expose
/// edit or photo actions, which would have written a copy into the viewer's
/// own recipes under the shared id.
class RecipeDetailsArgs {
  final RecipeEntity recipe;

  /// True for recipes reached from the community that are not this
  /// account's own.
  final bool readOnly;

  /// Set when the screen shows this account's own community post: every
  /// save then rewrites the post, photo included, and nothing local.
  final String? sharedId;

  const RecipeDetailsArgs({
    required this.recipe,
    this.readOnly = false,
    this.sharedId,
  });
}

class RecipeDetailsPage extends StatefulWidget {
  final RecipeEntity recipe;
  final bool readOnly;
  final String? sharedId;

  const RecipeDetailsPage({
    super.key,
    required this.recipe,
    this.readOnly = false,
    this.sharedId,
  });

  @override
  State<RecipeDetailsPage> createState() => _RecipeDetailsPageState();
}

class _RecipeDetailsPageState extends State<RecipeDetailsPage> {
  late RecipeEntity recipe = widget.recipe;
  bool _analyzing = false;

  /// Read-only when opened that way, or when this account is a viewer on a
  /// shared recipe.
  bool get _readOnly => widget.readOnly || !recipe.canEdit;

  @override
  void initState() {
    super.initState();
    if (recipe.isShared) _syncShared();
  }

  /// A shared recipe's local copy is a cache; the document is the truth. On
  /// failure the cache stands, and the user is told it may be stale.
  Future<void> _syncShared() async {
    final uid = AuthSessionService().user?.uid;
    if (uid == null) return;
    try {
      final synced = await SyncCollabRecipeUseCase(
        sharing: context.read<RecipeSharingRepository>(),
        recipes: context.read<RecipesRepository>(),
      )(recipe, uid: uid);
      if (mounted) setState(() => recipe = synced);
    } catch (e) {
      debugPrint('Shared recipe sync failed: $e');
      if (mounted) {
        AppDialog.warning(message: t.sharing.syncFailed).notify(context);
      }
    }
  }

  /// Runs the analysis a template was saved without. The result keeps this
  /// recipe's id, photo and origin — it is the same recipe, now structured —
  /// and clears the pending flag. Capped like the original attempt was.
  bool _estimating = false;

  /// The recipe as stored right now, for a change to be made on. The page's
  /// copy is the one it opened with, and the website or another device may
  /// have edited the recipe since: a whole record built from that copy
  /// would put their edit back. A post opened as its author is not in the
  /// box under its own id, so its copy on screen is the base. Null when the
  /// recipe was deleted elsewhere — a write must not bring it back.
  Future<RecipeEntity?> _latest() async {
    if (widget.sharedId != null) return recipe;
    return context.read<RecipesRepository>().getRecipeById(recipe.id);
  }

  /// Fills servings and per-serving nutrition for a recipe that has none, or
  /// re-estimates one the user asked to redo. Saved straight away, like a
  /// deferred analysis.
  Future<void> _estimateNutrition() async {
    // A second tap before the button greys out would pay for a second call.
    if (_estimating) return;
    final ingestion = context.read<RecipeIngestionRepository>();
    setState(() => _estimating = true);
    try {
      final estimate = await EstimateNutritionUseCase(ingestion)(
        recipe,
      ).timeout(const Duration(seconds: 30));
      if (!mounted) return;
      // Only the estimate, onto the recipe as it is now: the call took
      // seconds, and an edit saved meanwhile must survive it.
      final base = await _latest();
      if (base == null) throw StateError('Recipe ${recipe.id} is gone');
      final updated = base.copyWith(
        servings: estimate.servings,
        nutrition: estimate.nutrition,
      );
      if (!mounted) return;
      // Through _persist, not a plain save: a post opened as its author must
      // not grow a local twin, and a shared recipe's estimate has to reach
      // the shared document or the next sync lays the old copy back.
      final stored = await _persist(updated);
      if (!mounted) return;
      setState(() => recipe = stored);
      AppDialog.success(message: t.nutrition.estimated).notify(context);
    } catch (e) {
      debugPrint('Nutrition estimate failed: $e');
      if (mounted) {
        AppDialog.error(message: t.nutrition.estimateFailed).show(context);
      }
    } finally {
      if (mounted) setState(() => _estimating = false);
    }
  }

  Future<void> _analyzeNow() async {
    if (_analyzing) return;
    final ingestion = context.read<RecipeIngestionRepository>();

    setState(() => _analyzing = true);
    try {
      // A template saved from a recipe *request* holds the request, not a
      // recipe: it is written, not parsed.
      final analysis = recipe.sourceChannel == RecipeIngestionChannel.aiRequest
          ? GenerateRecipeUseCase(ingestion)(recipe.rawText)
          : ParseRawTextUseCase(ingestion)(recipe.rawText);
      final parsed = await analysis.timeout(const Duration(seconds: 30));
      if (!mounted) return;
      // Built on the recipe as it is now, not as the page opened with it:
      // the model took seconds, and what changed meanwhile must survive.
      final base = await _latest();
      if (base == null) throw StateError('Recipe ${recipe.id} is gone');
      // Structured elsewhere meanwhile (by hand on the website, or this
      // same analysis on another device): that version stands.
      if (!base.pendingAnalysis && widget.sharedId == null) {
        if (mounted) setState(() => recipe = base);
        return;
      }
      final updated = RecipeEntity(
        id: base.id,
        title: parsed.title,
        prepTimeMinutes: parsed.prepTimeMinutes,
        cookTimeMinutes: parsed.cookTimeMinutes,
        ingredients: parsed.ingredients,
        steps: parsed.steps,
        // A topic the user already picked outranks the model's silence on it.
        dietaryTags: parsed.dietaryTags.isNotEmpty
            ? parsed.dietaryTags
            : base.dietaryTags,
        allergens: parsed.allergens.isNotEmpty
            ? parsed.allergens
            : base.allergens,
        mayContain: parsed.mayContain.isNotEmpty
            ? parsed.mayContain
            : base.mayContain,
        servings: parsed.servings ?? base.servings,
        nutrition: parsed.nutrition ?? base.nutrition,
        sourceChannel: base.sourceChannel,
        sourceUrl: base.sourceUrl,
        imageFileName: base.imageFileName,
        imageStoragePath: base.imageStoragePath,
        savedFromSharedId: base.savedFromSharedId,
        collabId: base.collabId,
        collabRole: base.collabRole,
        sharedRecipeId: base.sharedRecipeId,
        pendingAnalysis: false,
        createdAt: base.createdAt,
        // Carried so a save that leaves the words alone keeps the record's
        // language; the repository moves the version on when they changed.
        contentLang: base.contentLang,
        contentVersion: base.contentVersion,
      );
      if (!mounted) return;
      final stored = await _persist(updated);
      if (mounted) setState(() => recipe = stored);
    } catch (e) {
      debugPrint('Deferred analysis failed: $e');
      if (mounted) {
        AppDialog.error(message: t.recipe.analyzeFailed).show(context);
      }
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  /// Persists straight through the use case rather than a bloc: this page is
  /// pushed with the recipe as a route argument and owns no other state.
  Future<void> _changePhoto() async {
    final result = await showImageSourceSheet(
      context,
      hasImage: recipe.imageFileName != null,
      aiPrompt: GenerateImageUseCase.recipePrompt(recipe),
      searchQuery: recipe.title,
    );
    if (result == null || !mounted) return;

    // The photo goes onto the recipe as it is stored now: the sheet stayed
    // open a while, and an edit made elsewhere meanwhile must survive it.
    final base = await _latest();
    if (!mounted) return;
    if (base == null) {
      AppDialog.error(message: t.common.error).show(context);
      return;
    }
    final previous = base.imageFileName;
    // Read before the copyWith, which clears it: a new photo invalidates the
    // uploaded one, and this is the last moment the old path is known.
    final previousRemote = base.imageStoragePath;
    final updated = base.copyWith(
      imageFileName: result.fileName,
      removeImage: result.removed,
    );
    // Through the collab use case, not a plain save: a photo is part of what a
    // shared recipe carries, so swapping one here has to reach the shared
    // document too — otherwise the co-editors keep the picture that was
    // replaced, and only this device ever sees the new one.
    final RecipeEntity stored;
    try {
      stored = await _persist(updated);
    } catch (e) {
      // A refused shared write used to vanish here: the picture was uploaded,
      // nothing recorded it, and the screen went on showing the old one.
      debugPrint('Photo change failed for ${recipe.id}: $e');
      if (mounted) {
        AppDialog.error(message: t.common.error).show(context);
      }
      return;
    }
    // Drop the replaced file so removed photos don't accumulate on disk, and
    // the copy in Storage with it — nothing points at it any more, but it would
    // go on being billed.
    // In post mode the previous file name is the author's own local recipe
    // photo, which must stay on this device.
    if (widget.sharedId == null &&
        previous != null &&
        previous != updated.imageFileName) {
      await ImageStorageService().delete(previous);
      // The old upload stays when the recipe is published: every saved copy
      // in the community points at that path until its owner refreshes.
      final published =
          widget.sharedId != null || stored.sharedRecipeId != null;
      if (!published) {
        unawaited(
          RecipeImageStore().remove(previousRemote, uid: UserScope().uid),
        );
      }
    }
    if (mounted) setState(() => recipe = stored);
  }

  /// Photo changes stay on the image itself, so the bar action opens the
  /// structured editor. Saving here is immediate — the recipe already exists.
  /// Where a change goes. A community post (opened from the feed as its
  /// author) is rewritten in place. A local recipe is saved as always — and
  /// when it was published, the author is asked whether the post should
  /// follow, every time, since the two copies are theirs to keep apart.
  Future<RecipeEntity> _persist(RecipeEntity updated) async {
    final recipes = context.read<RecipesRepository>();
    final postId = widget.sharedId;
    if (postId != null) {
      try {
        await AppDialog.busy(
          context,
          () => UpdateSharedRecipeUseCase(
            context.read<SharedRecipesRepository>(),
            recipes,
          )(postId, updated, persist: false),
        );
      } catch (e) {
        // Nothing was written. Thrown, not swallowed: every caller says the
        // change failed in its own words and keeps what the post still says
        // — returning the old copy here let "nutrition estimated" show over
        // a refused save.
        debugPrint('Post update failed: $e');
        rethrow;
      }
      return updated;
    }

    // Upload, write, and possibly a feed lookup: behind the busy card, so
    // the page never sits with the old photo and no sign of work.
    final (stored, published) = await AppDialog.busy(context, () async {
      final stored = await SaveCollabRecipeUseCase(
        sharing: context.read<RecipeSharingRepository>(),
        recipes: context.read<RecipesRepository>(),
      )(updated, byUid: AuthSessionService().user?.uid ?? '');

      // Recipes published before the link existed carry no post id. Their
      // post is found by title among this account's own posts, and the link
      // is written so the next save skips the lookup.
      var published = stored.sharedRecipeId;
      if (published == null && stored.isMine) {
        published = await _findMyPost(stored);
        if (published != null) {
          await SaveRecipeUseCase(recipes)(
            stored.copyWith(sharedRecipeId: published),
          );
        }
      }
      return (stored, published);
    });
    if (published == null || !mounted) return stored;
    final also = await AppDialog.general(
      title: t.recipe.communityUpdateTitle,
      message: t.recipe.communityUpdateBody,
      icon: Icons.groups_rounded,
      confirmLabel: t.recipe.communityUpdateBoth,
      cancelLabel: t.recipe.communityUpdateLocal,
    ).show(context);
    if (also != true || !mounted) return stored;
    try {
      await AppDialog.busy(
        context,
        () => UpdateSharedRecipeUseCase(
          context.read<SharedRecipesRepository>(),
          context.read<RecipesRepository>(),
        )(published, stored),
      );
      if (mounted) {
        AppDialog.success(message: t.recipe.communityUpdated).notify(context);
      }
    } catch (e) {
      debugPrint('Community update failed: $e');
      // Offline, a timeout, a refusal: the post is still there, so the link
      // stays and the user hears the update did not go out.
      if (!isPostGone(e)) {
        if (mounted) {
          AppDialog.warning(
            message: t.recipe.communityUpdateFailed,
          ).notify(context);
        }
        return stored;
      }
      // The post is gone (taken down elsewhere): forget the link.
      final unlinked = stored.copyWith(clearSharedRecipeId: true);
      await SaveRecipeUseCase(recipes)(unlinked);
      if (mounted) {
        AppDialog.info(message: t.recipe.communityGone).notify(context);
      }
      return unlinked;
    }
    return stored;
  }

  /// The community post this account published from [recipe], by title —
  /// for recipes that predate the stored link. Null when there is none or
  /// the title is ambiguous.
  Future<String?> _findMyPost(RecipeEntity recipe) async {
    final uid = AuthSessionService().user?.uid;
    // Reached after an await: the page may have gone (a sign-out redirect).
    if (uid == null || !mounted) return null;
    try {
      // Only this account's posts, and without a like lookup per post: the
      // whole feed with likes was two hundred reads plus two hundred more,
      // on every save of a never-shared recipe.
      final mine = await context.read<SharedRecipesRepository>().getByAuthor(
        uid,
      );
      final title = recipe.title.trim();
      final matches = mine
          .where((p) => p.recipe.title.trim() == title)
          .toList();
      return matches.length == 1 ? matches.single.id : null;
    } catch (e) {
      debugPrint('Post lookup failed: $e');
      return null;
    }
  }

  /// A new shopping list holding this recipe's ingredients, scaled to how
  /// much is being made — then, if the user wants, straight to it.
  Future<void> _createGroceryList() async {
    final options = await showRecipeGroceryListSheet(context, recipe);
    if (options == null || !mounted) return;
    final create = CreateRecipeGroceryListUseCase(
      context.read<GroceryListsRepository>(),
      HiveActiveGroceryListStore.instance,
    );
    try {
      final list = await AppDialog.busy(
        context,
        () => create(recipe, name: options.name, scale: options.scale),
      );
      if (!mounted) return;
      final open = await AppDialog.info(
        message: t.groceryList.listCreated(name: list.name),
        icon: Icons.shopping_cart_rounded,
        confirmLabel: t.groceryList.openList,
        cancelLabel: t.groceryList.stayHere,
      ).show(context);
      if (open != true || !mounted) return;
      // The groceries tab already opened the new list (it follows the
      // active-list store); this only takes the user there.
      MainTabs.index.value = MainTabs.groceries;
      context.goNamed(Routing.home);
    } catch (e) {
      debugPrint('Grocery list from recipe failed: $e');
      if (mounted) AppDialog.error(message: t.common.error).show(context);
    }
  }

  Future<void> _edit() async {
    final repository = context.read<RecipesRepository>();
    final before = recipe;
    final edited = await context.pushNamed<RecipeEntity>(
      Routing.recipeEditor,
      extra: recipe,
    );
    if (edited == null || !mounted) return;
    try {
      final merged = mergeEditedRecipe(
        edited,
        before,
        await repository.getRecipeById(before.id),
      );
      if (!mounted) return;
      final stored = await _persist(merged);
      if (mounted) setState(() => recipe = stored);
    } catch (e) {
      // A refused shared write (a revoked or demoted member) or a failed
      // save: said, rather than the edits vanishing without a word.
      debugPrint('Saving the edited recipe failed: $e');
      if (mounted) AppDialog.error(message: t.common.error).show(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClayScaffold(
      // The copilot locked to this recipe, floating like the main one;
      // drawn only when the console opens it to this account.
      floatingActionButton: FeatureGate.builder(
        feature: FeaturesFlags.assistantScoped,
        builder: (context, access) => access.isEnabled
            ? AssistantFab(
                light: true,
                scope: AssistantScope.recipe(
                  id: recipe.id,
                  title: recipe.title,
                ),
              )
            : const SizedBox.shrink(),
      ),
      appBar: ClayTopAppBar(
        title: t.appName,
        leadingIcon: Icons.arrow_back_rounded,
        onLeadingTap: () => Navigator.of(context).maybePop(),
        trailingIcon: _readOnly ? null : Icons.edit_rounded,
        onTrailingTap: _readOnly ? null : _edit,
      ),
      body: ListView(
        // Room at the end for the floating copilot, so the last buttons
        // scroll out from under it instead of sitting there in its colour.
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.marginMobile,
          AppSpacing.md,
          AppSpacing.marginMobile,
          AppSpacing.xl + ClayNavDock.fabClearance,
        ),
        children: [
          GestureDetector(
            // A tap opens the photo full size; a long press changes it. With
            // no photo yet there is nothing to open, so a tap adds one.
            onTap:
                recipe.imageFileName != null || recipe.imageStoragePath != null
                ? () => showImageViewer(
                    context,
                    fileName: recipe.imageFileName,
                    remotePath: recipe.imageStoragePath,
                  )
                : (_readOnly ? null : _changePhoto),
            onLongPress: _readOnly ? null : _changePhoto,
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              height: 260,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClayImage(
                      fileName: recipe.imageFileName,
                      remotePath: recipe.imageStoragePath,
                      radius: AppRadius.lg,
                      fallbackIconSize: 64,
                    ),
                  ),
                  // A soft shade along the bottom edge so the chips on the
                  // photo stay legible whatever the dish looks like.
                  if (recipe.imageFileName != null ||
                      recipe.imageStoragePath != null)
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          gradient: LinearGradient(
                            begin: Alignment.center,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.45),
                            ],
                          ),
                        ),
                      ),
                    ),
                  PositionedDirectional(
                    start: AppSpacing.sm,
                    bottom: AppSpacing.sm,
                    child: Wrap(
                      spacing: AppSpacing.base,
                      children: [
                        if (recipe.collabRole case final role?)
                          _GlassChip(
                            icon: Icons.group_rounded,
                            label: switch (role) {
                              CollabRole.owner => t.sharing.ownerTag,
                              CollabRole.editor => t.sharing.editorTag,
                              CollabRole.viewer => t.sharing.viewerTag,
                            },
                          ),
                        ...recipe.dietaryTags
                            .take(2)
                            .map(
                              (tag) => _GlassChip(
                                icon: dietaryIcon(tag),
                                label: dietaryLabel(tag),
                              ),
                            ),
                      ],
                    ),
                  ),
                  if (!_readOnly)
                    PositionedDirectional(
                      end: AppSpacing.sm,
                      bottom: AppSpacing.sm,
                      child: GestureDetector(
                        // The pencil edits; the picture around it opens the viewer.
                        onTap: _changePhoto,
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.base),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLowest,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            recipe.imageFileName == null
                                ? Icons.add_a_photo_rounded
                                : Icons.edit_rounded,
                            size: 20,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.gutter),
          ClayPageHeader(title: recipe.title),
          const SizedBox(height: AppSpacing.gutter),
          // The figures a cook checks before anything else, at a glance.
          Row(
            children: [
              Expanded(
                child: StatTile(
                  icon: Icons.timer_rounded,
                  value: optionalDurationLabel(recipe.prepTimeMinutes),
                  caption: t.recipe.prepTime,
                ),
              ),
              const SizedBox(width: AppSpacing.base),
              Expanded(
                child: StatTile(
                  icon: Icons.local_fire_department_rounded,
                  value: optionalDurationLabel(recipe.cookTimeMinutes),
                  caption: t.recipe.cookTime,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(width: AppSpacing.base),
              Expanded(
                child: StatTile(
                  icon: Icons.group_rounded,
                  value: recipe.servings?.toString() ?? kMissingInfoPlaceholder,
                  caption: t.nutrition.servings,
                  color: AppColors.tertiary,
                ),
              ),
              const SizedBox(width: AppSpacing.base),
              Expanded(
                child: StatTile(
                  icon: Icons.bolt_rounded,
                  value: recipe.nutrition == null
                      ? kMissingInfoPlaceholder
                      : kcalNumber(recipe.nutrition!.calories),
                  unit: recipe.nutrition == null ? null : t.nutrition.kcal,
                  caption: t.nutrition.calories,
                  color: AppColors.warmAccent,
                ),
              ),
            ],
          ),
          if (recipe.dietaryTags.length > 2) ...[
            const SizedBox(height: AppSpacing.gutter),
            Wrap(
              spacing: AppSpacing.base,
              runSpacing: AppSpacing.base,
              children: recipe.dietaryTags.skip(2).map((tag) {
                final (background, foreground) = dietaryColors(tag);
                return ClayTag(
                  label: dietaryLabel(tag),
                  icon: dietaryIcon(tag),
                  background: background,
                  foreground: foreground,
                );
              }).toList(),
            ),
          ],
          AllergenNotice(
            allergens: recipe.allergens,
            mayContain: recipe.mayContain,
          ),
          const SizedBox(height: AppSpacing.lg),
          FeatureGate(
            feature: FeaturesFlags.nutrition,
            gapAfter: AppSpacing.md,
            child: NutritionFactsCard(
              nutrition: recipe.nutrition,
              servings: recipe.servings,
              estimating: _estimating,
              // Only a recipe with ingredients can be estimated, and only by
              // someone allowed to change it.
              onEstimate: _readOnly || recipe.ingredients.isEmpty
                  ? null
                  : _estimateNutrition,
            ),
          ),
          if (recipe.pendingAnalysis) ...[
            ClayCard(
              radius: AppRadius.md,
              padding: const EdgeInsets.all(AppSpacing.md),
              color: AppColors.secondaryContainer,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.hourglass_top_rounded,
                        size: 20,
                        color: AppColors.onSecondaryContainer,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          t.recipe.pendingAnalysis,
                          style: AppTextStyles.bodyLg.copyWith(
                            color: AppColors.onSecondaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    t.recipe.pendingAnalysisHint,
                    style: AppTextStyles.labelMd.copyWith(
                      color: AppColors.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ClayButton(
                    label: _analyzing
                        ? t.recipe.analyzing
                        : t.recipe.analyzeNow,
                    icon: Icons.auto_awesome_rounded,
                    expanded: true,
                    onPressed: _analyzing || _readOnly ? null : _analyzeNow,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          // Hands-free reading of the steps: one per screen, large type,
          // timers, and the screen kept awake. Above the ingredients, where
          // the cook reaches first; works on read-only recipes too, nothing
          // here writes. The gate draws Premium-only / coming-soon itself.
          // (Shefi for this recipe is the floating button, not a row here.)
          if (recipe.steps.isNotEmpty)
            FeatureGate(
              feature: FeaturesFlags.cookMode,
              gapAfter: AppSpacing.md,
              child: ClayButton(
                label: t.cookMode.start,
                icon: Icons.local_fire_department_rounded,
                expanded: true,
                onPressed: () => openCookMode(context, recipe),
              ),
            ),
          ClayCard(
            radius: AppRadius.md,
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClaySectionHeader(title: t.recipe.ingredients, underline: true),
                const SizedBox(height: AppSpacing.sm),
                ...recipe.ingredients.map(
                  (ingredient) => Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Icon(
                            Icons.circle,
                            size: 6,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            _ingredientLine(ingredient),
                            style: AppTextStyles.bodyMd,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (recipe.ingredients.isNotEmpty)
                  // Shopping for just this dish, without building a menu
                  // around it. Offered on read-only recipes too: a community
                  // recipe is as shoppable as one of the account's own.
                  FeatureGate(
                    feature: FeaturesFlags.groceryFromRecipe,
                    gapBefore: AppSpacing.md,
                    child: ClayButton(
                      label: t.groceryList.createFromRecipe,
                      icon: Icons.shopping_cart_rounded,
                      expanded: true,
                      onPressed: _createGroceryList,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ClayCard(
            radius: AppRadius.md,
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClaySectionHeader(
                  title: t.recipe.instructions,
                  underline: true,
                ),
                const SizedBox(height: AppSpacing.sm),
                ...recipe.steps.asMap().entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.base,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.primaryFixed,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${entry.key + 1}',
                            style: AppTextStyles.labelSm.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(entry.value, style: AppTextStyles.bodyMd),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _ingredientLine(RecipeIngredientEntity ingredient) {
    final amount = ingredient.isAmountMissing
        ? kMissingInfoPlaceholder
        : ingredient.displayAmount;
    final unit = measurementUnitLabel(ingredient.unit);
    return [amount, unit, ingredient.name].where((s) => s.isNotEmpty).join(' ');
  }
}

/// A translucent chip on top of the hero photo.
class _GlassChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _GlassChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: ShapeDecoration(
        color: AppColors.surfaceContainerLowest.withValues(alpha: 0.88),
        shape: const StadiumBorder(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurface),
          ),
        ],
      ),
    );
  }
}

/// The editor returns the record as it was when it opened, with the user's
/// changes. What landed meanwhile from elsewhere — the website's edit of
/// another field, the photo upload's storage path, a community link set or
/// cleared, a change of role — is taken from [fresh] wherever the user left
/// that field alone, so the save does not put the old values back. A field
/// both sides changed keeps the user's version: it is the one they just saw.
@visibleForTesting
RecipeEntity mergeEditedRecipe(
  RecipeEntity edited,
  RecipeEntity before,
  RecipeEntity? fresh,
) {
  if (fresh == null) return edited;
  var changed = false;
  T pick<T>(T mine, T was, T theirs, [bool Function(T a, T b)? same]) {
    final eq = same ?? (T a, T b) => a == b;
    // Untouched here and moved elsewhere: theirs.
    if (eq(mine, was) && !eq(theirs, was)) {
      changed = true;
      return theirs;
    }
    return mine;
  }

  bool sameList<E>(List<E> a, List<E> b) => listEquals(a, b);
  bool sameIngredients(
    List<RecipeIngredientEntity> a,
    List<RecipeIngredientEntity> b,
  ) => listEquals(
    [for (final i in a) '${i.name}\u0001${i.amount}\u0001${i.unit.name}'],
    [for (final i in b) '${i.name}\u0001${i.amount}\u0001${i.unit.name}'],
  );

  final title = pick(edited.title, before.title, fresh.title);
  final prep = pick(
    edited.prepTimeMinutes,
    before.prepTimeMinutes,
    fresh.prepTimeMinutes,
  );
  final cook = pick(
    edited.cookTimeMinutes,
    before.cookTimeMinutes,
    fresh.cookTimeMinutes,
  );
  final ingredients = pick(
    edited.ingredients,
    before.ingredients,
    fresh.ingredients,
    sameIngredients,
  );
  final steps = pick(edited.steps, before.steps, fresh.steps, sameList);
  final tags = pick(
    edited.dietaryTags,
    before.dietaryTags,
    fresh.dietaryTags,
    sameList,
  );
  final servings = pick(edited.servings, before.servings, fresh.servings);
  final nutrition = pick(edited.nutrition, before.nutrition, fresh.nutrition);
  final allergens = pick(
    edited.allergens,
    before.allergens,
    fresh.allergens,
    sameList,
  );
  final mayContain = pick(
    edited.mayContain,
    before.mayContain,
    fresh.mayContain,
    sameList,
  );
  final pending = pick(
    edited.pendingAnalysis,
    before.pendingAnalysis,
    fresh.pendingAnalysis,
  );
  // Not the editor's to change: always as stored now.
  final collabId = pick(edited.collabId, before.collabId, fresh.collabId);
  final collabRole = pick(
    edited.collabRole,
    before.collabRole,
    fresh.collabRole,
  );
  final photoMoved =
      fresh.imageFileName != before.imageFileName ||
      fresh.imageStoragePath != before.imageStoragePath;
  final linkMoved = fresh.sharedRecipeId != before.sharedRecipeId;
  if (!changed && !photoMoved && !linkMoved) return edited;
  return RecipeEntity(
    id: edited.id,
    title: title,
    prepTimeMinutes: prep,
    cookTimeMinutes: cook,
    ingredients: ingredients,
    steps: steps,
    dietaryTags: tags,
    servings: servings,
    nutrition: nutrition,
    allergens: allergens,
    mayContain: mayContain,
    sourceChannel: edited.sourceChannel,
    sourceUrl: edited.sourceUrl,
    imageFileName: photoMoved ? fresh.imageFileName : edited.imageFileName,
    imageStoragePath: photoMoved
        ? fresh.imageStoragePath
        : edited.imageStoragePath,
    savedFromSharedId: edited.savedFromSharedId,
    pendingAnalysis: pending,
    collabId: collabId,
    collabRole: collabRole,
    sharedRecipeId: linkMoved ? fresh.sharedRecipeId : edited.sharedRecipeId,
    createdAt: edited.createdAt,
    // The stored record's: the repository moves the version on from it
    // when the merged words differ.
    contentLang: fresh.contentLang ?? edited.contentLang,
    contentVersion: fresh.contentVersion,
  );
}

/// Whether a failed community update means the post no longer exists, the
/// only failure that should unlink the recipe from it for good.
@visibleForTesting
bool isPostGone(Object error) =>
    error is FirebaseException && error.code == 'not-found';
