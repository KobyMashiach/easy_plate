import '../entities/grocery_list_entity.dart';
import '../repositories/grocery_lists_repository.dart';

class WatchGroceryListsUseCase {
  final GroceryListsRepository repository;
  WatchGroceryListsUseCase(this.repository);

  Stream<List<GroceryListEntity>> call() => repository.watchLists();
}
