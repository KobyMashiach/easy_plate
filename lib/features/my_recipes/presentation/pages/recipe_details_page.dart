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
import '../../../../core/widgets/clay/clay.dart';
import '../../../../core/widgets/dietary_chip_selector.dart';
import '../../../../core/services/image_storage_service.dart';
import '../../../../core/widgets/image_source_sheet.dart';
import '../../../../core/widgets/measurement_unit_label.dart';
import '../../domain/entities/recipe_entity.dart';
import '../../domain/entities/recipe_ingredient_entity.dart';
import '../../domain/repositories/recipes_repository.dart';
import '../../domain/usecases/save_recipe_usecase.dart';
import '../../../recipe_ingestion/domain/repositories/recipe_ingestion_repository.dart';
import '../../../recipe_sharing/domain/repositories/recipe_sharing_repository.dart';
import '../../../recipe_sharing/domain/usecases/save_collab_recipe_usecase.dart';
import '../../../recipe_sharing/domain/usecases/sync_collab_recipe_usecase.dart';
import '../../../../core/services/auth_session_service.dart';
import '../../../recipe_ingestion/domain/usecases/parse_raw_text_usecase.dart';

/// Route payload for [RecipeDetailsPage]. A bare entity was not enough once
/// the same screen started opening community recipes: those must not expose
/// edit or photo actions, which would have written a copy into the viewer's
/// own recipes under the shared id.
class RecipeDetailsArgs {
  final RecipeEntity recipe;

  /// True for recipes reached from the community. Only the author edits a
  /// shared recipe, and only from the feed card — never from this screen.
  final bool readOnly;

  const RecipeDetailsArgs({required this.recipe, this.readOnly = false});
}

class RecipeDetailsPage extends StatefulWidget {
  final RecipeEntity recipe;
  final bool readOnly;

  const RecipeDetailsPage({super.key, required this.recipe, this.readOnly = false});

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.sharing.syncFailed, style: AppTextStyles.bodyMd)),
        );
      }
    }
  }

  /// Runs the analysis a template was saved without. The result keeps this
  /// recipe's id, photo and origin — it is the same recipe, now structured —
  /// and clears the pending flag. Capped like the original attempt was.
  Future<void> _analyzeNow() async {
    final ingestion = context.read<RecipeIngestionRepository>();
    final recipes = context.read<RecipesRepository>();
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _analyzing = true);
    try {
      final parsed = await ParseRawTextUseCase(ingestion)(recipe.rawText)
          .timeout(const Duration(seconds: 30));
      final updated = RecipeEntity(
        id: recipe.id,
        title: parsed.title,
        prepTimeMinutes: parsed.prepTimeMinutes,
        cookTimeMinutes: parsed.cookTimeMinutes,
        ingredients: parsed.ingredients,
        steps: parsed.steps,
        // A topic the user already picked outranks the model's silence on it.
        dietaryTags: parsed.dietaryTags.isNotEmpty ? parsed.dietaryTags : recipe.dietaryTags,
        sourceChannel: recipe.sourceChannel,
        sourceUrl: recipe.sourceUrl,
        imageFileName: recipe.imageFileName,
        savedFromSharedId: recipe.savedFromSharedId,
        pendingAnalysis: false,
        createdAt: recipe.createdAt,
      );
      await SaveRecipeUseCase(recipes)(updated);
      if (mounted) setState(() => recipe = updated);
    } catch (e) {
      debugPrint('Deferred analysis failed: $e');
      messenger.showSnackBar(
        SnackBar(content: Text(t.recipe.analyzeFailed, style: AppTextStyles.bodyMd)),
      );
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
    );
    if (result == null || !mounted) return;

    final previous = recipe.imageFileName;
    final updated = recipe.copyWith(
      imageFileName: result.fileName,
      removeImage: result.removed,
    );
    await SaveRecipeUseCase(context.read<RecipesRepository>())(updated);
    // Drop the replaced file so removed photos don't accumulate on disk.
    if (previous != null && previous != updated.imageFileName) {
      await ImageStorageService().delete(previous);
    }
    if (mounted) setState(() => recipe = updated);
  }

  /// Photo changes stay on the image itself, so the bar action opens the
  /// structured editor. Saving here is immediate — the recipe already exists.
  Future<void> _edit() async {
    final repository = context.read<RecipesRepository>();
    final edited = await context.pushNamed<RecipeEntity>(
      Routing.recipeEditor,
      extra: recipe,
    );
    if (edited == null || !mounted) return;

    // Shared recipes write to the shared document first; the use case falls
    // through to a plain local save for everything else.
    await SaveCollabRecipeUseCase(
      sharing: context.read<RecipeSharingRepository>(),
      recipes: repository,
    )(edited, byUid: AuthSessionService().user?.uid ?? '');
    if (mounted) setState(() => recipe = edited);
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
            onTap: _readOnly ? null : _changePhoto,
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              height: 200,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClayImage(
                      fileName: recipe.imageFileName,
                      radius: AppRadius.md,
                      fallbackIconSize: 64,
                    ),
                  ),
                  if (!_readOnly)
                  PositionedDirectional(
                    end: AppSpacing.sm,
                    bottom: AppSpacing.sm,
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.base),
                      decoration: const BoxDecoration(
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
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.gutter),
          ClayPageHeader(title: recipe.title),
          const SizedBox(height: AppSpacing.gutter),
          Wrap(
            spacing: AppSpacing.base,
            runSpacing: AppSpacing.base,
            children: [
              ClayTag(
                label: '${t.recipe.prepTime} · ${optionalDurationLabel(recipe.prepTimeMinutes)}',
                icon: Icons.timer_rounded,
              ),
              if (recipe.collabRole case final role?)
                ClayTag(
                  label: switch (role) {
                    CollabRole.owner => t.sharing.ownerTag,
                    CollabRole.editor => t.sharing.editorTag,
                    CollabRole.viewer => t.sharing.viewerTag,
                  },
                  icon: Icons.group_rounded,
                  background: AppColors.secondaryContainer,
                  foreground: AppColors.onSecondaryContainer,
                ),
              ClayTag(
                label: '${t.recipe.cookTime} · ${optionalDurationLabel(recipe.cookTimeMinutes)}',
                icon: Icons.local_fire_department_rounded,
                background: AppColors.secondaryContainer,
                foreground: AppColors.onSecondaryContainer,
              ),
              ...recipe.dietaryTags.map((tag) {
                final (background, foreground) = dietaryColors(tag);
                return ClayTag(
                  label: dietaryLabel(tag),
                  icon: dietaryIcon(tag),
                  background: background,
                  foreground: foreground,
                );
              }),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
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
                      const Icon(Icons.hourglass_top_rounded,
                          size: 20, color: AppColors.onSecondaryContainer),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          t.recipe.pendingAnalysis,
                          style: AppTextStyles.bodyLg
                              .copyWith(color: AppColors.onSecondaryContainer),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    t.recipe.pendingAnalysisHint,
                    style: AppTextStyles.labelMd
                        .copyWith(color: AppColors.onSecondaryContainer),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ClayButton(
                    label: _analyzing ? t.recipe.analyzing : t.recipe.analyzeNow,
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
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
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
                ClaySectionHeader(title: t.recipe.instructions, underline: true),
                const SizedBox(height: AppSpacing.sm),
                ...recipe.steps.asMap().entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.base),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
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
    final amount =
        ingredient.isAmountMissing ? kMissingInfoPlaceholder : ingredient.amount.toString();
    final unit = measurementUnitLabel(ingredient.unit);
    return [amount, unit, ingredient.name].where((s) => s.isNotEmpty).join(' ');
  }
}
