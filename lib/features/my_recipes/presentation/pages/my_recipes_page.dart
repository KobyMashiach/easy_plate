import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/account_avatar_button.dart';
import '../../../../core/widgets/notification_bell_button.dart';
import '../../../../core/utils/routing/routing.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../../../core/widgets/dietary_chip_selector.dart';
import '../../../../core/widgets/error_retry_view.dart';
import '../../domain/entities/recipe_entity.dart';
import '../bloc/my_recipes_bloc.dart';
import '../../../recipe_sharing/presentation/widgets/recipe_share_sheet.dart';
import '../widgets/recipe_card.dart';
import 'recipe_details_page.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/walkthrough/walkthrough.dart';
import '../../../../core/walkthrough/app_walkthroughs.dart';

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
            actions: const [NotificationBellButton()],
          ),
          body: BlocBuilder<MyRecipesBloc, MyRecipesState>(
            builder: (context, state) {
              return switch (state) {
                MyRecipesLoading() => const Center(
                  child: CircularProgressIndicator(),
                ),
                MyRecipesLoaded(
                  recipes: final recipes,
                  dietaryFilters: final filters,
                ) =>
                  _RecipesBody(recipes: recipes, filters: filters),
                MyRecipesError(error: final error) => ErrorRetryView(
                  error: error,
                  onRetry: () => context.read<MyRecipesBloc>().add(
                    const MyRecipesEvent.init(),
                  ),
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

  Future<void> _confirmRemove(
    BuildContext context,
    MyRecipesBloc bloc,
    RecipeEntity recipe,
  ) async {
    final confirmed = await AppDialog.warning(
      title: t.community.removeSaved,
      message: t.community.removeSavedConfirm,
      icon: Icons.bookmark_remove_rounded,
      confirmLabel: t.common.delete,
      cancelLabel: t.common.cancel,
      destructive: true,
    ).show(context);
    if (confirmed ?? false) bloc.add(MyRecipesEvent.deleteRecipe(recipe.id));
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<MyRecipesBloc>();
    final filters = widget.filters;
    final recipes = widget.recipes
        .where((r) => r.isSavedFromCommunity == _savedTab)
        .toList();

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.marginMobile,
        AppSpacing.md,
        AppSpacing.marginMobile,
        ClayNavDock.bottomPadding(context),
      ),
      children: [
        ClayPageHeader(
          title: t.books.myRecipes,
          subtitle: t.books.recipesSubtitle,
          // The sparkle rather than a plus: adding a recipe here means the
          // model reads it in, and the same icon marks every AI action in
          // the app.
          trailing: WalkthroughTarget(
            id: WalkthroughIds.recipesAdd,
            child: ClayIconButton(
              icon: Icons.auto_awesome_rounded,
              filled: true,
              size: 48,
              tooltip: t.ingestion.title,
              onTap: () async {
                await context.pushNamed(Routing.ingestion);
                if (context.mounted) bloc.add(const MyRecipesEvent.init());
              },
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // The switch between what was written and what was saved is the
        // page's main division, so it stands on its own right under the
        // title; the search and the topic chips, which only narrow the list,
        // sit together in one card below it.
        WalkthroughTarget(
          id: WalkthroughIds.recipesSegments,
          child: ClaySegmentedControl(
            segments: [
              ClaySegment(label: t.recipe.mine, icon: Icons.edit_note_rounded),
              ClaySegment(label: t.recipe.saved, icon: Icons.bookmark_rounded),
            ],
            selectedIndex: _savedTab ? 1 : 0,
            onSelected: (index) => setState(() => _savedTab = index == 1),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        WalkthroughTarget(
          id: WalkthroughIds.recipesFilters,
          child: ClayCard(
            radius: AppRadius.md,
            padding: const EdgeInsets.all(AppSpacing.gutter),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Recessed search pill, per the Stitch library screen.
                ClayInset(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.gutter,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search_rounded,
                        color: AppColors.outline,
                      ),
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
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.gutter,
                            ),
                          ),
                          onChanged: (value) => bloc.add(.search(value)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.gutter),
                Text(
                  t.editor.topics,
                  style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.base),
                DietaryChipSelector(
                  selected: filters,
                  onToggle: (pref) {
                    final updated = [...filters];
                    updated.contains(pref)
                        ? updated.remove(pref)
                        : updated.add(pref);
                    bloc.add(.filterByDietary(updated));
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (recipes.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.lg),
            child: ClayEmptyState(
              icon: _savedTab
                  ? Icons.bookmark_border_rounded
                  : Icons.restaurant_menu_rounded,
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
                onTap: () => context.pushNamed(
                  Routing.recipeDetails,
                  extra: RecipeDetailsArgs(recipe: recipe),
                ),
                // Long-press to share. Only for recipes this account wrote —
                // a member of someone else's recipe cannot invite others, and
                // a copy saved from the community is not this account's to
                // pass on.
                onRemove: recipe.isSavedFromCommunity
                    ? () => _confirmRemove(context, bloc, recipe)
                    : null,
                onShare: recipe.isMine
                    ? () async {
                        final sent = await showRecipeShareSheet(
                          context,
                          recipe,
                        );
                        if (sent == true && context.mounted) {
                          AppDialog.success(
                            message: t.sharing.sent,
                          ).notify(context);
                        }
                      }
                    : null,
              ),
            ),
      ],
    );
  }
}
