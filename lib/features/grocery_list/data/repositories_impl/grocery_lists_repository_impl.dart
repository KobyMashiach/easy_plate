import '../../domain/entities/grocery_list_entity.dart';
import '../../domain/repositories/grocery_lists_repository.dart';
import '../datasources/grocery_lists_local_datasource.dart';
import '../models/grocery_list_model.dart';

class GroceryListsRepositoryImpl implements GroceryListsRepository {
  final GroceryListsLocalDataSource localDataSource;

  GroceryListsRepositoryImpl({required this.localDataSource});

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
  Future<void> saveList(GroceryListEntity list) {
    return localDataSource.saveList(list.toModel());
  }

  @override
  Future<void> deleteList(String id) {
    return localDataSource.deleteList(id);
  }
}
