import 'package:flutter/foundation.dart';

/// Which of the main tabs is showing. Owned here rather than by the nav bar's
/// state so something outside it — the walkthrough, a notification tap — can
/// move the user to a tab.
abstract class MainTabs {
  static const recipes = 0;
  static const library = 1;
  static const mealPlan = 2;
  static const groceries = 3;
  static const community = 4;

  static final index = ValueNotifier<int>(recipes);
}
