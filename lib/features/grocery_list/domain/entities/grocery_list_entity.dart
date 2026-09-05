import '../../../../core/constants/app_enums.dart';
import 'grocery_item_entity.dart';

class GroceryListEntity {
  final String id;
  final String name;
  final List<GroceryItemEntity> items;
  final Map<String, AccessRole> collaborators;

  /// Which meal plans feed the aggregation. Empty means every plan — the
  /// default, and what an existing list stored before this field existed reads
  /// back as.
  final List<String> selectedPlanIds;
  final DateTime createdAt;

  const GroceryListEntity({
    required this.id,
    required this.name,
    required this.items,
    required this.createdAt,
    this.collaborators = const {},
    this.selectedPlanIds = const [],
  });

  bool get includesAllPlans => selectedPlanIds.isEmpty;

  GroceryListEntity copyWith({
    String? name,
    List<GroceryItemEntity>? items,
    List<String>? selectedPlanIds,
  }) {
    return GroceryListEntity(
      id: id,
      name: name ?? this.name,
      items: items ?? this.items,
      collaborators: collaborators,
      selectedPlanIds: selectedPlanIds ?? this.selectedPlanIds,
      createdAt: createdAt,
    );
  }
}
