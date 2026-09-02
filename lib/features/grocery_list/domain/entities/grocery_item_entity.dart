import '../../../../core/constants/app_enums.dart';
import 'grocery_item_source_entity.dart';

class GroceryItemEntity {
  final String id;
  final String name;
  final MeasurementUnit unit;
  final List<GroceryItemSourceEntity> sources;
  final bool isChecked;
  final String category;
  final bool isAdHoc;

  const GroceryItemEntity({
    required this.id,
    required this.name,
    required this.unit,
    required this.sources,
    required this.category,
    this.isChecked = false,
    this.isAdHoc = false,
  });

  double get totalAmount => sources.fold(0, (sum, s) => sum + s.amount);

  GroceryItemEntity copyWith({
    List<GroceryItemSourceEntity>? sources,
    bool? isChecked,
    String? category,
    MeasurementUnit? unit,
  }) {
    return GroceryItemEntity(
      id: id,
      name: name,
      unit: unit ?? this.unit,
      sources: sources ?? this.sources,
      isChecked: isChecked ?? this.isChecked,
      category: category ?? this.category,
      isAdHoc: isAdHoc,
    );
  }
}
