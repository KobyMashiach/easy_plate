import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/dietary_chip_selector.dart';
import '../../../../core/widgets/error_retry_view.dart';
import '../../domain/entities/recipe_entity.dart';
import '../bloc/my_recipes_bloc.dart';

/// Shared picker for "choose a recipe from My Recipes", used both when
/// adding a recipe to a book and when assigning a meal item.
Future<RecipeEntity?> showRecipePickerSheet(BuildContext context, {Set<String> excludeIds = const {}}) {
  return showModalBottomSheet<RecipeEntity>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
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
                  MyRecipesLoaded(recipes: final recipes, dietaryFilters: final filters) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.mealPlanner.pickRecipe, style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          TextField(
                            decoration: InputDecoration(
                              hintText: t.common.search,
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onChanged: (value) => context.read<MyRecipesBloc>().add(.search(value)),
                          ),
                          const SizedBox(height: 8),
                          DietaryChipSelector(
                            selected: filters,
                            onToggle: (pref) {
                              final updated = [...filters];
                              updated.contains(pref) ? updated.remove(pref) : updated.add(pref);
                              context.read<MyRecipesBloc>().add(.filterByDietary(updated));
                            },
                          ),
                          Expanded(
                            child: ListView.builder(
                              controller: scrollController,
                              itemCount: recipes.length,
                              itemBuilder: (context, index) {
                                final recipe = recipes[index];
                                final excluded = excludeIds.contains(recipe.id);
                                return ListTile(
                                  title: Text(recipe.title),
                                  enabled: !excluded,
                                  trailing: excluded ? const Icon(Icons.check) : null,
                                  onTap: excluded ? null : () => Navigator.of(context).pop(recipe),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  MyRecipesError(error: final error) => ErrorRetryView(
                      error: error,
                      onRetry: () => context.read<MyRecipesBloc>().add(const MyRecipesEvent.init()),
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
