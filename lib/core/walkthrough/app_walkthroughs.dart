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
}

/// The guide's chapters. Built on each call so the text follows the locale.
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
