import '../entities/grocery_list_entity.dart';
import '../repositories/grocery_lists_repository.dart';

class SaveGroceryListUseCase {
  final GroceryListsRepository repository;
  SaveGroceryListUseCase(this.repository);

  Future<void> call(GroceryListEntity list) => repository.saveList(list);
}
