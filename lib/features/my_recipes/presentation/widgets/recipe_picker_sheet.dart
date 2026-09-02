import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../../../core/widgets/dietary_chip_selector.dart';
import '../../../../core/widgets/error_retry_view.dart';
import '../../domain/entities/recipe_entity.dart';
import '../bloc/my_recipes_bloc.dart';

/// Shared picker for "choose a recipe from My Recipes".
///
/// Two modes:
/// * single pick (default) — tapping a recipe closes the sheet and returns it,
///   which is what assigning a meal item needs.
/// * multi-select — pass [onToggle] and the sheet stays open so several
///   recipes can be added in one go, each tap toggling membership. Selection is
///   tracked here rather than read back from the caller's bloc, which isn't
///   visible from a modal route's context.
Future<RecipeEntity?> showRecipePickerSheet(
  BuildContext context, {
  Set<String> selectedIds = const {},
  void Function(RecipeEntity recipe, bool selected)? onToggle,
}) {
  return showModalBottomSheet<RecipeEntity>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return BlocProvider(
        create: (context) => MyRecipesBloc.fromContext(context),
        child: DraggableScrollableSheet(
          initialChildSize: 0.75,
          expand: false,
          builder: (context, scrollController) {
            return BlocBuilder<MyRecipesBloc, MyRecipesState>(
              builder: (context, state) {
                return switch (state) {
                  MyRecipesLoading() => const Center(child: CircularProgressIndicator()),
                  MyRecipesLoaded(
                    recipes: final recipes,
                    dietaryFilters: final filters,
                  ) =>
                    _PickerBody(
                      recipes: recipes,
                      filters: filters,
                      initialSelectedIds: selectedIds,
                      onToggle: onToggle,
                      scrollController: scrollController,
                    ),
                  MyRecipesError(error: final error) => ErrorRetryView(
                      error: error,
                      onRetry: () =>
                          context.read<MyRecipesBloc>().add(const MyRecipesEvent.init()),
                    ),
                };
              },
            );
          },
        ),
      );
    },
  );
}

class _PickerBody extends StatefulWidget {
  final List<RecipeEntity> recipes;
  final List<DietaryPreference> filters;
  final Set<String> initialSelectedIds;
  final void Function(RecipeEntity recipe, bool selected)? onToggle;
  final ScrollController scrollController;

  const _PickerBody({
    required this.recipes,
    required this.filters,
    required this.initialSelectedIds,
    required this.onToggle,
    required this.scrollController,
  });

  @override
  State<_PickerBody> createState() => _PickerBodyState();
}

class _PickerBodyState extends State<_PickerBody> {
  late final Set<String> _selected = {...widget.initialSelectedIds};

  bool get _isMultiSelect => widget.onToggle != null;

  void _onRecipeTapped(RecipeEntity recipe) {
    if (!_isMultiSelect) {
      Navigator.of(context).pop(recipe);
      return;
    }
    final nowSelected = !_selected.contains(recipe.id);
    setState(() {
      nowSelected ? _selected.add(recipe.id) : _selected.remove(recipe.id);
    });
    widget.onToggle!(recipe, nowSelected);
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<MyRecipesBloc>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.marginMobile),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(t.mealPlanner.pickRecipe, style: AppTextStyles.headlineMd),
              ),
              if (_isMultiSelect)
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(t.common.done),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.gutter),
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
          const SizedBox(height: AppSpacing.sm),
          DietaryChipSelector(
            selected: widget.filters,
            onToggle: (pref) {
              final updated = [...widget.filters];
              updated.contains(pref) ? updated.remove(pref) : updated.add(pref);
              bloc.add(.filterByDietary(updated));
            },
          ),
          const SizedBox(height: AppSpacing.gutter),
          Expanded(
            child: ListView.separated(
              controller: widget.scrollController,
              itemCount: widget.recipes.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.base),
              itemBuilder: (context, index) {
                final recipe = widget.recipes[index];
                final isSelected = _selected.contains(recipe.id);

                return ClayCard(
                  radius: AppRadius.std,
                  padding: const EdgeInsets.all(AppSpacing.gutter),
                  onTap: () => _onRecipeTapped(recipe),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          recipe.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyMd,
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? AppColors.secondaryContainer
                              : AppColors.surfaceContainerLow,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.secondaryContainer
                                : AppColors.outlineVariant,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          isSelected ? Icons.check_rounded : Icons.add_rounded,
                          size: 18,
                          color: isSelected
                              ? AppColors.onSecondaryContainer
                              : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
