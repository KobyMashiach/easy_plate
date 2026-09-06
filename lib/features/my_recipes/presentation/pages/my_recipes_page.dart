import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/account_avatar_button.dart';
import '../../../../core/utils/routing/routing.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../../../core/widgets/dietary_chip_selector.dart';
import '../../../../core/widgets/error_retry_view.dart';
import '../../domain/entities/recipe_entity.dart';
import '../bloc/my_recipes_bloc.dart';
import '../widgets/recipe_card.dart';

class MyRecipesPage extends StatelessWidget {
  const MyRecipesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MyRecipesBloc.fromContext(context),
      child: Builder(
        builder: (context) => ClayScaffold(
          appBar: ClayTopAppBar(
            title: t.appName,
            leading: const AccountAvatarButton(),
            trailingIcon: Icons.auto_awesome_rounded,
            // The page lives in an IndexedStack, so returning from ingestion
            // doesn't rebuild it — reload explicitly or a freshly saved recipe
            // stays invisible until the app restarts.
            onTrailingTap: () async {
              await context.pushNamed(Routing.ingestion);
              if (context.mounted) {
                context.read<MyRecipesBloc>().add(const MyRecipesEvent.init());
              }
            },
          ),
          body: BlocBuilder<MyRecipesBloc, MyRecipesState>(
            builder: (context, state) {
              return switch (state) {
                MyRecipesLoading() => const Center(child: CircularProgressIndicator()),
                MyRecipesLoaded(recipes: final recipes, dietaryFilters: final filters) =>
                  _RecipesBody(recipes: recipes, filters: filters),
                MyRecipesError(error: final error) => ErrorRetryView(
                    error: error,
                    onRetry: () =>
                        context.read<MyRecipesBloc>().add(const MyRecipesEvent.init()),
                  ),
              };
            },
          ),
        ),
      ),
    );
  }
}

class _RecipesBody extends StatefulWidget {
  final List<RecipeEntity> recipes;
  final List<DietaryPreference> filters;

  const _RecipesBody({required this.recipes, required this.filters});

  @override
  State<_RecipesBody> createState() => _RecipesBodyState();
}

class _RecipesBodyState extends State<_RecipesBody> {
  /// Recipes the user wrote versus ones saved from the community. A saved copy
  /// is fully theirs — editing it changes only the local copy, never the
  /// published original.
  bool _savedTab = false;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<MyRecipesBloc>();
    final filters = widget.filters;
    final recipes = widget.recipes
        .where((r) => r.isSavedFromCommunity == _savedTab)
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.marginMobile,
        AppSpacing.md,
        AppSpacing.marginMobile,
        ClayNavDock.reservedHeight,
      ),
      children: [
        ClayPageHeader(title: t.books.myRecipes, subtitle: t.books.recipesSubtitle),
        const SizedBox(height: AppSpacing.md),
        // Recessed search pill, per the Stitch library screen.
        ClayInset(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
          child: Row(
            children: [
              const Icon(Icons.search_rounded, color: AppColors.outline),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextField(
                  style: AppTextStyles.bodyMd,
                  decoration: InputDecoration(
                    hintText: t.common.search,
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.gutter),
                  ),
                  onChanged: (value) => bloc.add(.search(value)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.gutter),
        Row(
          children: [
            Expanded(
              child: _tab(
                label: t.recipe.mine,
                icon: Icons.edit_note_rounded,
                selected: !_savedTab,
                onTap: () => setState(() => _savedTab = false),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _tab(
                label: t.recipe.saved,
                icon: Icons.bookmark_rounded,
                selected: _savedTab,
                onTap: () => setState(() => _savedTab = true),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.gutter),
        DietaryChipSelector(
          selected: filters,
          onToggle: (pref) {
            final updated = [...filters];
            updated.contains(pref) ? updated.remove(pref) : updated.add(pref);
            bloc.add(.filterByDietary(updated));
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        if (recipes.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.lg),
            child: ClayEmptyState(
              icon: _savedTab ? Icons.bookmark_border_rounded : Icons.restaurant_menu_rounded,
              message: _savedTab ? t.recipe.noneSaved : t.recipe.noneMine,
              action: _savedTab
                  ? null
                  : ClayButton(
                      label: t.ingestion.title,
                      icon: Icons.add_rounded,
                      onPressed: () => context.pushNamed(Routing.ingestion),
                    ),
            ),
          )
        else
          for (final recipe in recipes)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: RecipeCard(
                recipe: recipe,
                // No reload on return: the list is driven by the box, so an
                // edit made on the details page arrives on its own.
                onTap: () => context.pushNamed(Routing.recipeDetails, extra: recipe),
              ),
            ),
      ],
    );
  }

  Widget _tab({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: selected ? AppColors.primary : AppColors.tertiary),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelMd.copyWith(
                  color: selected ? AppColors.primary : AppColors.tertiary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
