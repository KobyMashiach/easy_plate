class Routing {
  static const splash = '/';
  static const login = '/login';
  static const phoneVerify = '/phone_verify';
  static const phoneGate = '/phone_gate';
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
  static const nutritionDashboard = 'nutrition_dashboard';
  static const receiptReview = 'receipt_review';
  static const priceBook = 'price_book';
  static const receiptDetails = 'receipt_details';
  static const receiptImages = 'receipt_images';
  static const groceryListDetails = 'grocery_list_details';
  static const settings = 'settings';
  static const accountMenu = 'account_menu';
  static const support = 'support';
  static const premium = 'premium';
  static const sharing = 'sharing';
  static const notifications = 'notifications';
  static const profileEdit = 'profile_edit';
  static const forumThread = 'forum_thread';
  static const tutorial = 'tutorial';
  static const adminFeedback = 'admin_feedback';
}
