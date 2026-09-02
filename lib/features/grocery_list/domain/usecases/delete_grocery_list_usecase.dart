import '../repositories/grocery_lists_repository.dart';

class DeleteGroceryListUseCase {
  final GroceryListsRepository repository;
  DeleteGroceryListUseCase(this.repository);

  Future<void> call(String id) => repository.deleteList(id);
}
