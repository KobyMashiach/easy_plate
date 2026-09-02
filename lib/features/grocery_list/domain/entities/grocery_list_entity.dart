import '../../../../core/constants/app_enums.dart';
import 'grocery_item_entity.dart';

class GroceryListEntity {
  final String id;
  final String name;
  final List<GroceryItemEntity> items;
  final Map<String, AccessRole> collaborators;
  final DateTime createdAt;

  const GroceryListEntity({
    required this.id,
    required this.name,
    required this.items,
    required this.createdAt,
    this.collaborators = const {},
  });

  GroceryListEntity copyWith({String? name, List<GroceryItemEntity>? items}) {
    return GroceryListEntity(
      id: id,
      name: name ?? this.name,
      items: items ?? this.items,
      collaborators: collaborators,
      createdAt: createdAt,
    );
  }
}
