import '../entities/grocery_list_entity.dart';

abstract class GroceryListsRepository {
  Future<List<GroceryListEntity>> getLists();

  /// The lists, kept current as they are written from anywhere.
  Stream<List<GroceryListEntity>> watchLists();
  Future<GroceryListEntity?> getListById(String id);

  /// See [RecipesRepository.saveRecipe] for [stampLanguage].
  Future<void> saveList(GroceryListEntity list, {bool stampLanguage = true});
  Future<void> deleteList(String id);
}
