import 'dart:async';

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
import '../../domain/entities/recipe_ingredient_entity.dart';
import '../../domain/repositories/recipes_repository.dart';
import '../../domain/usecases/save_recipe_usecase.dart';
import '../../../recipe_ingestion/domain/repositories/recipe_ingestion_repository.dart';
import '../../../recipe_sharing/domain/repositories/recipe_sharing_repository.dart';
import '../../../shared_recipes/domain/usecases/update_shared_recipe_usecase.dart';
import '../../../shared_recipes/domain/repositories/shared_recipes_repository.dart';
import '../../../recipe_sharing/domain/usecases/save_collab_recipe_usecase.dart';
import '../../../recipe_sharing/domain/usecases/sync_collab_recipe_usecase.dart';
import '../../../../core/services/auth_session_service.dart';
import '../../../recipe_ingestion/domain/usecases/estimate_nutrition_usecase.dart';
import '../../../recipe_ingestion/domain/usecases/generate_image_usecase.dart';
import '../../../recipe_ingestion/domain/usecases/generate_recipe_usecase.dart';
import '../../../recipe_ingestion/domain/usecases/parse_raw_text_usecase.dart';
import '../../../../core/widgets/app_dialog.dart';

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

  /// Fills servings and per-serving nutrition for a recipe that has none, or
  /// re-estimates one the user asked to redo. Saved straight away, like a
  /// deferred analysis.
  Future<void> _estimateNutrition() async {
    final ingestion = context.read<RecipeIngestionRepository>();
    final recipes = context.read<RecipesRepository>();
    setState(() => _estimating = true);
    try {
      final updated = await EstimateNutritionUseCase(ingestion)(
        recipe,
      ).timeout(const Duration(seconds: 30));
      await SaveRecipeUseCase(recipes)(updated);
      if (!mounted) return;
      setState(() => recipe = updated);
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
    final ingestion = context.read<RecipeIngestionRepository>();
    final recipes = context.read<RecipesRepository>();

    setState(() => _analyzing = true);
    try {
      // A template saved from a recipe *request* holds the request, not a
      // recipe: it is written, not parsed.
      final analysis = recipe.sourceChannel == RecipeIngestionChannel.aiRequest
          ? GenerateRecipeUseCase(ingestion)(recipe.rawText)
          : ParseRawTextUseCase(ingestion)(recipe.rawText);
      final parsed = await analysis.timeout(const Duration(seconds: 30));
      final updated = RecipeEntity(
        id: recipe.id,
        title: parsed.title,
        prepTimeMinutes: parsed.prepTimeMinutes,
        cookTimeMinutes: parsed.cookTimeMinutes,
        ingredients: parsed.ingredients,
        steps: parsed.steps,
        // A topic the user already picked outranks the model's silence on it.
        dietaryTags: parsed.dietaryTags.isNotEmpty
            ? parsed.dietaryTags
            : recipe.dietaryTags,
        allergens: parsed.allergens.isNotEmpty
            ? parsed.allergens
            : recipe.allergens,
        mayContain: parsed.mayContain.isNotEmpty
            ? parsed.mayContain
            : recipe.mayContain,
        servings: parsed.servings ?? recipe.servings,
        nutrition: parsed.nutrition ?? recipe.nutrition,
        sourceChannel: recipe.sourceChannel,
        sourceUrl: recipe.sourceUrl,
        imageFileName: recipe.imageFileName,
        imageStoragePath: recipe.imageStoragePath,
        savedFromSharedId: recipe.savedFromSharedId,
        collabId: recipe.collabId,
        collabRole: recipe.collabRole,
        sharedRecipeId: recipe.sharedRecipeId,
        pendingAnalysis: false,
        createdAt: recipe.createdAt,
      );
      await SaveRecipeUseCase(recipes)(updated);
      if (mounted) setState(() => recipe = updated);
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
    );
    if (result == null || !mounted) return;

    final previous = recipe.imageFileName;
    // Read before the copyWith, which clears it: a new photo invalidates the
    // uploaded one, and this is the last moment the old path is known.
    final previousRemote = recipe.imageStoragePath;
    final updated = recipe.copyWith(
      imageFileName: result.fileName,
      removeImage: result.removed,
    );
    // Through the collab use case, not a plain save: a photo is part of what a
    // shared recipe carries, so swapping one here has to reach the shared
    // document too — otherwise the co-editors keep the picture that was
    // replaced, and only this device ever sees the new one.
    final stored = await _persist(updated);
    // Drop the replaced file so removed photos don't accumulate on disk, and
    // the copy in Storage with it — nothing points at it any more, but it would
    // go on being billed.
    if (previous != null && previous != updated.imageFileName) {
      await ImageStorageService().delete(previous);
      unawaited(
        RecipeImageStore().remove(previousRemote, uid: UserScope().uid),
      );
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
      await UpdateSharedRecipeUseCase(
        context.read<SharedRecipesRepository>(),
        context.read<RecipesRepository>(),
      )(postId, updated, persist: false);
      return updated;
    }

    final stored = await SaveCollabRecipeUseCase(
      sharing: context.read<RecipeSharingRepository>(),
      recipes: context.read<RecipesRepository>(),
    )(updated, byUid: AuthSessionService().user?.uid ?? '');

    final published = stored.sharedRecipeId;
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
      await UpdateSharedRecipeUseCase(
        context.read<SharedRecipesRepository>(),
        context.read<RecipesRepository>(),
      )(published, stored);
      if (mounted) {
        AppDialog.success(message: t.recipe.communityUpdated).notify(context);
      }
    } catch (e) {
      debugPrint('Community update failed: $e');
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

  Future<void> _edit() async {
    final edited = await context.pushNamed<RecipeEntity>(
      Routing.recipeEditor,
      extra: recipe,
    );
    if (edited == null || !mounted) return;
    final stored = await _persist(edited);
    if (mounted) setState(() => recipe = stored);
  }

  @override
  Widget build(BuildContext context) {
    return ClayScaffold(
      appBar: ClayTopAppBar(
        title: t.appName,
        leadingIcon: Icons.arrow_back_rounded,
        onLeadingTap: () => Navigator.of(context).maybePop(),
        trailingIcon: _readOnly ? null : Icons.edit_rounded,
        onTrailingTap: _readOnly ? null : _edit,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.marginMobile,
          AppSpacing.md,
          AppSpacing.marginMobile,
          AppSpacing.xl,
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
          NutritionFactsCard(
            nutrition: recipe.nutrition,
            servings: recipe.servings,
            estimating: _estimating,
            // Only a recipe with ingredients can be estimated, and only by
            // someone allowed to change it.
            onEstimate: _readOnly || recipe.ingredients.isEmpty
                ? null
                : _estimateNutrition,
          ),
          const SizedBox(height: AppSpacing.md),
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
        : ingredient.amount.toString();
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
