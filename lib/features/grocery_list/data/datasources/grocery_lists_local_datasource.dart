import 'package:hive_ce/hive.dart';

import '../models/grocery_list_model.dart';

abstract class GroceryListsLocalDataSource {
  Future<List<GroceryListModel>> getLists();
  Future<GroceryListModel?> getListById(String id);
  Future<void> saveList(GroceryListModel list);
  Future<void> deleteList(String id);
}

class GroceryListsLocalDataSourceImpl implements GroceryListsLocalDataSource {
  @override
  Future<List<GroceryListModel>> getLists() async {
    final box = await Hive.openBox<GroceryListModel>(GroceryListModel.hiveKey);
    return box.values.toList();
  }

  @override
  Future<GroceryListModel?> getListById(String id) async {
    final box = await Hive.openBox<GroceryListModel>(GroceryListModel.hiveKey);
    return box.get(id);
  }

  @override
  Future<void> saveList(GroceryListModel list) async {
    final box = await Hive.openBox<GroceryListModel>(GroceryListModel.hiveKey);
    await box.put(list.id, list);
  }

  @override
  Future<void> deleteList(String id) async {
    final box = await Hive.openBox<GroceryListModel>(GroceryListModel.hiveKey);
    await box.delete(id);
  }
}
