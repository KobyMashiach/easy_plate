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

/// Stored on recipes as a plain string, so adding a value is safe for
/// existing boxes. The order is the order the chips are offered in.
///
/// [aiRequest] is the one channel with no source to read from: the user
/// describes the dish they want and the model writes the recipe.
/// [file] is a recording or a PDF the model listens to or reads: a voice
/// note of a recipe, a scanned cookbook page, shared in from another app.
enum RecipeIngestionChannel {
  rawText,
  webSearch,
  urlScrape,
  socialVideo,
  aiRequest,
  manual,
  file,
}

/// Starting shape for a new meal plan. Not persisted — it only decides which
/// meals get pre-created across the week, and the plan is freely editable
/// afterwards.
enum MealPlanTemplate { free, threeMeals, sixMeals }

/// UI languages the app ships with. Persisted, so the choice survives a
/// restart; mapped to a slang `AppLocale` in the presentation layer.
@HiveType(typeId: 24)
enum AppLanguage {
  @HiveField(0)
  hebrew,
  @HiveField(1)
  english,
  @HiveField(2)
  arabic,
  @HiveField(3)
  french,
  @HiveField(4)
  russian,
}

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

/// The common allergens a recipe can be marked with, both as "contains" and
/// as "may contain" (traces). Stored on recipes as plain strings, like
/// [CollabRole], so adding one later is safe for existing boxes.
enum Allergen {
  gluten,
  milk,
  eggs,
  fish,
  shellfish,
  peanuts,
  treeNuts,
  sesame,
  soy
  ;

  /// Names back to values, in this order and without repeats. Anything that
  /// is not a known name — an old client's value, a model's slip — is dropped
  /// rather than failing the recipe.
  static List<Allergen> fromNames(Object? raw) {
    if (raw is! List) return const [];
    final names = raw.whereType<String>().toSet();
    return [
      for (final a in values)
        if (names.contains(a.name)) a,
    ];
  }
}

extension AllergenNames on List<Allergen> {
  List<String> get names => [for (final a in this) a.name];
}

/// A person's standing on a recipe shared between accounts. Stored on recipes
/// as a plain string. Owner is not an [AccessRole] because the owner alone
/// manages members; an invite only ever grants viewer or editor.
enum CollabRole { owner, editor, viewer }

/// What a shared document or an invite is about. A recipe has its own
/// collection; books and meal plans share one, told apart by this.
enum CollabKind {
  recipe,
  book,
  mealPlan,

  /// A Pro Duo / Pro Family household; only share codes carry this kind.
  /// Redeeming one adds a member directly, so no invite ever has it.
  household
  ;

  static CollabKind fromName(String? name) =>
      CollabKind.values.where((k) => k.name == name).firstOrNull ??
      CollabKind.recipe;
}

enum ShareInviteStatus { pending, accepted, declined }

/// When to remind about the shopping day. Stored by name in the
/// preferences; the default is the two that are useful without nagging.
enum ShoppingReminderSlot {
  twoDaysBefore,
  dayBefore,
  sameDayMorning,
  sameDayAfternoon
  ;

  static const defaults = [
    ShoppingReminderSlot.dayBefore,
    ShoppingReminderSlot.sameDayMorning,
  ];

  static List<ShoppingReminderSlot> fromNames(Iterable<String> names) => [
    for (final slot in ShoppingReminderSlot.values)
      if (names.contains(slot.name)) slot,
  ];
}

/// Notification kinds. Written by the app (an invite, or the administrator's
/// answer to a support message) or by a Cloud Function (a community post the
/// user saved was edited by its author).
enum AppNotificationType {
  shareInvite,
  sharedRecipeUpdated,
  adminReply,
  adminMessage,

  /// Someone replied in a forum thread the account opened or took part in.
  /// Written by the `onForumReplyCreated` function.
  forumReply,
}
