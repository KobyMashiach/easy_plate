import 'package:uuid/uuid.dart';

import '../../../my_recipes/domain/entities/recipe_entity.dart';
import '../../data/datasources/active_grocery_list_store.dart';
import '../entities/grocery_list_entity.dart';
import '../repositories/grocery_lists_repository.dart';
import 'build_aggregate_grocery_list_usecase.dart';

/// A new list holding one recipe's ingredients, made the open list.
///
/// Shared by the recipe's own page and the groceries tab, so the two make
/// exactly the same list. Built from the [RecipeEntity] in hand rather than
/// re-read by id: a community recipe opened read-only is not in the local
/// box, and should still be shoppable.
class CreateRecipeGroceryListUseCase {
  final GroceryListsRepository repository;
  final ActiveGroceryListStore activeList;
  static const _uuid = Uuid();

  CreateRecipeGroceryListUseCase(this.repository, this.activeList);

  Future<GroceryListEntity> call(
    RecipeEntity recipe, {
    required String name,
    double scale = 1,
  }) async {
    final list = GroceryListEntity(
      id: _uuid.v4(),
      name: name.trim().isEmpty ? recipe.title : name.trim(),
      items: groceryItemsForRecipe(recipe, scale: scale),
      createdAt: DateTime.now(),
      source: GroceryListSource.recipe,
      recipeId: recipe.id,
      recipeScale: scale,
      recipeServings: recipe.servings,
      recipeTitle: recipe.title,
    );
    await repository.saveList(list);
    await activeList.write(list.id);
    return list;
  }
}
