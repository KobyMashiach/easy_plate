import 'meal_item_entity.dart';

class MealEntity {
  final String id;
  final int weekday;
  final String name;
  final int order;
  final List<MealItemEntity> items;

  const MealEntity({
    required this.id,
    required this.weekday,
    required this.name,
    required this.order,
    required this.items,
  });

  MealEntity copyWith({String? name, List<MealItemEntity>? items}) {
    return MealEntity(
      id: id,
      weekday: weekday,
      name: name ?? this.name,
      order: order,
      items: items ?? this.items,
    );
  }
}
