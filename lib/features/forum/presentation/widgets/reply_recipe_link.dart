import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/services/auth_session_service.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/utils/routing/routing.dart';
import '../../../my_recipes/presentation/pages/recipe_details_page.dart';
import '../../../shared_recipes/domain/repositories/shared_recipes_repository.dart';
import '../../../shared_recipes/domain/usecases/get_shared_recipe_by_id_usecase.dart';

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

  Future<void> _open() async {
    final repository = context.read<SharedRecipesRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    setState(() => _opening = true);
    try {
      final shared = await GetSharedRecipeByIdUseCase(repository)(
        widget.sharedRecipeId,
        viewerUid: AuthSessionService().user?.uid ?? '',
      );
      if (shared == null) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(t.community.recipeUnavailable, style: AppTextStyles.bodyMd),
          ),
        );
        return;
      }
      router.pushNamed(
        Routing.recipeDetails,
        extra: RecipeDetailsArgs(recipe: shared.recipe, readOnly: true),
      );
    } catch (e) {
      debugPrint('Opening linked recipe failed: $e');
      messenger.showSnackBar(
        SnackBar(content: Text(t.community.loadFailed, style: AppTextStyles.bodyMd)),
      );
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _opening ? null : _open,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.base,
        ),
        decoration: const ShapeDecoration(
          color: AppColors.primaryFixed,
          shape: StadiumBorder(),
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
              const Icon(Icons.link_rounded, size: 16, color: AppColors.primary),
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
