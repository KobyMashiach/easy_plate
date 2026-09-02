import '../entities/grocery_list_entity.dart';

abstract class GroceryListsRepository {
  Future<List<GroceryListEntity>> getLists();
  Future<GroceryListEntity?> getListById(String id);
  Future<void> saveList(GroceryListEntity list);
  Future<void> deleteList(String id);
}
