import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
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

class RecipeDetailsPage extends StatefulWidget {
  final RecipeEntity recipe;

  const RecipeDetailsPage({super.key, required this.recipe});

  @override
  State<RecipeDetailsPage> createState() => _RecipeDetailsPageState();
}

class _RecipeDetailsPageState extends State<RecipeDetailsPage> {
  late RecipeEntity recipe = widget.recipe;

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

    await SaveRecipeUseCase(repository)(edited);
    if (mounted) setState(() => recipe = edited);
  }

  @override
  Widget build(BuildContext context) {
    return ClayScaffold(
      appBar: ClayTopAppBar(
        title: t.appName,
        leadingIcon: Icons.arrow_back_rounded,
        onLeadingTap: () => Navigator.of(context).maybePop(),
        trailingIcon: Icons.edit_rounded,
        onTrailingTap: _edit,
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
            onTap: _changePhoto,
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
