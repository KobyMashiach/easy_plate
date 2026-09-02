import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/utils/routing/routing.dart';
import '../../../../core/widgets/dietary_chip_selector.dart';
import '../../../../core/widgets/error_retry_view.dart';
import '../bloc/my_recipes_bloc.dart';
import '../widgets/recipe_card.dart';

class MyRecipesPage extends StatelessWidget {
  const MyRecipesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MyRecipesBloc.fromContext(context),
      child: Scaffold(
        appBar: AppBar(title: Text(t.books.myRecipes)),
        floatingActionButton: FloatingActionButton(
          heroTag: 'myRecipesFab',
          onPressed: () => context.pushNamed(Routing.ingestion),
          child: const Icon(Icons.add),
        ),
        body: BlocBuilder<MyRecipesBloc, MyRecipesState>(
          builder: (context, state) {
            return switch (state) {
              MyRecipesLoading() => const Center(child: CircularProgressIndicator()),
              MyRecipesLoaded(recipes: final recipes, dietaryFilters: final filters) => Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: t.common.search,
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onChanged: (value) => context.read<MyRecipesBloc>().add(.search(value)),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: DietaryChipSelector(
                          selected: filters,
                          onToggle: (pref) {
                            final updated = [...filters];
                            updated.contains(pref) ? updated.remove(pref) : updated.add(pref);
                            context.read<MyRecipesBloc>().add(.filterByDietary(updated));
                          },
                        ),
                      ),
                    ),
                    Expanded(
                      child: recipes.isEmpty
                          ? Center(child: Text(t.books.emptyBook))
                          : GridView.builder(
                              padding: const EdgeInsets.all(16),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 1.1,
                              ),
                              itemCount: recipes.length,
                              itemBuilder: (context, index) {
                                final recipe = recipes[index];
                                return RecipeCard(
                                  recipe: recipe,
                                  onTap: () => context.pushNamed(
                                    Routing.recipeDetails,
                                    extra: recipe,
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              MyRecipesError(error: final error) => ErrorRetryView(
                  error: error,
                  onRetry: () => context.read<MyRecipesBloc>().add(const MyRecipesEvent.init()),
                ),
            };
          },
        ),
      ),
    );
  }
}
