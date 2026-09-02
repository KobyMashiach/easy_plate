import 'package:hive_ce/hive.dart';

import '../../features/grocery_list/data/models/grocery_list_model.dart';
import '../../features/meal_planner/data/models/meal_plan_model.dart';
import '../../features/my_recipes/data/models/recipe_model.dart';
import '../../features/recipe_books/data/models/recipe_book_model.dart';
import '../../features/user_profile/data/models/user_preferences_model.dart';
import '../../hive_registrar.g.dart';

class AdaptersController {
  /// Adapter registration comes from the generated registrar so a new
  /// `@HiveType` can never be missed here; this only opens the root boxes
  /// (nested models are stored inside them, so they need no box of their own).
  static Future<void> registerAdapters() async {
    Hive.registerAdapters();

    await openBox<UserPreferencesModel>(UserPreferencesModel.hiveKey);
    await openBox<RecipeModel>(RecipeModel.hiveKey);
    await openBox<RecipeBookModel>(RecipeBookModel.hiveKey);
    await openBox<MealPlanModel>(MealPlanModel.hiveKey);
    await openBox<GroceryListModel>(GroceryListModel.hiveKey);
  }

  static Future<void> openBox<T>(String boxName) async {
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox<T>(boxName);
    }
  }
}
