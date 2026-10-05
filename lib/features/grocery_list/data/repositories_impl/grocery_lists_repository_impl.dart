import 'dart:async';

import '../../../../core/sync/user_cloud_collection.dart';
import '../../../../core/translation/content_translation.dart';
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
  Stream<List<GroceryListEntity>> watchLists() => localDataSource
      .watchLists()
      .map((models) => models.map((m) => m.toEntity()).toList());

  @override
  Future<GroceryListEntity?> getListById(String id) async {
    final model = await localDataSource.getListById(id);
    return model?.toEntity();
  }

  @override
  Future<void> saveList(
    GroceryListEntity list, {
    bool stampLanguage = true,
  }) async {
    if (stampLanguage) {
      list = await _stamped(list);
    }
    final model = list.toModel();
    await localDataSource.saveList(model);
    unawaited(cloud?.push(model) ?? Future.value());
  }

  @override
  Future<void> deleteList(String id) async {
    await localDataSource.deleteList(id);
    unawaited(cloud?.remove(id) ?? Future.value());
  }

  /// See the same method on the recipes repository.
  Future<GroceryListEntity> _stamped(GroceryListEntity list) async {
    // One key lookup, not the whole box mapped to find one record.
    final previous = (await localDataSource.getListById(list.id))?.toEntity();
    final edited = previous == null || _words(previous) != _words(list);
    if (!edited && list.contentLang != null) return list;
    return list.copyWith(
      contentLang: currentContentLanguage().code,
      contentVersion: edited && previous != null
          ? previous.contentVersion + 1
          : list.contentVersion,
    );
  }

  static String _words(GroceryListEntity l) =>
      [l.name, for (final item in l.items) item.name].join('\n');
}
