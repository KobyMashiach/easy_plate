import 'dart:math';

import '../../../core/constants/app_enums.dart';
import '../../my_recipes/domain/entities/recipe_entity.dart';
import 'entities/meal_entity.dart';
import 'entities/meal_item_entity.dart';
import 'entities/meal_plan_entity.dart';

/// Dishes to put into a plan's empty meals, worked out once on the plan on
/// screen and then applied to the plan as it is stored at the moment of the
/// write.
///
/// Applying never overwrites: a meal that someone filled in the meantime —
/// on the website, a household member, a co-editor of a shared plan — is
/// left alone. Undoing takes out exactly the items this fill put in, by id,
/// so whatever was added beside them since stays.
class PlanFill {
  /// Items for meals the plan already had, by meal id.
  final Map<String, List<MealItemEntity>> items;

  /// Whole meals added to days that had none (copying into a free plan).
  final List<MealEntity> newMeals;

  /// How many empty meals there were to fill, for the "filled 5 of 9" line.
  final int emptySlots;

  const PlanFill({
    this.items = const {},
    this.newMeals = const [],
    this.emptySlots = 0,
  });

  /// Meals that got something, counting the new ones.
  int get filled => items.length + newMeals.length;

  bool get isEmpty => filled == 0;

  MealPlanEntity apply(MealPlanEntity plan) {
    final existing = {for (final m in plan.meals) m.id};
    return plan.copyWith(
      meals: [
        for (final meal in plan.meals)
          // Only a meal still empty here: one filled meanwhile is the other
          // writer's, and two dishes stacked in one slot is not a fill.
          if (meal.items.isEmpty && items[meal.id] != null)
            meal.copyWith(items: items[meal.id])
          else
            meal,
        for (final meal in newMeals)
          // A day that grew its own meal since the fill was worked out
          // keeps it; the copy adds beside it only what is not there yet.
          if (!existing.contains(meal.id) &&
              !plan.meals.any(
                (m) => m.weekday == meal.weekday && _sameName(m, meal),
              ))
            meal,
      ],
    );
  }

  /// Takes out what [apply] put in. A meal this fill created goes too, unless
  /// something else has been put into it since.
  MealPlanEntity undo(MealPlanEntity plan) {
    final ours = {
      for (final list in items.values)
        for (final item in list) item.id,
      for (final meal in newMeals)
        for (final item in meal.items) item.id,
    };
    final newIds = {for (final m in newMeals) m.id};
    final meals = <MealEntity>[];
    for (final meal in plan.meals) {
      final kept = meal.items.where((i) => !ours.contains(i.id)).toList();
      if (newIds.contains(meal.id) && kept.isEmpty) continue;
      meals.add(
        kept.length == meal.items.length ? meal : meal.copyWith(items: kept),
      );
    }
    return plan.copyWith(meals: meals);
  }

  static bool _sameName(MealEntity a, MealEntity b) =>
      a.name.trim().toLowerCase() == b.name.trim().toLowerCase();
}

/// "Fill my week": the plan's empty meals filled from the account's own
/// recipes, without the model — so it is instant, free and works offline.
///
/// The rules, in order of weight:
///  * a recipe the account's diet rules out is never picked, as far as the
///    recipe says what it is (an untagged recipe is not guessed at);
///  * no recipe appears twice in the week, counting what is already in it;
///  * among the rest, the ones used least across the account's other plans
///    go first, so two weeks filled in a row do not come out the same;
///  * ties are broken at random, so a second try gives a different week.
class WeekAutofill {
  const WeekAutofill._();

  /// Whether [recipe] fits [diet] and [allergens] as far as it is tagged.
  static bool suits(
    RecipeEntity recipe, {
    List<DietaryPreference> diet = const [],
    List<Allergen> allergens = const [],
  }) {
    final tags = recipe.dietaryTags.toSet();
    final vegan = diet.contains(DietaryPreference.vegan);
    final vegetarian = vegan || diet.contains(DietaryPreference.vegetarian);
    // A recipe tagged vegan or vegetarian says so itself; one tagged meat
    // says the opposite. One with neither is left in.
    if (vegetarian &&
        tags.contains(DietaryPreference.meat) &&
        !tags.contains(DietaryPreference.vegetarian) &&
        !tags.contains(DietaryPreference.vegan)) {
      return false;
    }
    if (vegan &&
        tags.contains(DietaryPreference.dairy) &&
        !tags.contains(DietaryPreference.vegan)) {
      return false;
    }
    if (vegan && recipe.allergens.contains(Allergen.milk)) return false;
    if (vegan && recipe.allergens.contains(Allergen.eggs)) return false;
    if (diet.contains(DietaryPreference.glutenFree) &&
        !tags.contains(DietaryPreference.glutenFree) &&
        recipe.allergens.contains(Allergen.gluten)) {
      return false;
    }
    // Traces count for an allergy: "may contain nuts" is a no for someone
    // who avoids nuts.
    for (final allergen in allergens) {
      if (recipe.allergens.contains(allergen) ||
          recipe.mayContain.contains(allergen)) {
        return false;
      }
    }
    return true;
  }

  /// The fill for [plan]'s empty meals. [usage] counts how often each recipe
  /// sits in the account's other plans; [newId] mints item ids.
  static PlanFill plan(
    MealPlanEntity plan,
    List<RecipeEntity> recipes, {
    required String Function() newId,
    List<DietaryPreference> diet = const [],
    List<Allergen> allergens = const [],
    Map<String, int> usage = const {},
    Random? random,
  }) {
    final slots = [
      for (var day = 0; day < 7; day++)
        for (final meal in plan.mealsForWeekday(day))
          if (meal.items.isEmpty) meal,
    ];
    if (slots.isEmpty) return const PlanFill();
    final inWeek = {
      for (final meal in plan.meals)
        for (final item in meal.items)
          if (item.recipeId != null) item.recipeId!,
    };
    final candidates = [
      for (final recipe in recipes)
        // A template still waiting for its analysis is raw text, not a dish.
        if (!recipe.pendingAnalysis &&
            recipe.title.trim().isNotEmpty &&
            !inWeek.contains(recipe.id) &&
            suits(recipe, diet: diet, allergens: allergens))
          recipe,
    ]..shuffle(random ?? Random());
    // A stable sort after the shuffle: least used first, random among equals.
    final order =
        [
          for (var i = 0; i < candidates.length; i++) (i, candidates[i]),
        ]..sort((a, b) {
          final byUse = (usage[a.$2.id] ?? 0).compareTo(usage[b.$2.id] ?? 0);
          return byUse != 0 ? byUse : a.$1.compareTo(b.$1);
        });
    final items = <String, List<MealItemEntity>>{};
    for (var i = 0; i < slots.length && i < order.length; i++) {
      items[slots[i].id] = [
        MealItemEntity(id: newId(), recipeId: order[i].$2.id),
      ];
    }
    return PlanFill(items: items, emptySlots: slots.length);
  }

  /// How often each recipe appears in [plans], for [plan]'s `usage`.
  static Map<String, int> usageIn(Iterable<MealPlanEntity> plans) {
    final usage = <String, int>{};
    for (final plan in plans) {
      for (final meal in plan.meals) {
        for (final item in meal.items) {
          final id = item.recipeId;
          if (id != null) usage[id] = (usage[id] ?? 0) + 1;
        }
      }
    }
    return usage;
  }
}

/// "Copy last week": another plan's dishes into this plan's empty meals.
///
/// A plan here is a week template (days, not dates), so "last week" is the
/// plan made before this one. Meals are matched by day and name, then by
/// their place in the day; a day with no meals at all takes the source day's
/// meals whole. Days already planned keep what they have.
class WeekCopy {
  const WeekCopy._();

  /// The plan to copy from by default: the newest one made before [target],
  /// else the newest other one. Null when there is no other plan with
  /// anything in it.
  static MealPlanEntity? previous(
    MealPlanEntity target,
    List<MealPlanEntity> plans,
  ) {
    final others = [
      for (final p in plans)
        if (p.id != target.id && p.meals.any((m) => m.items.isNotEmpty)) p,
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return others
            .where((p) => p.createdAt.isBefore(target.createdAt))
            .firstOrNull ??
        others.firstOrNull;
  }

  static PlanFill plan(
    MealPlanEntity target,
    MealPlanEntity source, {
    required String Function() newId,
  }) {
    List<MealItemEntity> copies(MealEntity meal) => [
      for (final item in meal.items)
        MealItemEntity(
          id: newId(),
          recipeId: item.recipeId,
          freeText: item.freeText,
          ingredients: item.ingredients,
        ),
    ];

    final items = <String, List<MealItemEntity>>{};
    final newMeals = <MealEntity>[];
    var emptySlots = 0;
    for (var day = 0; day < 7; day++) {
      final from = source.mealsForWeekday(day);
      final into = target.mealsForWeekday(day);
      if (from.every((m) => m.items.isEmpty)) {
        emptySlots += into.where((m) => m.items.isEmpty).length;
        continue;
      }
      if (into.isEmpty) {
        for (final meal in from) {
          if (meal.items.isEmpty) continue;
          newMeals.add(
            MealEntity(
              id: newId(),
              weekday: day,
              name: meal.name,
              order: meal.order,
              items: copies(meal),
            ),
          );
        }
        continue;
      }
      final used = <String>{};
      String norm(String s) => s.trim().toLowerCase();
      for (var i = 0; i < into.length; i++) {
        final meal = into[i];
        if (meal.items.isNotEmpty) {
          // A filled meal still claims its namesake, so the source's
          // breakfast does not slide into the next empty slot.
          final twin = from
              .where(
                (m) => !used.contains(m.id) && norm(m.name) == norm(meal.name),
              )
              .firstOrNull;
          if (twin != null) used.add(twin.id);
          continue;
        }
        emptySlots++;
        final match =
            from
                .where(
                  (m) =>
                      !used.contains(m.id) && norm(m.name) == norm(meal.name),
                )
                .firstOrNull ??
            (i < from.length &&
                    !used.contains(from[i].id) &&
                    !into.any((t) => norm(t.name) == norm(from[i].name))
                ? from[i]
                : null);
        if (match == null) continue;
        used.add(match.id);
        if (match.items.isEmpty) continue;
        items[meal.id] = copies(match);
      }
    }
    return PlanFill(items: items, newMeals: newMeals, emptySlots: emptySlots);
  }
}

/// Undo for a removal on the board: the meal or the dish put back as it
/// was, onto the plan as stored. Something already back is not doubled.
class PlanRestore {
  const PlanRestore._();

  static MealPlanEntity meal(MealPlanEntity plan, MealEntity meal) {
    if (plan.meals.any((m) => m.id == meal.id)) return plan;
    return plan.copyWith(meals: [...plan.meals, meal]);
  }

  /// [item] back into [mealId] at [index]. Gone with its meal (removed
  /// elsewhere meanwhile), it has nowhere to go and is dropped.
  static MealPlanEntity item(
    MealPlanEntity plan,
    String mealId,
    MealItemEntity item,
    int index,
  ) {
    return plan.copyWith(
      meals: [
        for (final meal in plan.meals)
          if (meal.id == mealId && !meal.items.any((i) => i.id == item.id))
            meal.copyWith(
              items: [...meal.items]
                ..insert(index.clamp(0, meal.items.length), item),
            )
          else
            meal,
      ],
    );
  }

  /// The dishes of [meals] back, for an undone "clear the day": a meal that
  /// is still empty takes its old dishes again; one that got new dishes in
  /// the meantime keeps them; a meal removed since comes back whole.
  static MealPlanEntity meals(MealPlanEntity plan, List<MealEntity> meals) {
    final byId = {for (final m in meals) m.id: m};
    final present = {for (final m in plan.meals) m.id};
    return plan.copyWith(
      meals: [
        for (final m in plan.meals)
          byId[m.id] != null && m.items.isEmpty
              ? m.copyWith(items: byId[m.id]!.items)
              : m,
        for (final m in meals)
          if (!present.contains(m.id)) m,
      ],
    );
  }

  /// Every dish of [weekday] taken off, its meals kept.
  static MealPlanEntity clearDay(MealPlanEntity plan, int weekday) =>
      plan.copyWith(
        meals: [
          for (final m in plan.meals)
            m.weekday == weekday && m.items.isNotEmpty
                ? m.copyWith(items: const [])
                : m,
        ],
      );
}
