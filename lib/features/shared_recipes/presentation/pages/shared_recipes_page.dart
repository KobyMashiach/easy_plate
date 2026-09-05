import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/services/auth_session_service.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/utils/routing/routing.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../../../core/widgets/error_retry_view.dart';
import '../../../../core/widgets/measurement_unit_label.dart';
import '../../../community/presentation/widgets/author_row.dart';
import '../../../my_recipes/presentation/widgets/recipe_picker_sheet.dart';
import '../../domain/entities/shared_recipe_entity.dart';
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
                  SharedRecipesLoaded(recipes: final recipes) => _Feed(recipes: recipes),
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

class _Feed extends StatelessWidget {
  final List<SharedRecipeEntity> recipes;

  const _Feed({required this.recipes});

  @override
  Widget build(BuildContext context) {
    if (recipes.isEmpty) {
      return ClayEmptyState(
        icon: Icons.public_rounded,
        message: t.community.noSharedRecipes,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.marginMobile,
        0,
        AppSpacing.marginMobile,
        ClayNavDock.reservedHeight,
      ),
      itemCount: recipes.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) => _SharedCard(shared: recipes[index]),
    );
  }
}

class _SharedCard extends StatelessWidget {
  final SharedRecipeEntity shared;

  const _SharedCard({required this.shared});

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

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<SharedRecipesBloc>();
    final isMine = AuthSessionService().user?.uid == shared.authorUid;
    final recipe = shared.recipe;

    return ClayCard(
      radius: AppRadius.md,
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: () => context.pushNamed(Routing.recipeDetails, extra: recipe),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AuthorRow(
            name: shared.authorName,
            photoUrl: shared.authorPhotoUrl,
            createdAt: shared.createdAt,
            trailing: isMine
                ? IconButton(
                    tooltip: t.community.unshare,
                    icon: const Icon(Icons.delete_outline_rounded,
                        size: 20, color: AppColors.error),
                    onPressed: () => _confirmUnshare(context),
                  )
                : null,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(recipe.title, style: AppTextStyles.bodyLg),
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
