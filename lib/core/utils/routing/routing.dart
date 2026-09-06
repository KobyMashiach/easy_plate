class Routing {
  static const splash = '/';
  static const login = '/login';
  static const phoneVerify = '/phone_verify';
  static const verifyEmail = '/verify_email';
  static const register = '/register';
  static const onboarding = '/onboarding';
  static const home = '/home';

  // relative child routes (nested under /home)
  static const bookDetails = 'book_details';
  static const recipeDetails = 'recipe_details';
  static const recipeEditor = 'recipe_editor';
  static const ingestion = 'ingestion';
  static const ingestionReview = 'ingestion_review';
  static const mealPlanDetails = 'meal_plan_details';
  static const groceryListDetails = 'grocery_list_details';
  static const settings = 'settings';
  static const accountMenu = 'account_menu';
  static const support = 'support';
  static const sharing = 'sharing';
  static const notifications = 'notifications';
  static const profileEdit = 'profile_edit';
  static const forumThread = 'forum_thread';
}
