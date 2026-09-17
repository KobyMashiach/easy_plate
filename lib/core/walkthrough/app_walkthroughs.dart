import '../navigation/main_tabs.dart';
import '../utils/i18n/strings.g.dart';
import '../utils/routing/routing.dart';
import 'walkthrough_step.dart';

/// The ids the app's controls register under, in one place so a step and
/// the widget it points at cannot drift apart by a typo.
abstract class WalkthroughIds {
  static String navTab(int index) => 'nav.$index';
  static const barAvatar = 'bar.avatar';
  static const barBell = 'bar.bell';
  static const recipesAdd = 'recipes.add';
  static const recipesSegments = 'recipes.segments';
  static const recipesFilters = 'recipes.filters';
  static const ingestionChannels = 'ingestion.channels';
  static const libraryAdd = 'library.add';
  static const mealPlanAdd = 'mealPlan.add';
  static const groceriesRegenerate = 'groceries.regenerate';
  static const groceriesAdd = 'groceries.add';
  static const communitySegments = 'community.segments';
  static const communityShare = 'community.share';
  static const ingestionInput = 'ingestion.input';
  static const bookAddRecipe = 'book.addRecipe';
  static const mealPlanName = 'mealPlan.name';
  static const mealPlanSave = 'mealPlan.save';
  static const mealPlanShare = 'mealPlan.share';
  static const mealPlanDashboard = 'mealPlan.dashboard';
  static const nutritionOverview = 'nutrition.overview';
  static const groceriesItemName = 'groceries.itemName';
  static const groceriesItemSave = 'groceries.itemSave';
  static const groceriesPriceBook = 'groceries.priceBook';
  static const priceBookScan = 'priceBook.scan';
  static const accountPremium = 'account.premium';
  static const accountSharing = 'account.sharing';
  static const accountSettings = 'account.settings';
  static const settingsTheme = 'settings.theme';

  /// The text field and the confirm button of the app's prompt dialog: one
  /// pair of ids for every prompt, since only one dialog is ever up.
  static const dialogField = 'dialog.field';
  static const dialogConfirm = 'dialog.confirm';
}

/// The guide's chapters. Built on each call so the text follows the locale.
///
/// A chapter that makes something — a book, a plan, a grocery line — walks
/// the reader through the real form: the tap that opens it, the field that
/// arrives filled in, the button that saves. Those inner steps are "stay"
/// steps: they live in the dialog the tap opened, and fall away on their own
/// when the tap was skipped.
List<WalkthroughTopic> appWalkthroughTopics() {
  final w = t.walkthrough.topics;
  return [
    WalkthroughTopic(
      id: 'addRecipe',
      title: w.addRecipe.title,
      summary: w.addRecipe.summary,
      steps: [
        WalkthroughStep(
          title: w.addRecipe.title,
          body: w.addRecipe.s1,
          targetId: WalkthroughIds.recipesAdd,
          tab: MainTabs.recipes,
        ),
        WalkthroughStep(
          title: w.addRecipe.title,
          body: w.addRecipe.s2,
          targetId: WalkthroughIds.ingestionChannels,
          route: Routing.ingestion,
          advanceOnTap: false,
        ),
        // The pasted-text box, filled with a sample while the tour runs.
        WalkthroughStep(
          title: w.addRecipe.title,
          body: w.addRecipe.s3,
          targetId: WalkthroughIds.ingestionInput,
          route: Routing.ingestion,
          advanceOnTap: false,
        ),
      ],
    ),
    WalkthroughTopic(
      id: 'myRecipes',
      title: w.myRecipes.title,
      summary: w.myRecipes.summary,
      steps: [
        WalkthroughStep(
          title: w.myRecipes.title,
          body: w.myRecipes.s1,
          targetId: WalkthroughIds.recipesSegments,
          tab: MainTabs.recipes,
        ),
        WalkthroughStep(
          title: w.myRecipes.title,
          body: w.myRecipes.s2,
          targetId: WalkthroughIds.recipesFilters,
          tab: MainTabs.recipes,
          advanceOnTap: false,
        ),
      ],
    ),
    WalkthroughTopic(
      id: 'library',
      title: w.library.title,
      summary: w.library.summary,
      steps: [
        WalkthroughStep(
          title: w.library.title,
          body: w.library.s1,
          targetId: WalkthroughIds.navTab(MainTabs.library),
        ),
        WalkthroughStep(
          title: w.library.title,
          body: w.library.s2,
          targetId: WalkthroughIds.libraryAdd,
          tab: MainTabs.library,
        ),
        // Inside the name prompt: the field comes filled in, then "save".
        WalkthroughStep(
          title: w.library.title,
          body: w.library.s3,
          targetId: WalkthroughIds.dialogField,
          stay: true,
          advanceOnTap: false,
        ),
        WalkthroughStep(
          title: w.library.title,
          body: w.library.s4,
          targetId: WalkthroughIds.dialogConfirm,
          stay: true,
        ),
        // The spine picker that follows the name; saving opens the book.
        WalkthroughStep(
          title: w.library.title,
          body: w.library.s5,
          targetId: WalkthroughIds.dialogConfirm,
          stay: true,
        ),
        WalkthroughStep(
          title: w.library.title,
          body: w.library.s6,
          targetId: WalkthroughIds.bookAddRecipe,
          stay: true,
          advanceOnTap: false,
        ),
      ],
    ),
    WalkthroughTopic(
      id: 'mealPlan',
      title: w.mealPlan.title,
      summary: w.mealPlan.summary,
      steps: [
        WalkthroughStep(
          title: w.mealPlan.title,
          body: w.mealPlan.s1,
          targetId: WalkthroughIds.navTab(MainTabs.mealPlan),
        ),
        WalkthroughStep(
          title: w.mealPlan.title,
          body: w.mealPlan.s2,
          targetId: WalkthroughIds.mealPlanAdd,
          tab: MainTabs.mealPlan,
        ),
        // Inside the new-plan sheet: the name comes filled in, then "save".
        WalkthroughStep(
          title: w.mealPlan.title,
          body: w.mealPlan.s3,
          targetId: WalkthroughIds.mealPlanName,
          stay: true,
          advanceOnTap: false,
        ),
        WalkthroughStep(
          title: w.mealPlan.title,
          body: w.mealPlan.s4,
          targetId: WalkthroughIds.mealPlanSave,
          stay: true,
        ),
        // The day's nutrition card is on the board of the selected plan;
        // its button opens the dashboard, which needs the plan as data.
        WalkthroughStep(
          title: w.mealPlan.title,
          body: w.mealPlan.s5,
          targetId: WalkthroughIds.mealPlanDashboard,
          tab: MainTabs.mealPlan,
        ),
        WalkthroughStep(
          title: w.mealPlan.title,
          body: w.mealPlan.s6,
          targetId: WalkthroughIds.nutritionOverview,
          stay: true,
          advanceOnTap: false,
        ),
        WalkthroughStep(
          title: w.mealPlan.title,
          body: w.mealPlan.s7,
          targetId: WalkthroughIds.mealPlanShare,
          tab: MainTabs.mealPlan,
          advanceOnTap: false,
        ),
      ],
    ),
    WalkthroughTopic(
      id: 'groceries',
      title: w.groceries.title,
      summary: w.groceries.summary,
      steps: [
        WalkthroughStep(
          title: w.groceries.title,
          body: w.groceries.s1,
          targetId: WalkthroughIds.navTab(MainTabs.groceries),
        ),
        WalkthroughStep(
          title: w.groceries.title,
          body: w.groceries.s2,
          targetId: WalkthroughIds.groceriesRegenerate,
          tab: MainTabs.groceries,
          advanceOnTap: false,
        ),
        WalkthroughStep(
          title: w.groceries.title,
          body: w.groceries.s3,
          targetId: WalkthroughIds.groceriesAdd,
          tab: MainTabs.groceries,
        ),
        // Inside the add-item sheet: the name comes filled in, then "add".
        WalkthroughStep(
          title: w.groceries.title,
          body: w.groceries.s4,
          targetId: WalkthroughIds.groceriesItemName,
          stay: true,
          advanceOnTap: false,
        ),
        WalkthroughStep(
          title: w.groceries.title,
          body: w.groceries.s5,
          targetId: WalkthroughIds.groceriesItemSave,
          stay: true,
        ),
        WalkthroughStep(
          title: w.groceries.title,
          body: w.groceries.s6,
          targetId: WalkthroughIds.groceriesPriceBook,
          tab: MainTabs.groceries,
        ),
        WalkthroughStep(
          title: w.groceries.title,
          body: w.groceries.s7,
          targetId: WalkthroughIds.priceBookScan,
          route: Routing.priceBook,
          advanceOnTap: false,
        ),
      ],
    ),
    WalkthroughTopic(
      id: 'community',
      title: w.community.title,
      summary: w.community.summary,
      steps: [
        WalkthroughStep(
          title: w.community.title,
          body: w.community.s1,
          targetId: WalkthroughIds.navTab(MainTabs.community),
        ),
        WalkthroughStep(
          title: w.community.title,
          body: w.community.s2,
          targetId: WalkthroughIds.communitySegments,
          tab: MainTabs.community,
          advanceOnTap: false,
        ),
        WalkthroughStep(
          title: w.community.title,
          body: w.community.s3,
          targetId: WalkthroughIds.communityShare,
          tab: MainTabs.community,
          advanceOnTap: false,
        ),
      ],
    ),
    WalkthroughTopic(
      id: 'account',
      title: w.account.title,
      summary: w.account.summary,
      steps: [
        WalkthroughStep(
          title: w.account.title,
          body: w.account.s1,
          targetId: WalkthroughIds.barBell,
          advanceOnTap: false,
        ),
        WalkthroughStep(
          title: w.account.title,
          body: w.account.s2,
          targetId: WalkthroughIds.barAvatar,
        ),
        WalkthroughStep(
          title: w.account.title,
          body: w.account.s3,
          targetId: WalkthroughIds.accountPremium,
          route: Routing.accountMenu,
          advanceOnTap: false,
        ),
        WalkthroughStep(
          title: w.account.title,
          body: w.account.s4,
          targetId: WalkthroughIds.accountSharing,
          route: Routing.accountMenu,
          advanceOnTap: false,
        ),
        WalkthroughStep(
          title: w.account.title,
          body: w.account.s5,
          targetId: WalkthroughIds.accountSettings,
          route: Routing.accountMenu,
        ),
        WalkthroughStep(
          title: w.account.title,
          body: w.account.s6,
          targetId: WalkthroughIds.settingsTheme,
          route: Routing.settings,
          advanceOnTap: false,
        ),
      ],
    ),
  ];
}

/// The tour a new account gets once: a welcome, then every chapter in order.
List<WalkthroughStep> firstRunWalkthrough() => [
      WalkthroughStep(title: t.walkthrough.welcomeTitle, body: t.walkthrough.welcomeBody),
      for (final topic in appWalkthroughTopics()) ...topic.steps,
    ];
