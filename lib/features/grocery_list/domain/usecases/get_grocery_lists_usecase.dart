import '../entities/grocery_list_entity.dart';
import '../repositories/grocery_lists_repository.dart';

class GetGroceryListsUseCase {
  final GroceryListsRepository repository;
  GetGroceryListsUseCase(this.repository);

  Future<List<GroceryListEntity>> call() => repository.getLists();
}
