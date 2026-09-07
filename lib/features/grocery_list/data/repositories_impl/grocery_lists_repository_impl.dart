import 'dart:async';

import '../../../../core/sync/user_cloud_collection.dart';
import '../../domain/entities/grocery_list_entity.dart';
import '../../domain/repositories/grocery_lists_repository.dart';
import '../datasources/grocery_lists_local_datasource.dart';
import '../models/grocery_list_model.dart';

class GroceryListsRepositoryImpl implements GroceryListsRepository {
  final GroceryListsLocalDataSource localDataSource;

  /// Mirrors every write into the account's own Firestore subtree, so a list
  /// ticked off on one device is the same list on the next.
  final UserCloudCollection<GroceryListModel>? cloud;

  GroceryListsRepositoryImpl({required this.localDataSource, this.cloud});

  @override
  Future<List<GroceryListEntity>> getLists() async {
    final models = await localDataSource.getLists();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<GroceryListEntity?> getListById(String id) async {
    final model = await localDataSource.getListById(id);
    return model?.toEntity();
  }

  @override
  Future<void> saveList(GroceryListEntity list) async {
    final model = list.toModel();
    await localDataSource.saveList(model);
    unawaited(cloud?.push(model) ?? Future.value());
  }

  @override
  Future<void> deleteList(String id) async {
    await localDataSource.deleteList(id);
    unawaited(cloud?.remove(id) ?? Future.value());
  }
}
