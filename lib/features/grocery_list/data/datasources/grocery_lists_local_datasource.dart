import '../../../../core/hive/box_stream.dart';
import '../../../../core/hive/user_scope.dart';

import '../models/grocery_list_model.dart';

abstract class GroceryListsLocalDataSource {
  Future<List<GroceryListModel>> getLists();

  /// The lists, now and after every write — see [watchBoxValues].
  Stream<List<GroceryListModel>> watchLists();
  Future<GroceryListModel?> getListById(String id);
  Future<void> saveList(GroceryListModel list);
  Future<void> deleteList(String id);
}

class GroceryListsLocalDataSourceImpl implements GroceryListsLocalDataSource {
  @override
  Future<List<GroceryListModel>> getLists() async {
    final box = await UserScope().open<GroceryListModel>(
      GroceryListModel.hiveKey,
    );
    return box.values.toList();
  }

  @override
  Stream<List<GroceryListModel>> watchLists() => watchBoxValues(
    () => UserScope().open<GroceryListModel>(GroceryListModel.hiveKey),
  );

  @override
  Future<GroceryListModel?> getListById(String id) async {
    final box = await UserScope().open<GroceryListModel>(
      GroceryListModel.hiveKey,
    );
    return box.get(id);
  }

  @override
  Future<void> saveList(GroceryListModel list) async {
    final box = await UserScope().open<GroceryListModel>(
      GroceryListModel.hiveKey,
    );
    await box.put(list.id, list);
  }

  @override
  Future<void> deleteList(String id) async {
    final box = await UserScope().open<GroceryListModel>(
      GroceryListModel.hiveKey,
    );
    await box.delete(id);
  }
}
