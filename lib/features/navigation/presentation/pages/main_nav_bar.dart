import 'package:flutter/material.dart';

import '../../../../core/utils/i18n/strings.g.dart';
import '../../../grocery_list/presentation/pages/grocery_list_page.dart';
import '../../../meal_planner/presentation/pages/meal_planner_page.dart';
import '../../../my_recipes/presentation/pages/my_recipes_page.dart';
import '../../../recipe_books/presentation/pages/library_page.dart';
import '../../../settings/presentation/pages/settings_page.dart';

class MainNavBar extends StatefulWidget {
  const MainNavBar({super.key});

  @override
  State<MainNavBar> createState() => _MainNavBarState();
}

class _MainNavBarState extends State<MainNavBar> {
  int _index = 0;

  static const _pages = [
    LibraryPage(),
    MyRecipesPage(),
    MealPlannerPage(),
    GroceryListPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.menu_book), label: t.books.myLibrary),
          NavigationDestination(icon: const Icon(Icons.receipt_long), label: t.books.myRecipes),
          NavigationDestination(icon: const Icon(Icons.calendar_month), label: t.mealPlanner.title),
          NavigationDestination(icon: const Icon(Icons.shopping_cart), label: t.groceryList.title),
          NavigationDestination(icon: const Icon(Icons.settings), label: t.settings.title),
        ],
      ),
    );
  }
}
