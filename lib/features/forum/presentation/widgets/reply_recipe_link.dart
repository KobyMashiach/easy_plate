import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/monetization/quota_gates.dart';
import '../../../../core/services/auth_session_service.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/utils/routing/routing.dart';
import '../../../my_recipes/presentation/pages/recipe_details_page.dart';
import '../../../shared_recipes/domain/repositories/shared_recipes_repository.dart';
import '../../../my_recipes/domain/repositories/recipes_repository.dart';
import '../../../shared_recipes/domain/usecases/get_shared_recipe_by_id_usecase.dart';
import '../../../shared_recipes/domain/usecases/import_shared_recipe_usecase.dart';
import '../../../../core/widgets/app_dialog.dart';

/// The "[link to recipe]" chip inside a forum reply.
///
/// Shows the title captured when the reply was written, and resolves the live
/// recipe on tap — a reply outlives the recipe it points at, so the lookup can
/// legitimately come back empty.
class ReplyRecipeLink extends StatefulWidget {
  final String sharedRecipeId;
  final String? title;

  const ReplyRecipeLink({super.key, required this.sharedRecipeId, this.title});

  @override
  State<ReplyRecipeLink> createState() => _ReplyRecipeLinkState();
}

class _ReplyRecipeLinkState extends State<ReplyRecipeLink> {
  bool _opening = false;
  bool _saving = false;

  /// Same import as the feed's save button, so a recipe linked in a reply can
  /// be kept without going back to find it in the feed.
  Future<void> _save() async {
    final repository = context.read<SharedRecipesRepository>();
    final recipes = context.read<RecipesRepository>();

    setState(() => _saving = true);
    try {
      final shared = await GetSharedRecipeByIdUseCase(repository)(
        widget.sharedRecipeId,
        viewerUid: AuthSessionService().user?.uid ?? '',
      );
      if (shared == null) {
        if (mounted) {
          AppDialog.warning(
            message: t.community.recipeUnavailable,
          ).notify(context);
        }
        return;
      }
      final outcome = await ImportSharedRecipeUseCase(recipes)(shared);
      if (mounted) {
        AppDialog.success(
          message: outcome == ImportOutcome.saved
              ? t.community.savedToMyRecipes
              : t.community.alreadySaved,
        ).notify(context);
      }
    } catch (e) {
      debugPrint('Saving linked recipe failed: $e');
      if (mounted) {
        AppDialog.error(message: t.community.loadFailed).show(context);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _open() async {
    final repository = context.read<SharedRecipesRepository>();
    final router = GoRouter.of(context);

    setState(() => _opening = true);
    try {
      final shared = await GetSharedRecipeByIdUseCase(repository)(
        widget.sharedRecipeId,
        viewerUid: AuthSessionService().user?.uid ?? '',
      );
      if (shared == null) {
        if (mounted) {
          AppDialog.warning(
            message: t.community.recipeUnavailable,
          ).notify(context);
        }
        return;
      }
      // The same daily quota as the feed: a link in a reply is another door
      // to the same community recipe.
      if (!mounted) return;
      final allowed = await QuotaGates.openSharedRecipe(
        context,
        sharedId: shared.id,
        authorUid: shared.authorUid,
      );
      if (!allowed) return;
      router.pushNamed(
        Routing.recipeDetails,
        extra: RecipeDetailsArgs(recipe: shared.recipe, readOnly: true),
      );
    } catch (e) {
      debugPrint('Opening linked recipe failed: $e');
      if (mounted) {
        AppDialog.error(message: t.community.loadFailed).show(context);
      }
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(child: _chip()),
        IconButton(
          tooltip: t.community.saveToMyRecipes,
          visualDensity: VisualDensity.compact,
          icon: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  Icons.bookmark_add_rounded,
                  size: 20,
                  color: AppColors.primary,
                ),
          onPressed: _saving || _opening ? null : _save,
        ),
      ],
    );
  }

  Widget _chip() {
    return GestureDetector(
      onTap: _opening ? null : _open,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.base,
        ),
        decoration: ShapeDecoration(
          color: AppColors.primaryFixed,
          shape: const StadiumBorder(),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_opening)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(
                Icons.link_rounded,
                size: 16,
                color: AppColors.primary,
              ),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                widget.title ?? t.community.openRecipe,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelMd.copyWith(color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
