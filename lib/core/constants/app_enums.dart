import 'package:hive_ce/hive.dart';

part 'app_enums.g.dart';

@HiveType(typeId: 20)
enum ShoppingDay {
  @HiveField(0)
  sunday,
  @HiveField(1)
  monday,
  @HiveField(2)
  tuesday,
  @HiveField(3)
  wednesday,
  @HiveField(4)
  thursday,
  @HiveField(5)
  friday,
  @HiveField(6)
  saturday,
}

@HiveType(typeId: 21)
enum DietaryPreference {
  @HiveField(0)
  meat,
  @HiveField(1)
  dairy,
  @HiveField(2)
  vegetarian,
  @HiveField(3)
  vegan,
  @HiveField(4)
  kosher,
  @HiveField(5)
  glutenFree,
  @HiveField(6)
  allergy,
}

@HiveType(typeId: 22)
enum AccessRole {
  @HiveField(0)
  viewer,
  @HiveField(1)
  editor,
}

enum RecipeIngestionChannel { rawText, webSearch, urlScrape, socialVideo }

@HiveType(typeId: 23)
enum MeasurementUnit {
  @HiveField(0)
  gram,
  @HiveField(1)
  kilogram,
  @HiveField(2)
  milliliter,
  @HiveField(3)
  liter,
  @HiveField(4)
  teaspoon,
  @HiveField(5)
  tablespoon,
  @HiveField(6)
  cup,
  @HiveField(7)
  unit,
  @HiveField(8)
  pinch,
  @HiveField(9)
  unspecified,
}
